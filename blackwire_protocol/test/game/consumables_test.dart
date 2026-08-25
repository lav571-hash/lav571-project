import 'dart:math';

import 'package:blackwire_protocol/core/constants.dart';
import 'package:blackwire_protocol/data/content/equipment_catalog.dart';
import 'package:blackwire_protocol/data/models/faction.dart';
import 'package:blackwire_protocol/data/models/soldier.dart';
import 'package:blackwire_protocol/game/ai/simple_ai.dart';
import 'package:blackwire_protocol/game/battle_controller.dart';
import 'package:blackwire_protocol/game/battle_factory.dart';
import 'package:blackwire_protocol/game/combat/combat_resolver.dart';
import 'package:blackwire_protocol/game/map/tactical_map.dart';
import 'package:blackwire_protocol/game/map/tile.dart';
import 'package:blackwire_protocol/game/units/tactical_unit.dart';
import 'package:flutter_test/flutter_test.dart';

/// Always rolls 0, so grenade damage is exactly [GameConfig.grenadeMinDamage]
/// and the AI never takes its random branches.
class _ZeroRandom implements Random {
  @override
  bool nextBool() => false;
  @override
  double nextDouble() => 0;
  @override
  int nextInt(int max) => 0;
}

TacticalUnit _soldier({
  required String id,
  required GridPos position,
  List<String> consumables = const [],
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
  weapon: kWeaponCatalog['rifle_mk1']!,
  consumableIds: consumables,
);

TacticalUnit _enemy({required String id, required GridPos position}) =>
    TacticalUnit(
      id: id,
      team: Team.enemy,
      displayName: id,
      maxHp: 80,
      currentHp: 80,
      position: position,
      movementRange: 0,
      baseAccuracy: 10,
      weapon: kWeaponCatalog['pistol_mk1']!,
      enemyFactionId: EnemyFactionId.titanDynamics,
    );

BattleController _controller(List<TacticalUnit> units, {TacticalMap? map}) {
  final rng = _ZeroRandom();
  final resolver = CombatResolver(random: rng);
  return BattleController(
    map: map ?? TacticalMap(width: 14, height: 9),
    units: units,
    combatResolver: resolver,
    ai: SimpleAi(random: rng, combatResolver: resolver),
    random: rng,
  );
}

void main() {
  group('Frag grenade', () {
    test('damages every unit in the blast, cover included', () {
      final map = TacticalMap(width: 14, height: 9);
      // The crate would normally give the near enemy cover from the thrower.
      map.setTile(const GridPos(5, 4), TileType.crate);
      final thrower = _soldier(
        id: 'thrower',
        position: const GridPos(3, 4),
        consumables: const [GameConfig.fragGrenadeId],
      );
      final centreEnemy = _enemy(id: 'centre', position: const GridPos(6, 4));
      final splashedEnemy = _enemy(id: 'splashed', position: const GridPos(7, 5));
      final farEnemy = _enemy(id: 'far', position: const GridPos(10, 4));
      final controller = _controller([
        thrower,
        centreEnemy,
        splashedEnemy,
        farEnemy,
      ], map: map);
      controller.selectUnit(thrower.id);

      const target = GridPos(6, 4);
      expect(controller.grenadeTilesForSelected(), contains(target));
      expect(controller.throwGrenadeAt(target), isTrue);

      // Centre and the diagonally adjacent unit are hit, the far one is not.
      expect(centreEnemy.currentHp, 80 - GameConfig.grenadeMinDamage);
      expect(splashedEnemy.currentHp, 80 - GameConfig.grenadeMinDamage);
      expect(farEnemy.currentHp, 80);
      expect(thrower.hasActed, isTrue);
      expect(thrower.canThrowGrenade, isFalse);
      expect(
        controller.log.any((e) => e.text.contains('бросает гранату на 6,4')),
        isTrue,
      );
      expect(
        controller.log.where((e) => e.text.startsWith('Взрыв накрывает')).length,
        2,
      );
    });

    test('catches squadmates standing in the blast', () {
      final thrower = _soldier(
        id: 'thrower',
        position: const GridPos(3, 4),
        consumables: const [GameConfig.fragGrenadeId],
      );
      final ally = _soldier(id: 'ally', position: const GridPos(6, 5));
      final target = _enemy(id: 'target', position: const GridPos(6, 4));
      final controller = _controller([thrower, ally, target]);
      controller.selectUnit(thrower.id);

      expect(controller.throwGrenadeAt(const GridPos(6, 4)), isTrue);

      expect(ally.currentHp, 100 - GameConfig.grenadeMinDamage);
      // The thrower is never caught in their own blast.
      expect(thrower.currentHp, 100);
    });

    test('cannot be lobbed past throwing range or without the research', () {
      final withGrenade = _soldier(
        id: 'withGrenade',
        position: const GridPos(2, 4),
        consumables: const [GameConfig.fragGrenadeId],
      );
      final controller = _controller([
        withGrenade,
        _enemy(id: 'enemy', position: const GridPos(12, 4)),
      ]);
      controller.selectUnit(withGrenade.id);

      const tooFar = GridPos(11, 4);
      expect(
        withGrenade.position.chebyshevDistanceTo(tooFar),
        greaterThan(GameConfig.grenadeThrowRange),
      );
      expect(controller.grenadeTilesForSelected(), isNot(contains(tooFar)));
      expect(controller.throwGrenadeAt(tooFar), isFalse);
      expect(withGrenade.hasActed, isFalse);

      final unarmed = _soldier(id: 'unarmed', position: const GridPos(3, 4));
      final other = _controller([
        unarmed,
        _enemy(id: 'enemy', position: const GridPos(6, 4)),
      ]);
      other.selectUnit(unarmed.id);
      expect(unarmed.canThrowGrenade, isFalse);
      expect(other.grenadeTilesForSelected(), isEmpty);
      expect(other.throwGrenadeAt(const GridPos(6, 4)), isFalse);
    });

    test('a lethal blast ends the mission in victory', () {
      final thrower = _soldier(
        id: 'thrower',
        position: const GridPos(3, 4),
        consumables: const [GameConfig.fragGrenadeId],
      );
      final fragile = TacticalUnit(
        id: 'fragile',
        team: Team.enemy,
        displayName: 'fragile',
        maxHp: 10,
        currentHp: 10,
        position: const GridPos(6, 4),
        movementRange: 0,
        baseAccuracy: 10,
        weapon: kWeaponCatalog['pistol_mk1']!,
        enemyFactionId: EnemyFactionId.titanDynamics,
      );
      final controller = _controller([thrower, fragile]);
      controller.selectUnit(thrower.id);

      expect(controller.throwGrenadeAt(const GridPos(6, 4)), isTrue);

      expect(fragile.isAlive, isFalse);
      expect(thrower.kills, 1);
      expect(controller.phase, BattlePhase.victory);
    });
  });

  group('Combat stim', () {
    test('extends movement and accuracy, then wears off', () {
      final soldier = _soldier(
        id: 'runner',
        position: const GridPos(3, 4),
        consumables: const [GameConfig.combatStimId],
      );
      final target = _enemy(id: 'enemy', position: const GridPos(8, 4));
      final controller = _controller([soldier, target]);
      controller.selectUnit(soldier.id);

      final baseTiles = controller.movementOptionsForSelected().length;
      final baseChance = controller.combatResolver.computeHitChance(
        controller.map,
        soldier,
        target,
      );

      expect(controller.useStimOnSelected(), isTrue);

      expect(soldier.isStimmed, isTrue);
      expect(
        soldier.effectiveMovementRange,
        soldier.movementRange + GameConfig.stimMovementBonus,
      );
      // Using the stim costs the action but leaves movement available.
      expect(soldier.hasActed, isTrue);
      expect(soldier.hasMoved, isFalse);
      expect(
        controller.movementOptionsForSelected().length,
        greaterThan(baseTiles),
      );
      expect(
        controller.combatResolver.computeHitChance(
          controller.map,
          soldier,
          target,
        ),
        baseChance + GameConfig.stimAccuracyBonus,
      );

      // The boost covers this turn and the next, then expires.
      controller.endPlayerTurn();
      expect(soldier.isStimmed, isTrue);
      controller.endPlayerTurn();
      expect(soldier.isStimmed, isFalse);
      expect(soldier.effectiveMovementRange, soldier.movementRange);
    });

    test('is a single charge and cannot be stacked', () {
      final soldier = _soldier(
        id: 'runner',
        position: const GridPos(3, 4),
        consumables: const [GameConfig.combatStimId],
      );
      final controller = _controller([
        soldier,
        _enemy(id: 'enemy', position: const GridPos(9, 8)),
      ]);
      controller.selectUnit(soldier.id);

      expect(controller.useStimOnSelected(), isTrue);
      soldier.hasActed = false;
      expect(soldier.canUseStim, isFalse);
      expect(controller.useStimOnSelected(), isFalse);
      expect(soldier.stimTurnsLeft, GameConfig.stimTurns);
    });
  });

  test('BattleFactory hands researched consumables to the squad only', () {
    const soldier = Soldier(id: 's1', name: 'Recruit');
    final battle = BattleFactory.createMission(
      squad: [soldier],
      factionId: EnemyFactionId.titanDynamics,
      difficulty: 1,
      unlockedAbilityIds: const {
        GameConfig.fragGrenadeId,
        GameConfig.combatStimId,
      },
    );

    final unit = battle.units.firstWhere((u) => u.team == Team.player);
    expect(unit.canThrowGrenade, isTrue);
    expect(unit.canUseStim, isTrue);

    for (final enemy in battle.units.where((u) => u.team == Team.enemy)) {
      expect(enemy.canThrowGrenade, isFalse);
      expect(enemy.canUseStim, isFalse);
    }
  });

  test('without the research nobody carries consumables', () {
    const soldier = Soldier(id: 's1', name: 'Recruit');
    final battle = BattleFactory.createMission(
      squad: [soldier],
      factionId: EnemyFactionId.titanDynamics,
      difficulty: 1,
    );

    final unit = battle.units.firstWhere((u) => u.team == Team.player);
    expect(unit.canThrowGrenade, isFalse);
    expect(unit.canUseStim, isFalse);
  });
}
