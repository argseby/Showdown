import 'package:shadcn_flutter/shadcn_flutter.dart';

/// The four-suit banner. Its white outline keeps the black suits readable
/// on the dark theme, so it sits directly on the background.
class Logo extends StatelessWidget {
  const Logo({super.key, this.height = 28});

  /// The rendered height; the banner is about two and a half times as wide.
  final double height;

  @override
  Widget build(BuildContext context) => Image.asset(
    'assets/logo.png',
    height: height,
    fit: BoxFit.contain,
    filterQuality: FilterQuality.medium,
    excludeFromSemantics: true,
  );
}
