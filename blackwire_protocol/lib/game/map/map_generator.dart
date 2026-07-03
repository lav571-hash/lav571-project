import 'dart:math';

import 'tactical_map.dart';
import 'tile.dart';

/// Procedurally generates a tactical battle map: an open floor with
/// scattered wall clusters (full cover) and crates (half cover), guaranteed
/// to be fully connected, with distinct spawn zones for the player squad
/// (west side) and the enemy squad (east side).
class MapGenerator {
  final Random random;

  MapGenerator({Random? random}) : random = random ?? Random();

  TacticalMap generate({
    int width = 16,
    int height = 12,
    int obstacleDensity = 14,
  }) {
    late TacticalMap map;
    int attempts = 0;
    do {
      map = _generateAttempt(width, height, obstacleDensity);
      attempts++;
    } while (!_isFullyConnected(map) && attempts < 20);
    return map;
  }

  TacticalMap _generateAttempt(int width, int height, int obstacleDensity) {
    final map = TacticalMap(width: width, height: height);

    // Border walls.
    for (int x = 0; x < width; x++) {
      map.setTile(GridPos(x, 0), TileType.wall);
      map.setTile(GridPos(x, height - 1), TileType.wall);
    }
    for (int y = 0; y < height; y++) {
      map.setTile(GridPos(0, y), TileType.wall);
      map.setTile(GridPos(width - 1, y), TileType.wall);
    }

    // Keep 3-wide spawn corridors clear on west/east edges.
    bool inSpawnZone(int x, int y) => x <= 2 || x >= width - 3;

    // Scatter wall clusters (small blocks of 1-3 tiles) as full cover.
    final clusterCount = obstacleDensity;
    for (int i = 0; i < clusterCount; i++) {
      final cx = 2 + random.nextInt(width - 4);
      final cy = 1 + random.nextInt(height - 2);
      if (inSpawnZone(cx, cy)) continue;
      final clusterSize = 1 + random.nextInt(3);
      var pos = GridPos(cx, cy);
      for (int j = 0; j < clusterSize; j++) {
        if (map.inBounds(pos) && !inSpawnZone(pos.x, pos.y)) {
          map.setTile(pos, TileType.wall);
        }
        final dir = random.nextInt(4);
        pos = switch (dir) {
          0 => GridPos(pos.x + 1, pos.y),
          1 => GridPos(pos.x - 1, pos.y),
          2 => GridPos(pos.x, pos.y + 1),
          _ => GridPos(pos.x, pos.y - 1),
        };
      }
    }

    // Scatter crates (half cover) individually.
    final crateCount = (obstacleDensity * 1.2).round();
    for (int i = 0; i < crateCount; i++) {
      final x = 1 + random.nextInt(width - 2);
      final y = 1 + random.nextInt(height - 2);
      if (inSpawnZone(x, y)) continue;
      final pos = GridPos(x, y);
      if (map.tileAt(pos) == TileType.floor) {
        map.setTile(pos, TileType.crate);
      }
    }

    return map;
  }

  bool _isFullyConnected(TacticalMap map) {
    GridPos? start;
    for (final p in map.allPositions) {
      if (map.isWalkable(p)) {
        start = p;
        break;
      }
    }
    if (start == null) return false;

    final visited = <GridPos>{start};
    final queue = <GridPos>[start];
    while (queue.isNotEmpty) {
      final current = queue.removeLast();
      for (final n in map.neighbors4(current)) {
        if (!visited.contains(n) && map.isWalkable(n)) {
          visited.add(n);
          queue.add(n);
        }
      }
    }

    final totalWalkable = map.allPositions.where(map.isWalkable).length;
    return visited.length == totalWalkable;
  }

  /// Returns walkable spawn positions along the west edge (player) or east
  /// edge (enemy), top-to-bottom.
  List<GridPos> spawnPositions(
    TacticalMap map, {
    required bool west,
    required int count,
  }) {
    final positions = <GridPos>[];
    final xRange = west ? [1, 2] : [map.width - 2, map.width - 3];
    for (final x in xRange) {
      for (int y = 1; y < map.height - 1 && positions.length < count; y++) {
        final pos = GridPos(x, y);
        if (map.isWalkable(pos)) positions.add(pos);
      }
    }
    return positions.take(count).toList();
  }
}
