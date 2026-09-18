import 'package:flutter/widgets.dart';

/// Picks where a D-pad press moves the cursor: the index of the candidate
/// rect that lies in [direction] from [from] and is closest, preferring
/// candidates that overlap [from] sideways (a column of rows) over ones
/// off to the side (a button at the far end of the row). Null when
/// nothing lies in that direction.
///
/// Flutter's own directional traversal looks at every control on screen;
/// this one is fed only the controls of the same dialog, sheet or section,
/// so the cursor never lands on something hidden behind a sheet.
int? padNeighbour(
  Rect from,
  List<Rect> candidates,
  TraversalDirection direction,
) {
  final c = from.center;
  int? best;
  var bestScore = double.infinity;
  for (var i = 0; i < candidates.length; i++) {
    final r = candidates[i];
    if (r.isEmpty) continue;
    final rc = r.center;
    final double primary;
    final double secondary;
    final bool inBand;
    switch (direction) {
      case TraversalDirection.up:
        primary = c.dy - rc.dy;
        secondary = (rc.dx - c.dx).abs();
        inBand = r.right > from.left && r.left < from.right;
      case TraversalDirection.down:
        primary = rc.dy - c.dy;
        secondary = (rc.dx - c.dx).abs();
        inBand = r.right > from.left && r.left < from.right;
      case TraversalDirection.left:
        primary = c.dx - rc.dx;
        secondary = (rc.dy - c.dy).abs();
        inBand = r.bottom > from.top && r.top < from.bottom;
      case TraversalDirection.right:
        primary = rc.dx - c.dx;
        secondary = (rc.dy - c.dy).abs();
        inBand = r.bottom > from.top && r.top < from.bottom;
    }
    if (primary <= 1) continue;
    final score = primary + secondary * (inBand ? 0.5 : 3);
    if (score < bestScore) {
      bestScore = score;
      best = i;
    }
  }
  return best;
}
