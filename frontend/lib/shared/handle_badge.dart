import 'package:shadcn_flutter/shadcn_flutter.dart';

/// The profile a seat belongs to, under the name it sat down with. Guests
/// have none, and then nothing is drawn.
class HandleBadge extends StatelessWidget {
  const HandleBadge(this.handle, {super.key});

  final String? handle;

  @override
  Widget build(BuildContext context) {
    final h = handle;
    if (h == null || h.isEmpty) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(LucideIcons.userCheck, size: 12),
        const Gap(4),
        Text('@$h', key: const Key('player-handle')).muted().small(),
      ],
    );
  }
}
