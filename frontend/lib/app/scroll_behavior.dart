import 'package:shadcn_flutter/shadcn_flutter.dart';

/// Scrolling without the platform's scrollbar.
///
/// shadcn draws one down the right edge of every vertical scrollable on a
/// desktop or on the web, which lands on top of panels, dialogs and the
/// felt — surfaces that already end somewhere visible, so the bar reads as
/// a stray line across them. Everything else it sets (bouncing physics,
/// which pointers may drag) stays as it is.
class NoScrollbarBehavior extends ShadcnScrollBehavior {
  const NoScrollbarBehavior();

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) => child;
}
