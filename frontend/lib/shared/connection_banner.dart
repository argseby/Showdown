import 'package:shadcn_flutter/shadcn_flutter.dart';

/// A full-width notice at the top of the screen.
class ConnectionBanner extends StatelessWidget {
  const ConnectionBanner({
    super.key,
    required this.text,
    this.destructive = false,
    this.trailing,
  });

  final String text;
  final bool destructive;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = destructive
        ? theme.colorScheme.destructive
        : theme.colorScheme.secondary;
    final fg = destructive
        ? theme.colorScheme.primaryForeground
        : theme.colorScheme.secondaryForeground;
    return Container(
      width: double.infinity,
      color: bg,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(
            destructive ? LucideIcons.triangleAlert : LucideIcons.refreshCw,
            size: 16,
            color: fg,
          ),
          const Gap(8),
          Expanded(
            child: Text(text, style: TextStyle(color: fg)),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
