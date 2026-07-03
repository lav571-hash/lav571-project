import 'dart:math';

import 'package:blackwire_protocol/data/content/equipment_catalog.dart';
import 'package:blackwire_protocol/game/combat/combat_resolver.dart';
import 'package:blackwire_protocol/game/map/tactical_map.dart';
import 'package:blackwire_protocol/game/map/tile.dart';
import 'package:blackwire_protocol/game/units/tactical_unit.dart';
import 'package:flutter_test/flutter_test.dart';

/// A Random implementation that always returns 0, guaranteeing a hit and
/// minimum-roll damage for deterministic tests.
class _AlwaysZeroRandom implements Random {
  @override
  int nextInt(int max) => 0;

  @override
  double nextDouble() => 0;

  @override
  bool nextBool() => false;
}

void main() {
  group('CombatResolver.coverLevelFor', () {
    test('no cover when tile between shooter and target is floor', () {
      final map = TacticalMap(width: 10, height: 10);
      final cover = CombatResolver.coverLevelFor(
        map,
        const GridPos(5, 5),
        const GridPos(8, 5),
      );
      expect(cover, CoverLevel.none);
    });

    test('wall adjacent to target on shooter side grants full cover', () {
      final map = TacticalMap(width: 10, height: 10);
      map.setTile(const GridPos(6, 5), TileType.wall);
      final cover = CombatResolver.coverLevelFor(
        map,
        const GridPos(5, 5),
        const GridPos(8, 5),
      );
      expect(cover, CoverLevel.full);
    });

    test('crate adjacent to target on shooter side grants half cover', () {
      final map = TacticalMap(width: 10, height: 10);
      map.setTile(const GridPos(6, 5), TileType.crate);
      final cover = CombatResolver.coverLevelFor(
        map,
        const GridPos(5, 5),
        const GridPos(8, 5),
      );
      expect(cover, CoverLevel.half);
    });
  });

  group('CombatResolver.canAttack', () {
    test('true within weapon range with clear line of sight', () {
      final map = TacticalMap(width: 10, height: 10);
      final resolver = CombatResolver();
      final shooter = TacticalUnit(
        id: 'shooter',
        team: Team.player,
        displayName: 'Shooter',
        maxHp: 100,
        position: const GridPos(1, 1),
        movementRange: 5,
        baseAccuracy: 90,
        weapon: kWeaponCatalog['rifle_mk1']!,
      );
      final target = TacticalUnit(
        id: 'target',
        team: Team.enemy,
        displayName: 'Target',
        maxHp: 100,
        position: const GridPos(2, 1),
        movementRange: 5,
        baseAccuracy: 50,
        weapon: kWeaponCatalog['pistol_mk1']!,
      );
      expect(resolver.canAttack(map, shooter, target), isTrue);
    });

    test('false beyond weapon range', () {
      final map = TacticalMap(width: 20, height: 20);
      final resolver = CombatResolver();
      final shooter = TacticalUnit(
        id: 'shooter',
        team: Team.player,
        displayName: 'Shooter',
        maxHp: 100,
        position: const GridPos(0, 0),
        movementRange: 5,
        baseAccuracy: 90,
        weapon: kWeaponCatalog['pistol_mk1']!, // range: 6
      );
      final target = TacticalUnit(
        id: 'target',
        team: Team.enemy,
        displayName: 'Target',
        maxHp: 100,
        position: const GridPos(15, 0),
        movementRange: 5,
        baseAccuracy: 50,
        weapon: kWeaponCatalog['pistol_mk1']!,
      );
      expect(resolver.canAttack(map, shooter, target), isFalse);
    });
  });

  group('CombatResolver.resolveAttack', () {
    test(
      'a guaranteed hit (seeded RNG roll=0) deals damage in weapon range',
      () {
        final map = TacticalMap(width: 10, height: 10);
        final resolver = CombatResolver(random: _AlwaysZeroRandom());
        final shooter = TacticalUnit(
          id: 'shooter',
          team: Team.player,
          displayName: 'Shooter',
          maxHp: 100,
          position: const GridPos(1, 1),
          movementRange: 5,
          baseAccuracy: 90,
          weapon: kWeaponCatalog['rifle_mk1']!,
        );
        final target = TacticalUnit(
          id: 'target',
          team: Team.enemy,
          displayName: 'Target',
          maxHp: 100,
          position: const GridPos(2, 1),
          movementRange: 5,
          baseAccuracy: 50,
          weapon: kWeaponCatalog['pistol_mk1']!,
        );

        final result = resolver.resolveAttack(map, shooter, target);
        expect(result.hit, isTrue);
        expect(result.damage, greaterThan(0));
        expect(target.currentHp, lessThan(100));
      },
    );

    test('damage reduction lowers effective damage but never below 1', () {
      final map = TacticalMap(width: 10, height: 10);
      final resolver = CombatResolver(random: _AlwaysZeroRandom());
      final shooter = TacticalUnit(
        id: 'shooter',
        team: Team.player,
        displayName: 'Shooter',
        maxHp: 100,
        position: const GridPos(1, 1),
        movementRange: 5,
        baseAccuracy: 90,
        weapon: kWeaponCatalog['pistol_mk1']!,
      );
      final target = TacticalUnit(
        id: 'target',
        team: Team.enemy,
        displayName: 'Target',
        maxHp: 100,
        position: const GridPos(2, 1),
        movementRange: 5,
        baseAccuracy: 50,
        weapon: kWeaponCatalog['pistol_mk1']!,
        damageReduction: 999,
      );

      final result = resolver.resolveAttack(map, shooter, target);
      expect(result.hit, isTrue);
      expect(target.currentHp, 99); // 100 - 1 (minimum guaranteed damage).
    });
  });
}
