import 'package:shadcn_flutter/shadcn_flutter.dart';

import 'hats.dart';

/// The twenty predefined avatars: a Lucide icon (bundled with shadcn_flutter,
/// no assets, no network) on a colored disc.
const avatarIcons = <IconData>[
  LucideIcons.cat,
  LucideIcons.dog,
  LucideIcons.bird,
  LucideIcons.fish,
  LucideIcons.rabbit,
  LucideIcons.turtle,
  LucideIcons.squirrel,
  LucideIcons.snail,
  LucideIcons.bug,
  LucideIcons.ghost,
  LucideIcons.skull,
  LucideIcons.crown,
  LucideIcons.rocket,
  LucideIcons.anchor,
  LucideIcons.flame,
  LucideIcons.zap,
  LucideIcons.sun,
  LucideIcons.moon,
  LucideIcons.gem,
  LucideIcons.cherry,
];

/// Number of predefined avatars (must match the server's AvatarCount).
const avatarCount = 20;

/// Disc color for an avatar index.
Color avatarColor(int index) {
  final hue = (index.clamp(0, avatarCount - 1) * 360 / avatarCount) % 360;
  return HSLColor.fromAHSL(1, hue, 0.55, 0.42).toColor();
}

/// A player avatar: icon on a colored disc, with a hat on top when the
/// player wears one. The hat overflows the disc upwards without changing
/// the widget's own size.
class PlayerAvatar extends StatelessWidget {
  const PlayerAvatar({
    super.key,
    required this.index,
    this.size = 42,
    this.selected = false,
    this.hat,
  });

  final int index;
  final double size;
  final bool selected;

  /// A hat id (see hats.dart); null, empty or "none" for no hat.
  final String? hat;

  @override
  Widget build(BuildContext context) {
    final i = index.clamp(0, avatarCount - 1);
    final theme = Theme.of(context);
    final disc = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: avatarColor(i),
        border: selected
            ? Border.all(color: theme.colorScheme.primary, width: 3)
            : null,
      ),
      child: Icon(
        avatarIcons[i],
        size: size * 0.55,
        color: const Color(0xFFFFFFFF),
      ),
    );
    if (!wearsHat(hat)) return disc;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        disc,
        Positioned(
          left: size * (1 - hatWidth) / 2,
          top: -size * hatOverflow,
          child: IgnorePointer(
            child: PlayerHat(hat: hat!, width: size * hatWidth),
          ),
        ),
      ],
    );
  }
}

/// A grid of the twenty avatars with the selected one outlined.
class AvatarPicker extends StatelessWidget {
  const AvatarPicker({
    super.key,
    required this.selected,
    required this.onSelected,
    this.size = 40,
  });

  final int selected;
  final ValueChanged<int> onSelected;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (var i = 0; i < avatarCount; i++)
          GestureDetector(
            key: Key('avatar-$i'),
            onTap: () => onSelected(i),
            child: PlayerAvatar(index: i, size: size, selected: i == selected),
          ),
      ],
    );
  }
}
