import 'dart:math';

import 'package:blackwire_protocol/game/map/map_generator.dart';
import 'package:blackwire_protocol/game/map/tile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MapGenerator', () {
    test('generates a fully connected walkable map', () {
      for (int seed = 0; seed < 10; seed++) {
        final generator = MapGenerator(random: Random(seed));
        final map = generator.generate(width: 16, height: 12);

        final walkable = map.allPositions.where(map.isWalkable).toList();
        expect(walkable, isNotEmpty);

        final start = walkable.first;
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

        expect(
          visited.length,
          walkable.length,
          reason: 'seed=$seed map must be fully connected',
        );
      }
    });

    test('border tiles are always walls', () {
      final generator = MapGenerator(random: Random(1));
      final map = generator.generate(width: 16, height: 12);
      for (int x = 0; x < map.width; x++) {
        expect(map.tileAt(GridPos(x, 0)), TileType.wall);
        expect(map.tileAt(GridPos(x, map.height - 1)), TileType.wall);
      }
      for (int y = 0; y < map.height; y++) {
        expect(map.tileAt(GridPos(0, y)), TileType.wall);
        expect(map.tileAt(GridPos(map.width - 1, y)), TileType.wall);
      }
    });

    test('spawnPositions returns walkable tiles on requested side', () {
      final generator = MapGenerator(random: Random(2));
      final map = generator.generate(width: 16, height: 12);
      final west = generator.spawnPositions(map, west: true, count: 4);
      final east = generator.spawnPositions(map, west: false, count: 4);

      for (final p in west) {
        expect(map.isWalkable(p), isTrue);
        expect(p.x, lessThanOrEqualTo(2));
      }
      for (final p in east) {
        expect(map.isWalkable(p), isTrue);
        expect(p.x, greaterThanOrEqualTo(map.width - 3));
      }
    });
  });
}
