import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../../../app/l10n.dart';
import '../../../app/preferences.dart';
import '../../../app/theme.dart';
import '../../../core/turn_notifier.dart';
import '../../../core/voice/voice_controller.dart';
import '../../../shared/kbd_hint.dart';

/// True while the browser's notification prompt is open.
bool _notifyPrompt = false;

/// The settings tab of the side panel: one row per setting, icon and label
/// on the left, the control on the right (a switch, a small button or a
/// segmented choice). Sections: voice and video, preferences, table.
class TableSettingsTab extends ConsumerWidget {
  const TableSettingsTab({
    super.key,
    required this.tableId,
    required this.isPlayer,
    required this.onTakeSeat,
    required this.onOtherTable,
    required this.onLeave,
    required this.onShortcuts,
  });

  final String tableId;
  final bool isPlayer;
  final VoidCallback onTakeSeat;
  final VoidCallback onOtherTable;
  final VoidCallback onLeave;
  final VoidCallback onShortcuts;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final sound = ref.watch(soundEnabledProvider);
    final fourColor = ref.watch(fourColorDeckProvider);
    final chipDisplay = ref.watch(chipDisplayProvider);
    final voice = ref.watch(voiceControllerProvider(tableId));
    final notify = ref.watch(notifyTurnProvider);
    final showCameras = ref.watch(showCamerasProvider);
    final scale = ref.watch(uiScaleProvider);
    final notifier = TurnNotifier.create();
    final voiceCtrl = ref.read(voiceControllerProvider(tableId).notifier);
    final brightness = theme.colorScheme.brightness;
    final locale = Localizations.localeOf(context);
    final wide = MediaQuery.sizeOf(context).width >= KbdHint.minWidth;

    Widget section(String title) => Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 4),
      child: Text(title.toUpperCase()).muted().xSmall().semiBold(),
    );
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
            if (isPlayer) ...[
              section(l10n.voiceTitle),
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
            ],
            section(l10n.menuPreferences),
            toggle(
              LucideIcons.volume2,
              l10n.soundOn,
              sound,
              () => ref.read(soundEnabledProvider.notifier).toggle(),
              key: const Key('drawer-sound'),
            ),
            toggle(
              LucideIcons.palette,
              l10n.fourColorDeck,
              fourColor,
              () => ref.read(fourColorDeckProvider.notifier).set(!fourColor),
              key: const Key('drawer-deck'),
            ),
            toggle(
              LucideIcons.coins,
              l10n.showBigBlinds,
              chipDisplay == ChipDisplay.bigBlinds,
              () => ref.read(chipDisplayProvider.notifier).toggle(),
              key: const Key('drawer-chips'),
            ),
            if (notifier.supported)
              toggle(
                LucideIcons.bellRing,
                l10n.notifyTurn,
                notify,
                toggleNotify,
                key: const Key('drawer-notify'),
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
            section(l10n.menuTable),
            if (!isPlayer)
              button(
                LucideIcons.armchair,
                l10n.takeSeat,
                l10n.takeSeat,
                onTakeSeat,
                key: const Key('menu-take-seat'),
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
            const Gap(12),
          ],
        ),
      ),
    );
  }
}
