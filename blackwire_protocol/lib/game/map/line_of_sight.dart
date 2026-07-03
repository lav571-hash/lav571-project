import 'tactical_map.dart';
import 'tile.dart';

/// Line-of-sight utilities based on Bresenham's line algorithm.
class LineOfSight {
  /// Returns true if there is an unobstructed line of sight between [from]
  /// and [to] on [map]. Full-cover tiles (walls) block sight; half-cover
  /// (crates) do not.
  static bool hasLineOfSight(TacticalMap map, GridPos from, GridPos to) {
    final points = _bresenhamLine(from, to);
    // Skip the origin and destination tiles themselves - a unit standing
    // behind cover can still be seen/targeted, cover only affects hit
    // chance, not visibility.
    for (int i = 1; i < points.length - 1; i++) {
      if (map.blocksSight(points[i])) return false;
    }
    return true;
  }

  /// Computes the set of tiles visible from [origin] within [range] tiles,
  /// respecting line-of-sight blocking tiles (walls).
  static Set<GridPos> computeVisibleTiles(
    TacticalMap map,
    GridPos origin,
    int range,
  ) {
    final visible = <GridPos>{origin};
    for (final pos in map.allPositions) {
      if (pos == origin) continue;
      if (origin.chebyshevDistanceTo(pos) > range) continue;
      if (hasLineOfSight(map, origin, pos)) {
        visible.add(pos);
      }
    }
    return visible;
  }

  static List<GridPos> _bresenhamLine(GridPos from, GridPos to) {
    final points = <GridPos>[];
    int x0 = from.x, y0 = from.y;
    final x1 = to.x, y1 = to.y;
    final dx = (x1 - x0).abs();
    final dy = -(y1 - y0).abs();
    final sx = x0 < x1 ? 1 : -1;
    final sy = y0 < y1 ? 1 : -1;
    int err = dx + dy;

    while (true) {
      points.add(GridPos(x0, y0));
      if (x0 == x1 && y0 == y1) break;
      final e2 = 2 * err;
      if (e2 >= dy) {
        err += dy;
        x0 += sx;
      }
      if (e2 <= dx) {
        err += dx;
        y0 += sy;
      }
    }
    return points;
  }
}
