import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../../../app/l10n.dart';
import '../../../app/preferences.dart';
import '../../../app/theme.dart';
import '../../../core/gamepad/gamepad.dart';
import '../../../core/turn_notifier.dart';
import '../../../core/voice/voice_controller.dart';
import '../../../shared/kbd_hint.dart';
import '../network_texts.dart';
import '../table_session.dart';
import 'preference_card.dart';
import 'self_menu.dart';

/// True while the browser's notification prompt is open.
bool _notifyPrompt = false;

/// The pages of the settings menu that every player has.
enum SettingsPart { voice, preferences, table }

/// One page of the settings menu: one row per setting, icon and label on
/// the left, the control on the right (a switch, a small button or a
/// segmented choice). [part] picks voice and video, preferences or table.
class TableSettingsTab extends ConsumerWidget {
  const TableSettingsTab({
    super.key,
    required this.part,
    required this.tableId,
    required this.isPlayer,
    required this.onTakeSeat,
    required this.onOtherTable,
    required this.onLeave,
    required this.onShortcuts,
    required this.onRules,
  });

  final SettingsPart part;
  final String tableId;
  final bool isPlayer;
  final VoidCallback onTakeSeat;
  final VoidCallback onOtherTable;
  final VoidCallback onLeave;
  final VoidCallback onShortcuts;

  /// Opens the table rules card (the one shown on joining).
  final VoidCallback onRules;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final sound = ref.watch(soundEnabledProvider);
    final fourColor = ref.watch(fourColorDeckProvider);
    final chipStacks = ref.watch(chipStacksProvider);
    final fixedSeats = ref.watch(fixedSeatsProvider);
    final padHints = ref.watch(padHintsProvider);
    final padOn = ref.watch(gamepadProvider);
    final chipDisplay = ref.watch(chipDisplayProvider);
    final voice = ref.watch(voiceControllerProvider(tableId));
    final notify = ref.watch(notifyTurnProvider);
    final showCameras = ref.watch(showCamerasProvider);
    final showHats = ref.watch(showHatsProvider);
    final showHeat = ref.watch(showHeatProvider);
    final showDrawings = ref.watch(showDrawingsProvider);
    final scale = ref.watch(uiScaleProvider);
    final handLine = ref.watch(handLineProvider);
    final spotlight = ref.watch(showdownSpotlightProvider);
    final notifier = TurnNotifier.create();
    final voiceCtrl = ref.read(voiceControllerProvider(tableId).notifier);
    final isHost = ref.watch(
      tableSessionProvider(tableId)
          .select((s) => s.snapshot?.you.isAdmin ?? false),
    );
    // The viewer's own seat (for the hat and its preview).
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
    final brightness = theme.colorScheme.brightness;
    final locale = Localizations.localeOf(context);
    final wide = MediaQuery.sizeOf(context).width >= KbdHint.minWidth;

    Widget row(IconData icon, String label, Widget trailing) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.mutedForeground),
          const Gap(10),
          Expanded(child: Text(label)),
          trailing,
        ],
      ),
    );
    Widget section(String title) => Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Text(title.toUpperCase()).muted().xSmall().semiBold(),
    );
    Widget toggle(
      IconData icon,
      String label,
      bool value,
      VoidCallback onTap, {
      Key? key,
    }) => row(
      icon,
      label,
      Switch(key: key, value: value, onChanged: (_) => onTap()),
    );
    Widget button(
      IconData icon,
      String label,
      String action,
      VoidCallback onTap, {
      Key? key,
      bool destructive = false,
    }) => row(
      icon,
      label,
      OutlineButton(
        key: key,
        size: ButtonSize.small,
        onPressed: onTap,
        child: Text(
          action,
          style: destructive
              ? TextStyle(color: theme.colorScheme.destructive)
              : null,
        ),
      ),
    );
    Widget error(String text) => Padding(
      padding: const EdgeInsets.only(left: 26, bottom: 4),
      child: Text(
        text,
        style: TextStyle(fontSize: 12, color: theme.colorScheme.destructive),
      ),
    );

    Future<void> toggleNotify() async {
      if (notify) {
        ref.read(notifyTurnProvider.notifier).set(false);
        return;
      }
      // Already decided: no prompt. Otherwise ask once and ignore presses
      // while the browser's prompt is open.
      if (notifier.permission == 'granted') {
        ref.read(notifyTurnProvider.notifier).set(true);
        return;
      }
      if (notifier.permission == 'denied' || _notifyPrompt) {
        if (context.mounted) {
          showToast(
            context: context,
            location: ToastLocation.bottomCenter,
            builder: (context, overlay) =>
                SurfaceCard(child: Text(l10n.notifyDenied)),
          );
        }
        return;
      }
      _notifyPrompt = true;
      final ok = await notifier.requestPermission();
      _notifyPrompt = false;
      ref.read(notifyTurnProvider.notifier).set(ok);
      if (!ok && context.mounted) {
        showToast(
          context: context,
          location: ToastLocation.bottomCenter,
          builder: (context, overlay) =>
              SurfaceCard(child: Text(l10n.notifyDenied)),
        );
      }
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (part == SettingsPart.voice && isPlayer) ...[
              toggle(
                LucideIcons.headphones,
                l10n.voiceTitle,
                voice.enabled,
                () => voice.enabled ? voiceCtrl.disable() : voiceCtrl.enable(),
                key: const Key('drawer-voice'),
              ),
              if (voice.unavailable) error(l10n.voiceUnavailable),
              if (voice.enabled)
                toggle(
                  LucideIcons.mic,
                  l10n.voiceMicOn,
                  !voice.muted,
                  voiceCtrl.toggleMute,
                  key: const Key('drawer-mute'),
                ),
              toggle(
                LucideIcons.video,
                l10n.cameraTitle,
                voice.camera,
                () => voice.enabled
                    ? voiceCtrl.toggleCamera()
                    : voiceCtrl.enable(camera: true),
                key: const Key('drawer-camera'),
              ),
              if (voice.cameraUnavailable)
                error(
                  '${l10n.cameraUnavailable} ${voice.cameraError ?? ''}'.trim(),
                ),
              toggle(LucideIcons.users, l10n.showCameras, showCameras, () {
                ref.read(showCamerasProvider.notifier).set(!showCameras);
                voiceCtrl.setReceiveVideo(!showCameras);
              }, key: const Key('drawer-show-cameras')),
              // What this network allows, checked after joining: the
              // reason when nobody can be heard, and what to do about it.
              if (voice.enabled) ...[
                row(
                  LucideIcons.network,
                  '${l10n.networkCheckTitle}: '
                  '${networkStatus(l10n, voice.network, checking: voice.networkChecking)}',
                  OutlineButton(
                    key: const Key('drawer-network'),
                    size: ButtonSize.small,
                    onPressed: voice.networkChecking
                        ? null
                        : voiceCtrl.checkNetwork,
                    child: Text(l10n.networkCheckAgain),
                  ),
                ),
                if (voice.network?.problem ?? false)
                  error(networkExplanation(l10n, voice.network!, host: isHost)),
              ],
            ],
            if (part == SettingsPart.preferences) ...[
              // What the table looks like, each explained and shown. The
              // rest are one-liners whose name says it all, so they sit
              // together below rather than between the cards, where they
              // read as leftovers.
              section(l10n.prefsTableSection),
              PreferenceCard(
                icon: LucideIcons.palette,
                title: l10n.fourColorDeck,
                body: l10n.fourColorDeckAbout,
                value: fourColor,
                switchKey: const Key('drawer-deck'),
                preview: FourColorPreview(fourColor: fourColor),
                onChanged: (v) =>
                    ref.read(fourColorDeckProvider.notifier).set(v),
              ),
              PreferenceCard(
                icon: LucideIcons.layers,
                title: l10n.chipStacks,
                body: l10n.chipStacksAbout,
                value: chipStacks,
                switchKey: const Key('drawer-chip-stacks'),
                preview: const ChipStackPreview(),
                onChanged: (v) => ref.read(chipStacksProvider.notifier).set(v),
              ),
              PreferenceCard(
                icon: LucideIcons.armchair,
                title: l10n.fixedSeats,
                body: l10n.fixedSeatsAbout,
                value: fixedSeats,
                switchKey: const Key('drawer-fixed-seats'),
                preview: FixedSeatsPreview(fixed: fixedSeats),
                onChanged: (v) => ref.read(fixedSeatsProvider.notifier).set(v),
              ),
              PreferenceCard(
                icon: LucideIcons.sparkles,
                title: l10n.showdownSpotlight,
                body: l10n.showdownSpotlightAbout,
                value: spotlight,
                switchKey: const Key('drawer-spotlight'),
                preview: const SpotlightPreview(),
                onChanged: (v) =>
                    ref.read(showdownSpotlightProvider.notifier).set(v),
              ),
              PreferenceCard(
                icon: LucideIcons.type,
                title: l10n.handLine,
                body: l10n.handLineAbout,
                value: handLine != HandLinePlacement.off,
                preview: HandLinePreview(placement: handLine),
                trailing: OutlineButton(
                  key: const Key('hand-line-placement'),
                  size: ButtonSize.small,
                  onPressed: () => ref.read(handLineProvider.notifier).next(),
                  child: Text(switch (handLine) {
                    HandLinePlacement.off => l10n.handLineOff,
                    HandLinePlacement.board => l10n.handLineBoard,
                    HandLinePlacement.bottom => l10n.handLineBottom,
                  }),
                ),
              ),
              section(l10n.prefsMoreSection),
              toggle(
                LucideIcons.volume2,
                l10n.soundOn,
                sound,
                () => ref.read(soundEnabledProvider.notifier).toggle(),
                key: const Key('drawer-sound'),
              ),
              if (notifier.supported)
                toggle(
                  LucideIcons.bellRing,
                  l10n.notifyTurn,
                  notify,
                  toggleNotify,
                  key: const Key('drawer-notify'),
                ),
              toggle(
                LucideIcons.coins,
                l10n.showBigBlinds,
                chipDisplay == ChipDisplay.bigBlinds,
                () => ref.read(chipDisplayProvider.notifier).toggle(),
                key: const Key('drawer-chips'),
              ),
              toggle(
                LucideIcons.crown,
                l10n.showHats,
                showHats,
                () => ref.read(showHatsProvider.notifier).set(!showHats),
                key: const Key('drawer-hats'),
              ),
              toggle(
                LucideIcons.flame,
                l10n.showHeat,
                showHeat,
                () => ref.read(showHeatProvider.notifier).set(!showHeat),
                key: const Key('drawer-heat'),
              ),
              toggle(
                LucideIcons.pencil,
                l10n.showDrawings,
                showDrawings,
                () =>
                    ref.read(showDrawingsProvider.notifier).set(!showDrawings),
                key: const Key('drawer-drawings'),
              ),
              // Only with a controller: the hints mean nothing without one.
              if (padOn)
                toggle(
                  LucideIcons.gamepad2,
                  l10n.padHints,
                  padHints,
                  () => ref.read(padHintsProvider.notifier).set(!padHints),
                  key: const Key('drawer-pad-hints'),
                ),
              // One button like language and theme: shows the current size and
              // cycles through the options.
              button(
                LucideIcons.zoomIn,
                l10n.displaySize,
                switch (scale) {
                  1.25 => l10n.displayLarge,
                  1.5 => l10n.displayExtraLarge,
                  _ => l10n.displayNormal,
                },
                () {
                  const options = UiScaleNotifier.options;
                  final i = options.indexOf(scale);
                  ref
                      .read(uiScaleProvider.notifier)
                      .set(options[(i + 1) % options.length]);
                },
                key: const Key('display-size'),
              ),
              button(
                LucideIcons.languages,
                l10n.languageToggle,
                locale.languageCode.toUpperCase(),
                () => ref.read(localePreferenceProvider.notifier).next(locale),
              ),
              row(
                brightness == Brightness.dark
                    ? LucideIcons.sun
                    : LucideIcons.moon,
                l10n.themeToggle,
                OutlineButton(
                  size: ButtonSize.small,
                  onPressed: () =>
                      ref.read(themeModeProvider.notifier).toggle(brightness),
                  child: Icon(
                    brightness == Brightness.dark
                        ? LucideIcons.sun
                        : LucideIcons.moon,
                    size: 14,
                  ),
                ),
              ),
              if (wide)
                row(
                  LucideIcons.keyboard,
                  l10n.shortcutsTitle,
                  OutlineButton(
                    size: ButtonSize.small,
                    onPressed: onShortcuts,
                    child: const Text('?'),
                  ),
                ),
            ],
            if (part == SettingsPart.table) ...[
              if (isPlayer && me != null)
                button(
                  LucideIcons.crown,
                  l10n.lookTitle,
                  l10n.joinAvatarChange,
                  () => changeLook(context, ref, tableId, me),
                  key: const Key('drawer-look'),
                ),
              if (!isPlayer)
                button(
                  LucideIcons.armchair,
                  l10n.takeSeat,
                  l10n.takeSeat,
                  onTakeSeat,
                  key: const Key('menu-take-seat'),
                ),
              button(
                LucideIcons.scrollText,
                l10n.rulesTitle,
                l10n.rulesShow,
                onRules,
                key: const Key('menu-rules'),
              ),
              button(
                LucideIcons.house,
                l10n.otherTable,
                l10n.otherTable,
                onOtherTable,
                key: const Key('menu-other-table'),
              ),
              button(
                LucideIcons.logOut,
                l10n.leave,
                l10n.leave,
                onLeave,
                key: const Key('menu-leave'),
                destructive: true,
              ),
            ],
            const Gap(12),
          ],
        ),
      ),
    );
  }
}
