import 'dart:math';

import 'package:blackwire_protocol/core/constants.dart';
import 'package:blackwire_protocol/data/content/equipment_catalog.dart';
import 'package:blackwire_protocol/data/models/faction.dart';
import 'package:blackwire_protocol/data/models/soldier.dart';
import 'package:blackwire_protocol/data/models/specialization.dart';
import 'package:blackwire_protocol/game/ai/simple_ai.dart';
import 'package:blackwire_protocol/game/battle_controller.dart';
import 'package:blackwire_protocol/game/battle_factory.dart';
import 'package:blackwire_protocol/game/combat/combat_resolver.dart';
import 'package:blackwire_protocol/game/map/tactical_map.dart';
import 'package:blackwire_protocol/game/map/tile.dart';
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

TacticalUnit _tech({
  required GridPos position,
  List<String> skills = const [GameConfig.hackSkillId],
}) => TacticalUnit(
  id: 'tech',
  team: Team.player,
  displayName: 'Wire',
  maxHp: 100,
  position: position,
  movementRange: 5,
  baseAccuracy: 65,
  weapon: kWeaponCatalog['pistol_mk1']!,
  skillIds: skills,
);

TacticalUnit _droid({required String id, required GridPos position}) =>
    TacticalUnit(
      id: id,
      team: Team.enemy,
      displayName: id,
      maxHp: 50,
      position: position,
      movementRange: 4,
      baseAccuracy: 54,
      weapon: kWeaponCatalog['pistol_mk1']!,
      enemyFactionId: EnemyFactionId.nexusRobotics,
    );

TacticalUnit _mutant({required GridPos position, int hp = 45}) => TacticalUnit(
  id: 'mutant',
  team: Team.enemy,
  displayName: 'Мутант-биоформ #1',
  maxHp: hp,
  currentHp: hp,
  position: position,
  movementRange: 0,
  baseAccuracy: 10,
  weapon: kWeaponCatalog['pistol_mk1']!,
  enemyFactionId: EnemyFactionId.chimeraLabs,
);

BattleController _controller(List<TacticalUnit> units) {
  final rng = _ZeroRandom();
  final resolver = CombatResolver(random: rng);
  return BattleController(
    map: TacticalMap(width: 12, height: 8),
    units: units,
    combatResolver: resolver,
    ai: SimpleAi(random: rng, combatResolver: resolver),
    random: rng,
  );
}

void main() {
  group('Technician hack', () {
    test('converts a visible Nexus droid to the player team', () {
      final tech = _tech(position: const GridPos(2, 3));
      final droid = _droid(id: 'droid', position: const GridPos(5, 3));
      final controller = _controller([tech, droid]);
      controller.selectUnit(tech.id);

      expect(controller.hackableTargetsForSelected(), [droid]);
      expect(controller.hackTarget(droid.id), isTrue);

      expect(droid.team, Team.player);
      expect(droid.isHacked, isTrue);
      expect(tech.hasUsedHack, isTrue);
      expect(tech.hasActed, isTrue);
      expect(controller.phase, BattlePhase.victory);
      expect(
        controller.log.map((e) => e.text).join('\n'),
        contains('взламывает'),
      );
    });

    test(
      'cannot hack Chimera mutants or a second droid in the same battle',
      () {
        final tech = _tech(position: const GridPos(2, 3));
        final droid = _droid(id: 'droid', position: const GridPos(4, 3));
        final mutant = _mutant(position: const GridPos(5, 4));
        final second = _droid(id: 'droid2', position: const GridPos(6, 3));
        final controller = _controller([tech, droid, mutant, second]);
        controller.selectUnit(tech.id);

        expect(
          controller.hackableTargetsForSelected().map((u) => u.id),
          isNot(contains(mutant.id)),
        );
        expect(controller.hackTarget(mutant.id), isFalse);
        expect(mutant.team, Team.enemy);

        expect(controller.hackTarget(droid.id), isTrue);
        expect(controller.phase, BattlePhase.playerTurn);
        expect(controller.hackTarget(second.id), isFalse);
        expect(second.team, Team.enemy);
      },
    );

    test('does nothing without the hack signature skill', () {
      final tech = _tech(position: const GridPos(2, 3), skills: const []);
      final droid = _droid(id: 'droid', position: const GridPos(4, 3));
      final controller = _controller([tech, droid]);
      controller.selectUnit(tech.id);

      expect(controller.hackableTargetsForSelected(), isEmpty);
      expect(controller.hackTarget(droid.id), isFalse);
      expect(droid.team, Team.enemy);
    });
  });

  group('Technician turret', () {
    test('deploys once on an adjacent tile and auto-fires at end of turn', () {
      final tech = _tech(
        position: const GridPos(2, 3),
        skills: const [GameConfig.turretSkillId],
      );
      final tank = _mutant(position: const GridPos(8, 3), hp: 80);
      final controller = _controller([tech, tank]);
      controller.selectUnit(tech.id);

      const deployAt = GridPos(3, 3);
      expect(controller.deployTilesForSelected(), contains(deployAt));
      expect(controller.deployTurretAt(deployAt), isTrue);
      expect(tech.hasDeployedTurret, isTrue);
      expect(tech.hasActed, isTrue);

      final turret = controller.units.singleWhere((u) => u.isTurret);
      expect(turret.position, deployAt);
      expect(turret.team, Team.player);
      expect(controller.deployTurretAt(const GridPos(2, 4)), isFalse);

      controller.endPlayerTurn();

      expect(
        controller.log.any((e) => e.text.contains('Турель Wire поражает')),
        isTrue,
      );
      expect(tank.currentHp, lessThan(80));
      expect(controller.phase, BattlePhase.playerTurn);
      expect(turret.hasMoved, isTrue);
      expect(turret.hasActed, isTrue);
    });
  });

  test('BattleFactory copies technician skill ids onto the tactical unit', () {
    final soldier = const Soldier(id: 's-tech', name: 'Wire').copyWith(
      specialization: Specialization.technician,
      unlockedSkillIds: const [
        GameConfig.hackSkillId,
        GameConfig.turretSkillId,
      ],
    );
    final battle = BattleFactory.createMission(
      squad: [soldier],
      factionId: EnemyFactionId.nexusRobotics,
      difficulty: 1,
    );
    final unit = battle.units.firstWhere((u) => u.team == Team.player);
    expect(unit.skillIds, contains(GameConfig.hackSkillId));
    expect(unit.canHack, isTrue);
    expect(unit.canDeployTurret, isTrue);
  });
}
