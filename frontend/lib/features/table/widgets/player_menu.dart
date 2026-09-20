import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../../../app/l10n.dart';
import '../../../core/account.dart';
import '../../../core/friends.dart';
import '../../../core/peer_prefs.dart';
import '../../../core/providers.dart';
import '../../../core/rest_client.dart';
import '../../../protocol/protocol.dart';
import '../../admin/admin_player_actions.dart';
import '../../friends/profile_dialog.dart';
import '../table_session.dart';

/// The menu on another player's seat, for every viewer: their voice volume
/// and mute, and whether their video, hat and win streak are shown, all
/// only on this device. The host also gets the table-wide actions below.
Future<void> showPlayerMenu(
  BuildContext context, {
  required String tableId,
  required PlayerView player,
  AdminPlayerActions? admin,
}) {
  return showOverlay<void>(
    context,
    const DialogConfiguration(),
    builder: (dialog) => _PlayerMenu(
      dialog: dialog,
      tableId: tableId,
      player: player,
      admin: admin,
    ),
  ).future;
}

class _PlayerMenu extends ConsumerWidget {
  const _PlayerMenu({
    required this.dialog,
    required this.tableId,
    required this.player,
    required this.admin,
  });

  final BuildContext dialog;
  final String tableId;

  /// The player as seen when the menu opened; the live state is watched.
  final PlayerView player;
  final AdminPlayerActions? admin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    // Follow the server: a switch the host flips shows its new state.
    final player =
        ref.watch(
          tableSessionProvider(tableId).select((s) {
            for (final sv in s.snapshot?.seats ?? const <SeatView>[]) {
              if (sv.player?.id == this.player.id) return sv.player;
            }
            return null;
          }),
        ) ??
        this.player;
    final prefs =
        ref.watch(peerPrefsProvider.select((m) => m[player.id])) ??
        PeerPrefs.none;
    // A tournament: nobody hands out chips, the host included.
    final tournament = ref.watch(
      tableSessionProvider(tableId)
          .select((s) => s.snapshot?.table.settings.tournament ?? false),
    );
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
    final handle = player.account;
    return AlertDialog(
      // A signed-in player carries their profile name under the one they
      // sat down with; a guest shows nothing extra.
      title: handle == null || handle.isEmpty
          ? Text(player.name)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(player.name),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(LucideIcons.userCheck, size: 12),
                    const Gap(4),
                    Text(
                      '@$handle',
                      key: const Key('player-handle'),
                    ).muted().small(),
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
            // A player with a profile can be looked up and befriended;
            // a guest is just the name on the seat.
            if (handle != null && handle.isNotEmpty) ...[
              _ProfileActions(handle: handle),
              const Gap(12),
              const Divider(),
              const Gap(8),
            ],
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
            toggle(
              LucideIcons.pencilOff,
              l10n.peerHideDrawings,
              prefs.hideDrawings,
              (v) => set(prefs.copyWith(hideDrawings: v)),
              key: const Key('peer-hide-drawings'),
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
              const Gap(4),
              // Muted: no chat, no stickers, no drawings. The host may lift
              // this one again.
              toggle(
                LucideIcons.messageSquareOff,
                l10n.hostMuteAll,
                player.muted ?? false,
                (v) => admin.muteChat(player.id, muted: v),
                key: const Key('host-mute-all'),
              ),
              // Microphone and camera: the host can only switch them off;
              // only the player turns them on again.
              row(
                LucideIcons.mic,
                l10n.hostMic,
                Tooltip(
                  tooltip: TooltipContainer(
                    child: Text(
                      player.voice == 'on'
                          ? l10n.adminMuteVoice
                          : l10n.hostOnlyPlayerUnmutes,
                    ),
                  ).call,
                  child: Switch(
                    key: const Key('host-mic'),
                    value: player.voice == 'on',
                    onChanged: player.voice == 'on'
                        ? (_) => admin.muteVoice(player.id)
                        : null,
                  ),
                ),
              ),
              row(
                LucideIcons.video,
                l10n.hostCamera,
                Tooltip(
                  tooltip: TooltipContainer(
                    child: Text(
                      (player.camera ?? false)
                          ? l10n.adminCameraOff
                          : l10n.hostOnlyPlayerUnmutes,
                    ),
                  ).call,
                  child: Switch(
                    key: const Key('host-camera'),
                    value: player.camera ?? false,
                    onChanged: (player.camera ?? false)
                        ? (_) => admin.cameraOff(player.id)
                        : null,
                  ),
                ),
              ),
              const Gap(8),
              Row(
                children: [
                  if (!tournament) ...[
                    Expanded(
                      child: OutlineButton(
                        key: const Key('player-action-chips'),
                        onPressed: () {
                          closeOverlay<void>(dialog);
                          admin.chips(player.id, player.name);
                        },
                        leading: const Icon(LucideIcons.coins),
                        child: Text(l10n.adminChips),
                      ),
                    ),
                    const Gap(8),
                  ],
                  Expanded(
                    child: DestructiveButton(
                      key: const Key('player-action-kick'),
                      onPressed: () {
                        closeOverlay<void>(dialog);
                        admin.kick(player.id, player.name);
                      },
                      leading: const Icon(LucideIcons.userX),
                      child: Text(l10n.adminKick),
                    ),
                  ),
                ],
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

/// What one player can do about another's profile: look at it, and ask to
/// be friends. Nothing at all for a viewer who is not signed in.
class _ProfileActions extends ConsumerStatefulWidget {
  const _ProfileActions({required this.handle});

  final String handle;

  @override
  ConsumerState<_ProfileActions> createState() => _ProfileActionsState();
}

class _ProfileActionsState extends ConsumerState<_ProfileActions> {
  bool _busy = false;
  String? _sent;

  Future<void> _ask() async {
    final token = ref.read(accountProvider.notifier).token;
    if (token == null) return;
    setState(() => _busy = true);
    try {
      final state = await ref
          .read(friendsApiProvider)
          .request(token, widget.handle);
      ref.invalidate(friendsProvider);
      if (mounted) setState(() => _sent = state);
    } on ApiException catch (e) {
      if (mounted) setState(() => _sent = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (ref.watch(accountsEnabledProvider).value != true) {
      return const SizedBox.shrink();
    }
    final me = ref.watch(accountProvider).value;
    if (me == null || me.handle == widget.handle) {
      return const SizedBox.shrink();
    }
    final friends = ref.watch(friendsProvider).value;
    final already =
        friends?.friends.any((f) => f.handle == widget.handle) ?? false;
    final asked =
        friends?.outgoing.any((f) => f.handle == widget.handle) ?? false;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (already)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                const Icon(LucideIcons.users, size: 12),
                const Gap(6),
                Text(l10n.playerIsFriend).muted().xSmall(),
              ],
            ),
          ),
        Row(
          children: [
            Expanded(
              child: (already ? PrimaryButton.new : OutlineButton.new)(
                key: const Key('player-profile'),
                onPressed: () => showProfileDialog(context, widget.handle),
                leading: const Icon(LucideIcons.idCard, size: 14),
                child: Text(
                  already ? l10n.playerFriendRecord : l10n.profileOpen,
                ),
              ),
            ),
            if (!already) ...[
              const Gap(6),
              Expanded(
                child: OutlineButton(
                  key: const Key('player-add-friend'),
                  enabled: !_busy && !asked && _sent == null,
                  onPressed: _ask,
                  leading: const Icon(LucideIcons.userPlus, size: 14),
                  child: Text(
                    asked || _sent != null
                        ? l10n.friendsAsked
                        : l10n.friendsAdd,
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
