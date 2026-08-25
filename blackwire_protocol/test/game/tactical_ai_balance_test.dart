import 'dart:math';

import 'package:blackwire_protocol/core/constants.dart';
import 'package:blackwire_protocol/data/content/equipment_catalog.dart';
import 'package:blackwire_protocol/data/models/faction.dart';
import 'package:blackwire_protocol/data/models/soldier.dart';
import 'package:blackwire_protocol/game/ai/simple_ai.dart';
import 'package:blackwire_protocol/game/battle_factory.dart';
import 'package:blackwire_protocol/game/combat/combat_resolver.dart';
import 'package:blackwire_protocol/game/map/tactical_map.dart';
import 'package:blackwire_protocol/game/map/tile.dart';
import 'package:blackwire_protocol/game/units/enemy_defs.dart';
import 'package:blackwire_protocol/game/units/tactical_unit.dart';
import 'package:flutter_test/flutter_test.dart';

class _ZeroRandom implements Random {
  @override
  bool nextBool() => false;
  @override
  double nextDouble() => 0;
  @override
  int nextInt(int max) => 0;
}

TacticalUnit _player({
  required String id,
  required GridPos position,
  int hp = 100,
}) => TacticalUnit(
  id: id,
  team: Team.player,
  displayName: id,
  maxHp: 100,
  currentHp: hp,
  position: position,
  movementRange: 5,
  baseAccuracy: 65,
  weapon: kWeaponCatalog['pistol_mk1']!,
);

TacticalUnit _enemy({
  required GridPos position,
  int hp = 50,
  int movement = 5,
}) => TacticalUnit(
  id: 'enemy',
  team: Team.enemy,
  displayName: 'Enemy',
  maxHp: 50,
  currentHp: hp,
  position: position,
  movementRange: movement,
  baseAccuracy: 58,
  weapon: kWeaponCatalog['pistol_mk1']!,
);

void main() {
  group('Tactical enemy AI', () {
    test('critically wounded enemy retreats behind available cover', () {
      final map = TacticalMap(width: 9, height: 7);
      map.setTile(const GridPos(2, 3), TileType.crate);
      final player = _player(id: 'player', position: const GridPos(7, 3));
      final enemy = _enemy(position: const GridPos(4, 3), hp: 15);
      final startDistance = enemy.position.chebyshevDistanceTo(player.position);
      final ai = SimpleAi(
        random: _ZeroRandom(),
        combatResolver: CombatResolver(random: _ZeroRandom()),
      );

      final result = ai.takeTurn(map, enemy, [player, enemy]);

      expect(result.attackedTarget, isNull);
      expect(result.movePath, isNotEmpty);
      expect(
        enemy.position.chebyshevDistanceTo(player.position),
        greaterThan(startDistance),
      );
      expect(
        CombatResolver.coverLevelFor(map, enemy.position, player.position),
        isNot(CoverLevel.none),
      );
    });

    test('healthy enemy prefers a covered firing position while advancing', () {
      final map = TacticalMap(width: 10, height: 7);
      map.setTile(const GridPos(4, 3), TileType.crate);
      final player = _player(id: 'player', position: const GridPos(1, 3));
      final enemy = _enemy(position: const GridPos(8, 3), movement: 3);
      final ai = SimpleAi(
        random: _ZeroRandom(),
        combatResolver: CombatResolver(random: _ZeroRandom()),
      );

      final result = ai.takeTurn(map, enemy, [player, enemy]);

      expect(result.movePath, isNotEmpty);
      expect(result.attackedTarget, same(player));
      expect(
        CombatResolver.coverLevelFor(map, enemy.position, player.position),
        CoverLevel.half,
      );
    });

    test('enemy in range still focuses the lowest-HP visible target', () {
      final map = TacticalMap(width: 8, height: 8);
      final healthy = _player(id: 'healthy', position: const GridPos(2, 2));
      final wounded = _player(
        id: 'wounded',
        position: const GridPos(2, 4),
        hp: 25,
      );
      final enemy = _enemy(position: const GridPos(5, 3));
      final ai = SimpleAi(
        random: _ZeroRandom(),
        combatResolver: CombatResolver(random: _ZeroRandom()),
      );

      final result = ai.takeTurn(map, enemy, [healthy, wounded, enemy]);

      expect(result.attackedTarget, same(wounded));
    });

    test('detection range matches player vision range', () {
      expect(SimpleAi.detectionRange, GameConfig.baseVisionRange);
    });
  });

  group('Difficulty balance', () {
    test(
      'difficulty scales enemy HP, accuracy and count without HP sponges',
      () {
        const squad = [Soldier(id: 's1', name: 'Alpha')];
        final easy = BattleFactory.createMission(
          squad: squad,
          factionId: EnemyFactionId.titanDynamics,
          difficulty: 1,
          random: Random(10),
        );
        final hard = BattleFactory.createMission(
          squad: squad,
          factionId: EnemyFactionId.titanDynamics,
          difficulty: 5,
          random: Random(10),
        );
        final def = kEnemyDefs[EnemyFactionId.titanDynamics]!;

        expect(easy.enemyUnits, hasLength(2));
        expect(hard.enemyUnits, hasLength(6));
        expect(
          hard.enemyUnits.first.maxHp,
          def.maxHp + 4 * GameConfig.enemyHpPerDifficulty,
        );
        expect(
          hard.enemyUnits.first.baseAccuracy,
          def.baseAccuracy + 4 * GameConfig.enemyAccuracyPerDifficulty,
        );
        expect(GameConfig.enemyFearAttackChance, lessThan(0.25));
      },
    );
  });
}
