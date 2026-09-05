import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../app/l10n.dart';
import '../app/theme.dart';

/// Application bar with the theme and language toggles that every screen
/// shares. Screens add their own [trailing] controls in front of them.
class TopBar extends ConsumerWidget {
  const TopBar({
    super.key,
    required this.title,
    this.subtitle,
    this.leading = const [],
    this.trailing = const [],
    this.compact = false,
    this.showToggles = true,
  });

  final Widget title;
  final Widget? subtitle;
  final List<Widget> leading;
  final List<Widget> trailing;

  /// Narrow screens: language and theme toggles move into a single menu
  /// button so the bar stays on one line.
  final bool compact;

  /// Screens with their own menu (the table) hide the toggles here.
  final bool showToggles;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final brightness = Theme.of(context).colorScheme.brightness;
    final locale = Localizations.localeOf(context);

    final languageButton = Tooltip(
      tooltip: TooltipContainer(child: Text(l10n.languageToggle)).call,
      child: GhostButton(
        density: ButtonDensity.icon,
        onPressed: () =>
            ref.read(localePreferenceProvider.notifier).next(locale),
        child: Text(locale.languageCode.toUpperCase()).semiBold().small(),
      ),
    );
    final themeButton = Tooltip(
      tooltip: TooltipContainer(child: Text(l10n.themeToggle)).call,
      child: GhostButton(
        density: ButtonDensity.icon,
        onPressed: () =>
            ref.read(themeModeProvider.notifier).toggle(brightness),
        child: Icon(
          brightness == Brightness.dark ? LucideIcons.sun : LucideIcons.moon,
        ),
      ),
    );
    if (!showToggles) {
      return AppBar(
        title: title,
        subtitle: compact ? null : subtitle,
        leading: leading,
        trailing: trailing,
      );
    }
    if (compact) {
      return AppBar(
        title: title,
        leading: leading,
        trailing: [...trailing, languageButton, themeButton],
      );
    }
    return AppBar(
      title: title,
      subtitle: subtitle,
      leading: leading,
      trailing: [
        ...trailing,
        Tooltip(
          tooltip: TooltipContainer(child: Text(l10n.languageToggle)).call,
          child: GhostButton(
            density: ButtonDensity.icon,
            onPressed: () =>
                ref.read(localePreferenceProvider.notifier).next(locale),
            child: Text(locale.languageCode.toUpperCase()).semiBold().small(),
          ),
        ),
        Tooltip(
          tooltip: TooltipContainer(child: Text(l10n.themeToggle)).call,
          child: GhostButton(
            density: ButtonDensity.icon,
            onPressed: () =>
                ref.read(themeModeProvider.notifier).toggle(brightness),
            child: Icon(
              brightness == Brightness.dark
                  ? LucideIcons.sun
                  : LucideIcons.moon,
            ),
          ),
        ),
      ],
    );
  }
}
