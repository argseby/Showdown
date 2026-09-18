import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The areas of the table screen a controller can jump between: the
/// action bar at the bottom, the table with its seats and the top bar,
/// and the side panel (chat, log, leaderboard, settings).
enum PadSection { actions, table, panel }

/// One legend entry: the controller buttons and what they do here.
typedef PadLegendItem = (String buttons, String text);

/// Where the controller's cursor is and what the buttons do there. The
/// table screen recomputes it between frames; the legend strip and the
/// side panel's caps watch it (a sheet keeps the widget it was opened
/// with, so this must not travel as a constructor parameter).
class PadCursor {
  const PadCursor({
    this.section,
    this.dialog = false,
    this.where = '',
    this.legend = const [],
  });

  final PadSection? section;
  final bool dialog;
  final String where;
  final List<PadLegendItem> legend;
}

class PadCursorNotifier extends Notifier<PadCursor> {
  @override
  PadCursor build() => const PadCursor();

  void set(PadCursor cursor) => state = cursor;
}

final padCursorProvider = NotifierProvider<PadCursorNotifier, PadCursor>(
  PadCursorNotifier.new,
);

/// Marks the subtree as one [PadSection], so that a focus node can be
/// assigned to a section by walking up from its context.
class PadSectionScope extends InheritedWidget {
  const PadSectionScope({
    super.key,
    required this.section,
    required super.child,
  });

  final PadSection section;

  /// The section [context] sits in, without registering a dependency.
  static PadSection? of(BuildContext context) =>
      context.getInheritedWidgetOfExactType<PadSectionScope>()?.section;

  @override
  bool updateShouldNotify(PadSectionScope oldWidget) =>
      section != oldWidget.section;
}
