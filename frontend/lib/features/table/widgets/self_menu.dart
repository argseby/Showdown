import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../../../app/l10n.dart';
import '../../../core/voice/voice_controller.dart';
import '../../../protocol/protocol.dart';
import '../../../shared/avatars.dart';
import '../../../shared/handle_badge.dart';
import '../../../shared/hats.dart';
import '../../../shared/look_dialog.dart';
import '../table_session.dart';

/// Opens the avatar-and-hat dialog for the viewer and sends what changed.
Future<void> changeLook(
  BuildContext context,
  WidgetRef ref,
  String tableId,
  PlayerView me,
) async {
  final picked = await showLookDialog(context, avatar: me.avatar, hat: me.hat);
  if (picked == null) return;
  final session = ref.read(tableSessionProvider(tableId).notifier);
  if (picked.avatar != me.avatar) await session.setAvatar(picked.avatar);
  if ((picked.hat ?? hatNone) != (me.hat ?? hatNone)) {
    await session.setHat(picked.hat ?? hatNone);
  }
}

/// The menu on the viewer's own seat: avatar and hat, microphone, camera.
Future<void> showSelfMenu(BuildContext context, WidgetRef ref, String tableId) {
  return showOverlay<void>(
    context,
    const DialogConfiguration(),
    builder: (dialog) => _SelfMenu(dialog: dialog, tableId: tableId),
  ).future;
}

class _SelfMenu extends ConsumerWidget {
  const _SelfMenu({required this.dialog, required this.tableId});

  final BuildContext dialog;
  final String tableId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final me = ref.watch(
      tableSessionProvider(tableId).select((s) {
        final snap = s.snapshot;
        final seat = snap?.you.seat;
        if (snap == null || seat == null) return null;
        for (final sv in snap.seats) {
          if (sv.seat == seat) return sv.player;
        }
        return null;
      }),
    );
    final voice = ref.watch(voiceControllerProvider(tableId));
    final voiceCtrl = ref.read(voiceControllerProvider(tableId).notifier);
    Widget row(IconData icon, String label, Widget trailing) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.mutedForeground),
          const Gap(10),
          Expanded(child: Text(label)),
          trailing,
        ],
      ),
    );
    return AlertDialog(
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (me != null)
            Padding(
              padding: const EdgeInsets.only(top: 36 * hatOverflow),
              child: PlayerAvatar(index: me.avatar, size: 36, hat: me.hat),
            ),
          const Gap(12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(me?.name ?? l10n.selfMenuTitle),
              HandleBadge(me?.account),
            ],
          ),
        ],
      ),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (me != null)
              row(
                LucideIcons.crown,
                l10n.lookTitle,
                OutlineButton(
                  key: const Key('self-look'),
                  size: ButtonSize.small,
                  onPressed: () => changeLook(context, ref, tableId, me),
                  child: Text(l10n.joinAvatarChange),
                ),
              ),
            row(
              LucideIcons.headphones,
              l10n.voiceTitle,
              Switch(
                key: const Key('self-voice'),
                value: voice.enabled,
                onChanged: (_) =>
                    voice.enabled ? voiceCtrl.disable() : voiceCtrl.enable(),
              ),
            ),
            if (voice.enabled)
              row(
                LucideIcons.mic,
                l10n.voiceMicOn,
                Switch(
                  key: const Key('self-mic'),
                  value: !voice.muted,
                  onChanged: (_) => voiceCtrl.toggleMute(),
                ),
              ),
            row(
              LucideIcons.video,
              l10n.cameraTitle,
              Switch(
                key: const Key('self-camera'),
                value: voice.camera,
                onChanged: (_) => voice.enabled
                    ? voiceCtrl.toggleCamera()
                    : voiceCtrl.enable(camera: true),
              ),
            ),
            if (voice.unavailable) ...[
              const Gap(4),
              Text(
                l10n.voiceUnavailable,
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.destructive,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        PrimaryButton(
          key: const Key('self-menu-close'),
          onPressed: () => closeOverlay<void>(dialog),
          child: Text(l10n.close),
        ),
      ],
    );
  }
}
