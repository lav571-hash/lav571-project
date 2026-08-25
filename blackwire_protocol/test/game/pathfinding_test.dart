import 'package:blackwire_protocol/game/map/pathfinding.dart';
import 'package:blackwire_protocol/game/map/tactical_map.dart';
import 'package:blackwire_protocol/game/map/tile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Pathfinding.reachableTiles', () {
    test('returns tiles within maxSteps on an open map', () {
      final map = TacticalMap(width: 10, height: 10);
      final reachable = Pathfinding.reachableTiles(map, const GridPos(5, 5), 2);
      expect(reachable.containsKey(const GridPos(5, 3)), isTrue);
      expect(reachable.containsKey(const GridPos(5, 2)), isFalse);
      expect(
        reachable.containsKey(const GridPos(5, 5)),
        isFalse,
      ); // start excluded.
    });

    test('walls block movement entirely', () {
      final map = TacticalMap(width: 10, height: 10);
      map.setTile(const GridPos(6, 5), TileType.wall);
      final reachable = Pathfinding.reachableTiles(map, const GridPos(5, 5), 3);
      expect(reachable.containsKey(const GridPos(6, 5)), isFalse);
    });

    test('crates block movement like walls', () {
      final map = TacticalMap(width: 10, height: 10);
      map.setTile(const GridPos(6, 5), TileType.crate);
      final reachable = Pathfinding.reachableTiles(map, const GridPos(5, 5), 3);
      expect(reachable.containsKey(const GridPos(6, 5)), isFalse);
    });

    test('occupied tiles (blocked set) are treated as impassable', () {
      final map = TacticalMap(width: 10, height: 10);
      final reachable = Pathfinding.reachableTiles(
        map,
        const GridPos(5, 5),
        4,
        blocked: {const GridPos(6, 5)},
      );
      expect(reachable.containsKey(const GridPos(6, 5)), isFalse);
      // Should still be able to route around it (detour costs extra steps).
      expect(reachable.containsKey(const GridPos(7, 5)), isTrue);
    });

    test('path returned leads correctly to the destination', () {
      final map = TacticalMap(width: 10, height: 10);
      final reachable = Pathfinding.reachableTiles(map, const GridPos(0, 0), 4);
      final path = reachable[const GridPos(3, 0)]!;
      expect(path.last, const GridPos(3, 0));
      expect(path.length, 3);
    });
  });
}
