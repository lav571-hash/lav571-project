import 'package:blackwire_protocol/game/map/line_of_sight.dart';
import 'package:blackwire_protocol/game/map/tactical_map.dart';
import 'package:blackwire_protocol/game/map/tile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LineOfSight', () {
    test('unobstructed straight line has line of sight', () {
      final map = TacticalMap(width: 10, height: 10);
      final result = LineOfSight.hasLineOfSight(
        map,
        const GridPos(1, 5),
        const GridPos(8, 5),
      );
      expect(result, isTrue);
    });

    test('wall between two points blocks line of sight', () {
      final map = TacticalMap(width: 10, height: 10);
      map.setTile(const GridPos(5, 5), TileType.wall);
      final result = LineOfSight.hasLineOfSight(
        map,
        const GridPos(1, 5),
        const GridPos(8, 5),
      );
      expect(result, isFalse);
    });

    test('crate between two points does not block line of sight', () {
      final map = TacticalMap(width: 10, height: 10);
      map.setTile(const GridPos(5, 5), TileType.crate);
      final result = LineOfSight.hasLineOfSight(
        map,
        const GridPos(1, 5),
        const GridPos(8, 5),
      );
      expect(result, isTrue);
    });

    test('wall exactly at the target tile does not block sight to itself', () {
      final map = TacticalMap(width: 10, height: 10);
      map.setTile(const GridPos(8, 5), TileType.wall);
      final result = LineOfSight.hasLineOfSight(
        map,
        const GridPos(1, 5),
        const GridPos(8, 5),
      );
      expect(result, isTrue);
    });

    test('computeVisibleTiles respects range and walls', () {
      final map = TacticalMap(width: 10, height: 10);
      map.setTile(const GridPos(5, 3), TileType.wall);
      final visible = LineOfSight.computeVisibleTiles(
        map,
        const GridPos(3, 3),
        3,
      );
      expect(visible.contains(const GridPos(3, 3)), isTrue);
      // Tile far beyond range should not be visible.
      expect(visible.contains(const GridPos(9, 3)), isFalse);
    });
  });
}
