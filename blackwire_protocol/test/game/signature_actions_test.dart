import 'dart:math';

import 'package:blackwire_protocol/core/constants.dart';
import 'package:blackwire_protocol/data/content/equipment_catalog.dart';
import 'package:blackwire_protocol/data/models/faction.dart';
import 'package:blackwire_protocol/game/ai/simple_ai.dart';
import 'package:blackwire_protocol/game/battle_controller.dart';
import 'package:blackwire_protocol/game/combat/combat_resolver.dart';
import 'package:blackwire_protocol/game/map/tactical_map.dart';
import 'package:blackwire_protocol/game/map/tile.dart';
import 'package:blackwire_protocol/game/units/tactical_unit.dart';
import 'package:flutter_test/flutter_test.dart';

/// Always rolls 0: attacks always hit, damage is the weapon minimum and the
/// AI never takes its random branches.
class _ZeroRandom implements Random {
  @override
  bool nextBool() => false;
  @override
  double nextDouble() => 0;
  @override
  int nextInt(int max) => 0;
}

/// Always rolls the maximum: attacks always miss.
class _MaxRandom implements Random {
  @override
  bool nextBool() => false;
  @override
  double nextDouble() => 0.999;
  @override
  int nextInt(int max) => max - 1;
}

TacticalUnit _soldier({
  required String id,
  required GridPos position,
  required List<String> skills,
  int hp = 100,
  int maxHp = 100,
}) => TacticalUnit(
  id: id,
  team: Team.player,
  displayName: id,
  maxHp: maxHp,
  currentHp: hp,
  position: position,
  movementRange: 5,
  baseAccuracy: 65,
  weapon: kWeaponCatalog['rifle_mk1']!,
  skillIds: skills,
);

TacticalUnit _enemy({
  required GridPos position,
  int hp = 80,
  int movement = 5,
  int accuracy = 54,
}) => TacticalUnit(
  id: 'enemy',
  team: Team.enemy,
  displayName: 'PMC-оперативник #1',
  maxHp: hp,
  currentHp: hp,
  position: position,
  movementRange: movement,
  baseAccuracy: accuracy,
  weapon: kWeaponCatalog['rifle_mk1']!,
  enemyFactionId: EnemyFactionId.titanDynamics,
);

BattleController _controller(
  List<TacticalUnit> units, {
  Random? random,
  TacticalMap? map,
}) {
  final rng = random ?? _ZeroRandom();
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
  group('Assault overrun', () {
    test('ignores the target cover and adds damage at point blank', () {
      final map = TacticalMap(width: 14, height: 9);
      // Crate directly between assault and target grants the enemy cover.
      map.setTile(const GridPos(4, 4), TileType.crate);
      final assault = _soldier(
        id: 'assault',
        position: const GridPos(3, 4),
        skills: const [GameConfig.overrunSkillId],
      );
      final target = _enemy(position: const GridPos(5, 4));
      final controller = _controller([assault, target], map: map);
      controller.selectUnit(assault.id);

      expect(controller.overrunTargetsForSelected(), [target]);
      final covered = CombatResolver.coverLevelFor(
        map,
        target.position,
        assault.position,
      );
      expect(covered, isNot(CoverLevel.none));

      final result = controller.overrunTarget(target.id);

      expect(result, isNotNull);
      expect(result!.cover, CoverLevel.none);
      expect(
        result.damage,
        assault.weapon.minDamage + GameConfig.overrunDamageBonus,
      );
      expect(assault.hasActed, isTrue);
      expect(controller.overrunTargetsForSelected(), isEmpty);
      expect(
        controller.log.any((e) => e.text.contains('идёт в натиск')),
        isTrue,
      );
    });

    test('is out of reach beyond point-blank range', () {
      final assault = _soldier(
        id: 'assault',
        position: const GridPos(2, 4),
        skills: const [GameConfig.overrunSkillId],
      );
      final target = _enemy(position: const GridPos(7, 4));
      final controller = _controller([assault, target]);
      controller.selectUnit(assault.id);

      expect(controller.overrunTargetsForSelected(), isEmpty);
      expect(controller.overrunTarget(target.id), isNull);
      expect(assault.canOverrun, isTrue);
    });
  });

  group('Sniper aimed shot', () {
    test('boosts accuracy and damage while the sniper holds position', () {
      final sniper = _soldier(
        id: 'sniper',
        position: const GridPos(2, 4),
        skills: const [GameConfig.aimedShotSkillId],
      );
      final target = _enemy(position: const GridPos(8, 4));
      final controller = _controller([sniper, target]);
      controller.selectUnit(sniper.id);

      final plainChance = controller.combatResolver.computeHitChance(
        controller.map,
        sniper,
        target,
      );
      final result = controller.aimedShotTarget(target.id);

      expect(result, isNotNull);
      expect(result!.hitChance, greaterThan(plainChance));
      expect(
        result.damage,
        sniper.weapon.minDamage + GameConfig.aimedShotDamageBonus,
      );
      expect(sniper.hasActed, isTrue);
      expect(sniper.canAimedShot, isFalse);
    });

    test('is unavailable once the sniper has moved this turn', () {
      final sniper = _soldier(
        id: 'sniper',
        position: const GridPos(2, 4),
        skills: const [GameConfig.aimedShotSkillId],
      );
      final target = _enemy(position: const GridPos(8, 4));
      final controller = _controller([sniper, target]);
      controller.selectUnit(sniper.id);

      expect(controller.moveSelectedTo(const GridPos(3, 4)), isTrue);

      expect(sniper.canAimedShot, isFalse);
      expect(controller.aimedShotTargetsForSelected(), isEmpty);
      expect(controller.aimedShotTarget(target.id), isNull);
    });
  });

  group('Heavy suppression', () {
    test('pins the enemy for one turn, after which it advances again', () {
      final heavy = _soldier(
        id: 'heavy',
        position: const GridPos(3, 4),
        skills: const [GameConfig.suppressSkillId],
      );
      // Short-ranged enemy that has to close the distance to shoot back.
      final target = TacticalUnit(
        id: 'enemy',
        team: Team.enemy,
        displayName: 'PMC-оперативник #1',
        maxHp: 80,
        position: const GridPos(9, 4),
        movementRange: 4,
        baseAccuracy: 54,
        weapon: kWeaponCatalog['smg_arc']!,
        enemyFactionId: EnemyFactionId.titanDynamics,
      );
      final controller = _controller([heavy, target]);
      controller.selectUnit(heavy.id);

      expect(controller.suppressTargetsForSelected(), [target]);
      expect(controller.suppressTarget(target.id), isTrue);
      expect(target.isSuppressed, isTrue);
      expect(heavy.hasActed, isTrue);

      const pinnedAt = GridPos(9, 4);
      controller.endPlayerTurn();

      expect(target.position, pinnedAt);
      expect(
        controller.log.any((e) => e.text.contains('перемещается')),
        isFalse,
      );

      // Suppression lasts a single enemy turn.
      expect(target.isSuppressed, isFalse);
      controller.endPlayerTurn();
      expect(target.position, isNot(pinnedAt));
    });

    test('suppressed enemies shoot at a reduced hit chance', () {
      final map = TacticalMap(width: 14, height: 9);
      final rng = _MaxRandom();
      final ai = SimpleAi(random: rng, combatResolver: CombatResolver(random: rng));

      AttackResult shoot({required bool suppressed}) {
        final soldier = _soldier(
          id: 'target',
          position: const GridPos(3, 4),
          skills: const [],
        );
        final shooter = _enemy(position: const GridPos(6, 4));
        if (suppressed) shooter.suppressedTurns = GameConfig.suppressTurns;
        final result = ai.takeTurn(map, shooter, [soldier, shooter]);
        return result.attackResult!;
      }

      final free = shoot(suppressed: false);
      final pinned = shoot(suppressed: true);

      expect(
        pinned.hitChance,
        free.hitChance - GameConfig.suppressAccuracyPenalty,
      );
    });
  });

  group('Medic field heal', () {
    test('heals an adjacent wounded ally', () {
      final medic = _soldier(
        id: 'medic',
        position: const GridPos(3, 4),
        skills: const [GameConfig.fieldHealSkillId],
      );
      final wounded = _soldier(
        id: 'wounded',
        position: const GridPos(4, 4),
        skills: const [],
        hp: 30,
      );
      final controller = _controller([
        medic,
        wounded,
        _enemy(position: const GridPos(11, 4)),
      ]);
      controller.selectUnit(medic.id);

      expect(controller.healTargetsForSelected(), [wounded]);
      expect(controller.fieldHealTarget(wounded.id), isTrue);

      expect(wounded.currentHp, 30 + GameConfig.fieldHealAmount);
      expect(medic.hasActed, isTrue);
      expect(medic.canFieldHeal, isFalse);
      expect(controller.log.last.text, contains('оказывает помощь'));
    });

    test('never overheals and skips full-HP or distant allies', () {
      final medic = _soldier(
        id: 'medic',
        position: const GridPos(3, 4),
        skills: const [GameConfig.fieldHealSkillId],
      );
      final healthy = _soldier(
        id: 'healthy',
        position: const GridPos(4, 4),
        skills: const [],
      );
      final farAway = _soldier(
        id: 'farAway',
        position: const GridPos(9, 4),
        skills: const [],
        hp: 20,
      );
      final nearlyFull = _soldier(
        id: 'nearlyFull',
        position: const GridPos(3, 5),
        skills: const [],
        hp: 95,
      );
      final controller = _controller([
        medic,
        healthy,
        farAway,
        nearlyFull,
        _enemy(position: const GridPos(12, 8)),
      ]);
      controller.selectUnit(medic.id);

      expect(
        controller.healTargetsForSelected().map((u) => u.id),
        ['nearlyFull'],
      );
      expect(controller.fieldHealTarget(nearlyFull.id), isTrue);
      expect(nearlyFull.currentHp, nearlyFull.maxHp);
      expect(controller.log.last.text, contains('+5 HP'));
    });

    test('rallies a panicked ally so they can move again', () {
      final medic = _soldier(
        id: 'medic',
        position: const GridPos(3, 4),
        skills: const [GameConfig.fieldHealSkillId],
      );
      final panicked = _soldier(
        id: 'panicked',
        position: const GridPos(4, 4),
        skills: const [],
      );
      panicked.isPanicked = true;
      panicked.hasMoved = true;
      panicked.hasActed = true;

      final controller = _controller([
        medic,
        panicked,
        _enemy(position: const GridPos(12, 8)),
      ]);
      controller.selectUnit(medic.id);

      // A panicked ally is a valid target even at full health.
      expect(controller.healTargetsForSelected(), [panicked]);
      expect(controller.fieldHealTarget(panicked.id), isTrue);

      expect(panicked.isPanicked, isFalse);
      expect(panicked.hasMoved, isFalse);
      // Rallying restores movement only; the panic already cost the action.
      expect(panicked.hasActed, isTrue);
      expect(
        controller.log.any((e) => e.text.contains('приводит')),
        isTrue,
      );
    });
  });

  test('each signature action can only be spent once per battle', () {
    final soldier = _soldier(
      id: 'veteran',
      position: const GridPos(3, 4),
      skills: const [
        GameConfig.overrunSkillId,
        GameConfig.suppressSkillId,
      ],
    );
    final target = _enemy(position: const GridPos(4, 4), hp: 200);
    final controller = _controller([soldier, target]);
    controller.selectUnit(soldier.id);

    expect(controller.overrunTarget(target.id), isNotNull);
    // Freeing the action flag proves the limit comes from the spent skill.
    soldier.hasActed = false;
    expect(controller.overrunTarget(target.id), isNull);
    expect(soldier.canOverrun, isFalse);
    expect(soldier.canSuppress, isTrue);
  });
}
