import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../../app/l10n.dart';
import '../../shared/confirm_dialog.dart';
import 'admin_session.dart';
import 'admin_widgets.dart';

/// The host's actions on one player, shared by the Admin tab and the seat
/// tap at the table. Every call returns true when the server applied it.
class AdminPlayerActions {
  const AdminPlayerActions({
    required this.ref,
    required this.context,
    required this.tableId,
    required this.token,
  });

  final WidgetRef ref;
  final BuildContext context;
  final String tableId;
  final String token;

  Future<bool> kick(String playerId, String name) async {
    final l10n = context.l10n;
    final ok = await showConfirmDialog(
      context,
      title: l10n.adminKickTitle(name),
      body: l10n.adminKickBody,
      confirmLabel: l10n.adminKick,
      cancelLabel: l10n.cancel,
      destructive: true,
    );
    if (!ok || !context.mounted) return false;
    final r = await guardAdmin(ref, context, tableId, () async {
      await ref.read(adminApiProvider).kick(token, tableId, playerId);
      return true;
    });
    return r ?? false;
  }

  Future<bool> chips(String playerId, String name) async {
    final l10n = context.l10n;
    final amount = TextEditingController();
    final note = TextEditingController();
    String? error;
    final result = await showOverlay<(int, String)?>(
      context,
      const DialogConfiguration(),
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(l10n.adminChipsTitle(name)),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.adminChipsAmount).small(),
                const Gap(4),
                TextField(
                  key: const Key('chips-amount'),
                  controller: amount,
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(
                    signed: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9-]')),
                  ],
                ),
                const Gap(8),
                Text(l10n.adminChipsNote).small(),
                const Gap(4),
                TextField(key: const Key('chips-note'), controller: note),
                if (error != null) ...[
                  const Gap(6),
                  Text(
                    error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.destructive,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            OutlineButton(
              onPressed: () => closeOverlay<(int, String)?>(context),
              child: Text(l10n.cancel),
            ),
            PrimaryButton(
              key: const Key('chips-confirm'),
              onPressed: () {
                final v = int.tryParse(amount.text.trim());
                if (v == null || v == 0) {
                  setDialogState(() => error = l10n.adminChipsInvalid);
                  return;
                }
                closeOverlay<(int, String)?>(context, (v, note.text.trim()));
              },
              child: Text(l10n.confirm),
            ),
          ],
        ),
      ),
    ).future;
    amount.dispose();
    note.dispose();
    if (result == null || !context.mounted) return false;
    final applied = await guardAdmin(
      ref,
      context,
      tableId,
      () => ref
          .read(adminApiProvider)
          .adjustChips(
            token,
            tableId,
            playerId,
            delta: result.$1,
            note: result.$2,
          ),
    );
    if (applied != null && context.mounted) {
      showAdminToast(
        context,
        applied ? l10n.adminChipsApplied : l10n.adminChipsQueued,
      );
    }
    return applied != null;
  }

  Future<bool> muteChat(String playerId, {required bool muted}) async {
    final r = await guardAdmin(ref, context, tableId, () async {
      await ref
          .read(adminApiProvider)
          .mute(token, tableId, playerId, muted: muted);
      return true;
    });
    return r ?? false;
  }

  Future<bool> muteVoice(String playerId) async {
    final r = await guardAdmin(ref, context, tableId, () async {
      await ref.read(adminApiProvider).muteVoice(token, tableId, playerId);
      return true;
    });
    if ((r ?? false) && context.mounted) {
      showAdminToast(context, context.l10n.adminMutedVoice);
    }
    return r ?? false;
  }

  /// The action sheet opened by tapping a player's avatar.
  Future<void> showMenu({
    required String playerId,
    required String name,
    required bool chatMuted,
    required String voice,
  }) {
    final l10n = context.l10n;
    return showOverlay<void>(
      context,
      const DialogConfiguration(),
      builder: (dialog) => AlertDialog(
        title: Text(l10n.adminPlayerActions(name)),
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              OutlineButton(
                key: const Key('player-action-chips'),
                onPressed: () {
                  closeOverlay<void>(dialog);
                  chips(playerId, name);
                },
                leading: const Icon(LucideIcons.coins),
                alignment: Alignment.centerLeft,
                child: Text(l10n.adminChips),
              ),
              const Gap(6),
              OutlineButton(
                key: const Key('player-action-chat'),
                onPressed: () {
                  closeOverlay<void>(dialog);
                  muteChat(playerId, muted: !chatMuted);
                },
                leading: Icon(
                  chatMuted
                      ? LucideIcons.messageSquare
                      : LucideIcons.messageSquareOff,
                ),
                alignment: Alignment.centerLeft,
                child: Text(
                  chatMuted ? l10n.adminUnmuteChat : l10n.adminMuteChat,
                ),
              ),
              if (voice == 'on') ...[
                const Gap(6),
                OutlineButton(
                  key: const Key('player-action-voice'),
                  onPressed: () {
                    closeOverlay<void>(dialog);
                    muteVoice(playerId);
                  },
                  leading: const Icon(LucideIcons.micOff),
                  alignment: Alignment.centerLeft,
                  child: Text(l10n.adminMuteVoice),
                ),
              ],
              const Gap(6),
              DestructiveButton(
                key: const Key('player-action-kick'),
                onPressed: () {
                  closeOverlay<void>(dialog);
                  kick(playerId, name);
                },
                leading: const Icon(LucideIcons.userX),
                alignment: Alignment.centerLeft,
                child: Text(l10n.adminKick),
              ),
            ],
          ),
        ),
        actions: [
          OutlineButton(
            onPressed: () => closeOverlay<void>(dialog),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    ).future;
  }
}
