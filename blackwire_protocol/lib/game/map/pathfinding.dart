import 'tactical_map.dart';
import 'tile.dart';

/// BFS-based pathfinding for the uniform-cost tactical grid (each step costs
/// exactly 1 movement point, diagonal movement is not allowed to keep cover
/// geometry simple and readable).
class Pathfinding {
  /// Returns a map of every position reachable from [start] within
  /// [maxSteps], to the shortest path (list of positions, excluding start)
  /// leading there. Positions occupied by [blocked] units (other than the
  /// mover) are treated as impassable.
  static Map<GridPos, List<GridPos>> reachableTiles(
    TacticalMap map,
    GridPos start,
    int maxSteps, {
    Set<GridPos> blocked = const {},
  }) {
    final result = <GridPos, List<GridPos>>{};
    final visited = <GridPos, int>{start: 0};
    final queue = <GridPos>[start];
    final cameFrom = <GridPos, GridPos>{};

    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);
      final dist = visited[current]!;
      if (dist >= maxSteps) continue;
      for (final next in map.neighbors4(current)) {
        if (visited.containsKey(next)) continue;
        if (map.blocksMovement(next)) continue;
        if (blocked.contains(next)) continue;
        visited[next] = dist + 1;
        cameFrom[next] = current;
        queue.add(next);
      }
    }

    for (final pos in visited.keys) {
      if (pos == start) continue;
      final path = <GridPos>[];
      var cur = pos;
      while (cur != start) {
        path.insert(0, cur);
        cur = cameFrom[cur]!;
      }
      result[pos] = path;
    }
    return result;
  }
}
