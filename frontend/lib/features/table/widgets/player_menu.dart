import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../../../app/l10n.dart';
import '../../../core/peer_prefs.dart';
import '../../../protocol/protocol.dart';
import '../../admin/admin_player_actions.dart';

/// The menu on another player's seat, for every viewer: their voice volume
/// and mute, and whether their video, hat and win streak are shown, all
/// only on this device. The host also gets the table-wide actions below.
Future<void> showPlayerMenu(
  BuildContext context, {
  required PlayerView player,
  AdminPlayerActions? admin,
}) {
  return showOverlay<void>(
    context,
    const DialogConfiguration(),
    builder: (dialog) =>
        _PlayerMenu(dialog: dialog, player: player, admin: admin),
  ).future;
}

class _PlayerMenu extends ConsumerWidget {
  const _PlayerMenu({
    required this.dialog,
    required this.player,
    required this.admin,
  });

  final BuildContext dialog;
  final PlayerView player;
  final AdminPlayerActions? admin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final prefs =
        ref.watch(peerPrefsProvider.select((m) => m[player.id])) ??
        PeerPrefs.none;
    final notifier = ref.read(peerPrefsProvider.notifier);
    void set(PeerPrefs p) => notifier.set(player.id, p);

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
    Widget toggle(
      IconData icon,
      String label,
      bool value,
      ValueChanged<bool> onChanged, {
      required Key key,
    }) =>
        row(icon, label, Switch(key: key, value: value, onChanged: onChanged));

    final admin = this.admin;
    return AlertDialog(
      title: Text(player.name),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.playerMenuLocal.toUpperCase())
                .muted()
                .xSmall()
                .semiBold(),
            const Gap(4),
            row(
              LucideIcons.volume2,
              l10n.peerVolume,
              SizedBox(
                width: 150,
                child: Row(
                  children: [
                    Expanded(
                      child: Slider(
                        key: const Key('peer-volume'),
                        value: SliderValue.single(prefs.volume),
                        onChanged: prefs.muted
                            ? null
                            : (v) => set(prefs.copyWith(volume: v.value)),
                      ),
                    ),
                    const Gap(6),
                    SizedBox(
                      width: 36,
                      child: Text(
                        '${(prefs.effectiveVolume * 100).round()}%',
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'GeistMono',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            toggle(
              LucideIcons.volumeX,
              l10n.peerMute,
              prefs.muted,
              (v) => set(prefs.copyWith(muted: v)),
              key: const Key('peer-mute'),
            ),
            toggle(
              LucideIcons.videoOff,
              l10n.peerHideVideo,
              prefs.hideVideo,
              (v) => set(prefs.copyWith(hideVideo: v)),
              key: const Key('peer-hide-video'),
            ),
            toggle(
              LucideIcons.crown,
              l10n.peerHideHat,
              prefs.hideHat,
              (v) => set(prefs.copyWith(hideHat: v)),
              key: const Key('peer-hide-hat'),
            ),
            toggle(
              LucideIcons.flame,
              l10n.peerHideHeat,
              prefs.hideHeat,
              (v) => set(prefs.copyWith(hideHeat: v)),
              key: const Key('peer-hide-heat'),
            ),
            toggle(
              LucideIcons.smile,
              l10n.peerHideStickers,
              prefs.hideStickers,
              (v) => set(prefs.copyWith(hideStickers: v)),
              key: const Key('peer-hide-stickers'),
            ),
            const Gap(4),
            Text(l10n.playerMenuLocalHint).muted().xSmall(),
            if (admin != null) ...[
              const Gap(12),
              const Divider(),
              const Gap(8),
              Text(l10n.playerMenuEveryone.toUpperCase())
                  .muted()
                  .xSmall()
                  .semiBold(),
              const Gap(6),
              ...admin.actionButtons(
                dialog: dialog,
                playerId: player.id,
                name: player.name,
                chatMuted: player.muted ?? false,
                voice: player.voice,
                camera: player.camera ?? false,
              ),
            ],
          ],
        ),
      ),
      actions: [
        if (!prefs.isDefault)
          OutlineButton(
            key: const Key('peer-reset'),
            onPressed: () => notifier.reset(player.id),
            child: Text(l10n.peerReset),
          ),
        PrimaryButton(
          key: const Key('player-menu-close'),
          onPressed: () => closeOverlay<void>(dialog),
          child: Text(l10n.close),
        ),
      ],
    );
  }
}
