import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../../../app/l10n.dart';
import '../../../protocol/protocol.dart';
import '../../../shared/avatars.dart';
import '../../admin/admin_widgets.dart';

/// Copies the table link and shows it with a QR code and everyone who is
/// connected right now.
Future<void> showInviteDialog(
  BuildContext context, {
  required String tableId,
  required Snapshot? snapshot,
}) {
  final link = joinLinkFor(tableId);
  Clipboard.setData(ClipboardData(text: link));
  return showOverlay<void>(
    context,
    const DialogConfiguration(),
    builder: (context) => _InviteDialog(link: link, snapshot: snapshot),
  ).future;
}

class _InviteDialog extends StatelessWidget {
  const _InviteDialog({required this.link, required this.snapshot});
  final String link;
  final Snapshot? snapshot;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final players = [
      for (final sv in snapshot?.seats ?? const <SeatView>[])
        if (sv.player != null) sv.player!,
    ];
    final spectators = snapshot?.spectatorNames ?? const <String>[];
    Widget section(String title) => Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Text(title).semiBold().small(),
    );
    return AlertDialog(
      title: Text(l10n.inviteTitle),
      content: SizedBox(
        width: 380,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.inviteHint).muted().small(),
              const Gap(10),
              Row(
                children: [
                  Expanded(
                    child: SelectableText(
                      link,
                      key: const Key('invite-link'),
                      style: const TextStyle(
                        fontFamily: 'GeistMono',
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const Gap(8),
                  OutlineButton(
                    key: const Key('invite-copy'),
                    size: ButtonSize.small,
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: link));
                      showAdminToast(context, l10n.adminLinkCopied);
                    },
                    leading: const Icon(LucideIcons.copy),
                    child: Text(l10n.adminCopyLink),
                  ),
                ],
              ),
              const Gap(12),
              Center(
                child: Container(
                  color: const Color(0xFFFFFFFF),
                  padding: const EdgeInsets.all(8),
                  child: QrImageView(data: link, size: 180),
                ),
              ),
              section(l10n.invitePlayers(players.length)),
              if (players.isEmpty) Text(l10n.inviteNobody).muted().small(),
              for (final p in players)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      PlayerAvatar(index: p.avatar, size: 24),
                      const Gap(8),
                      Expanded(child: Text(p.name)),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: p.connected
                              ? const Color(0xFF43A047)
                              : theme.colorScheme.destructive,
                        ),
                      ),
                      const Gap(6),
                      Text(
                        p.connected
                            ? l10n.connConnected
                            : l10n.badgeDisconnected,
                      ).muted().small(),
                    ],
                  ),
                ),
              section(l10n.inviteSpectators(spectators.length)),
              if (spectators.isEmpty) Text(l10n.inviteNobody).muted().small(),
              for (final name in spectators)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.eye,
                        size: 16,
                        color: theme.colorScheme.mutedForeground,
                      ),
                      const Gap(8),
                      Expanded(child: Text(name)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        PrimaryButton(
          onPressed: () => closeOverlay<void>(context),
          child: Text(l10n.close),
        ),
      ],
    );
  }
}
