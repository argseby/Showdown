import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../../../app/l10n.dart';
import '../../../app/preferences.dart';
import '../../../app/theme.dart';
import '../../../core/turn_notifier.dart';
import '../../../core/voice/voice_controller.dart';
import '../../../shared/display_size_picker.dart';
import '../../../shared/kbd_hint.dart';

/// The settings tab of the side panel: voice chat, preferences (sound, deck
/// colours, coins/BB, display size, language, theme, shortcuts) and the
/// table actions (take a seat, other table, leave).
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
    final notifier = TurnNotifier.create();
    final brightness = theme.colorScheme.brightness;
    final locale = Localizations.localeOf(context);
    final wide = MediaQuery.sizeOf(context).width >= KbdHint.minWidth;

    Widget section(String title) => Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 6),
      child: Text(title).muted().small(),
    );
    Widget toggle(
      String label,
      IconData icon,
      bool value,
      VoidCallback onTap, {
      Key? key,
    }) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.mutedForeground),
          const Gap(10),
          Expanded(child: Text(label)),
          Switch(key: key, value: value, onChanged: (_) => onTap()),
        ],
      ),
    );
    Widget action(
      String label,
      IconData icon,
      VoidCallback onTap, {
      Key? key,
      bool destructive = false,
    }) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: (destructive ? DestructiveButton.new : OutlineButton.new)(
        key: key,
        size: ButtonSize.small,
        onPressed: onTap,
        alignment: Alignment.centerLeft,
        leading: Icon(icon, size: 16),
        child: Text(label),
      ),
    );

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isPlayer) ...[
              section(l10n.voiceTitle),
              toggle(
                voice.enabled ? l10n.voiceOn : l10n.voiceOff,
                LucideIcons.headphones,
                voice.enabled,
                () => voice.enabled
                    ? ref
                          .read(voiceControllerProvider(tableId).notifier)
                          .disable()
                    : ref
                          .read(voiceControllerProvider(tableId).notifier)
                          .enable(),
                key: const Key('drawer-voice'),
              ),
              if (voice.enabled)
                toggle(
                  voice.muted ? l10n.voiceMicMuted : l10n.voiceMicOn,
                  voice.muted ? LucideIcons.micOff : LucideIcons.mic,
                  !voice.muted,
                  () => ref
                      .read(voiceControllerProvider(tableId).notifier)
                      .toggleMute(),
                  key: const Key('drawer-mute'),
                ),
              if (voice.unavailable)
                Text(
                  l10n.voiceUnavailable,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.destructive,
                  ),
                ),
            ],
            section(l10n.menuPreferences),
            toggle(
              sound ? l10n.soundOn : l10n.soundOff,
              sound ? LucideIcons.volume2 : LucideIcons.volumeX,
              sound,
              () => ref.read(soundEnabledProvider.notifier).toggle(),
              key: const Key('drawer-sound'),
            ),
            toggle(
              l10n.fourColorDeck,
              LucideIcons.palette,
              fourColor,
              () => ref.read(fourColorDeckProvider.notifier).set(!fourColor),
              key: const Key('drawer-deck'),
            ),
            toggle(
              l10n.showBigBlinds,
              LucideIcons.coins,
              chipDisplay == ChipDisplay.bigBlinds,
              () => ref.read(chipDisplayProvider.notifier).toggle(),
              key: const Key('drawer-chips'),
            ),
            if (notifier.supported) ...[
              toggle(l10n.notifyTurn, LucideIcons.bellRing, notify, () async {
                if (notify) {
                  ref.read(notifyTurnProvider.notifier).set(false);
                  return;
                }
                final ok = await notifier.requestPermission();
                ref.read(notifyTurnProvider.notifier).set(ok);
                if (!ok && context.mounted) {
                  showToast(
                    context: context,
                    location: ToastLocation.bottomCenter,
                    builder: (context, overlay) =>
                        SurfaceCard(child: Text(l10n.notifyDenied)),
                  );
                }
              }, key: const Key('drawer-notify')),
              Padding(
                padding: const EdgeInsets.only(left: 28, bottom: 4),
                child: Text(l10n.notifyTurnHint).muted().small(),
              ),
            ],
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(
                    LucideIcons.zoomIn,
                    size: 18,
                    color: theme.colorScheme.mutedForeground,
                  ),
                  const Gap(10),
                  Expanded(child: Text(l10n.displaySize)),
                ],
              ),
            ),
            const DisplaySizePicker(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(
                    LucideIcons.languages,
                    size: 18,
                    color: theme.colorScheme.mutedForeground,
                  ),
                  const Gap(10),
                  Expanded(child: Text(l10n.languageToggle)),
                  OutlineButton(
                    size: ButtonSize.small,
                    onPressed: () => ref
                        .read(localePreferenceProvider.notifier)
                        .next(locale),
                    child: Text(locale.languageCode.toUpperCase()),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(
                    brightness == Brightness.dark
                        ? LucideIcons.sun
                        : LucideIcons.moon,
                    size: 18,
                    color: theme.colorScheme.mutedForeground,
                  ),
                  const Gap(10),
                  Expanded(child: Text(l10n.themeToggle)),
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
                ],
              ),
            ),
            if (wide)
              action(l10n.shortcutsTitle, LucideIcons.keyboard, onShortcuts),
            section(l10n.menuTable),
            if (!isPlayer)
              action(
                l10n.takeSeat,
                LucideIcons.armchair,
                onTakeSeat,
                key: const Key('menu-take-seat'),
              ),
            action(
              l10n.otherTable,
              LucideIcons.house,
              onOtherTable,
              key: const Key('menu-other-table'),
            ),
            action(
              l10n.leave,
              LucideIcons.logOut,
              onLeave,
              key: const Key('menu-leave'),
              destructive: true,
            ),
          ],
        ),
      ),
    );
  }
}
