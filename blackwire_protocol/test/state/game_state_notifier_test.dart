import 'dart:math';

import 'package:blackwire_protocol/data/content/equipment_catalog.dart';
import 'package:blackwire_protocol/data/models/faction.dart';
import 'package:blackwire_protocol/data/models/mission_site.dart';
import 'package:blackwire_protocol/data/models/soldier.dart';
import 'package:blackwire_protocol/game/battle_controller.dart';
import 'package:blackwire_protocol/game/combat/combat_resolver.dart';
import 'package:blackwire_protocol/game/map/tactical_map.dart';
import 'package:blackwire_protocol/game/map/tile.dart';
import 'package:blackwire_protocol/game/units/tactical_unit.dart';
import 'package:blackwire_protocol/state/game_state_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Always-hit RNG so tests can deterministically force combat outcomes.
class _AlwaysZeroRandom implements Random {
  @override
  int nextInt(int max) => 0;
  @override
  double nextDouble() => 0;
  @override
  bool nextBool() => false;
}

MissionSite _mission({
  int difficulty = 2,
  EnemyFactionId faction = EnemyFactionId.nexusRobotics,
}) => MissionSite(
  id: 'test_mission',
  factionId: faction,
  type: MissionType.raid,
  regionName: 'Test Sector',
  x: 0.5,
  y: 0.5,
  difficulty: difficulty,
  secondsRemaining: 100,
  totalLifetimeSeconds: 100,
);

void main() {
  group('GameStateNotifier.resolveMission', () {
    late ProviderContainer container;
    late GameStateNotifier notifier;

    setUp(() async {
      container = ProviderContainer();
      notifier = container.read(gameStateProvider.notifier);
      await notifier.startNewGame();
      notifier.paused = true; // freeze the geoscape ticker during assertions.
    });

    tearDown(() => container.dispose());

    test(
      'victory heals survivors, wounds low-hp units, kills dead ones, and grants loot',
      () {
        final soldiers = container.read(gameStateProvider).soldiers;
        expect(soldiers.length, 4);

        final survivor = soldiers[0];
        final wounded = soldiers[1];
        final dead = soldiers[2];
        final untouched = soldiers[3];

        final mission = _mission(difficulty: 2);
        notifier.loadSave(
          container.read(gameStateProvider).copyWith(activeMissions: [mission]),
        );

        final map = TacticalMap(width: 6, height: 6);
        final units = [
          TacticalUnit(
            id: 'p_survivor',
            team: Team.player,
            displayName: survivor.name,
            maxHp: 100,
            position: const GridPos(1, 1),
            movementRange: 5,
            baseAccuracy: 90,
            weapon: kWeaponCatalog['rifle_mk1']!,
            soldierId: survivor.id,
            currentHp: 90, // >= 50% -> should fully heal.
          ),
          TacticalUnit(
            id: 'p_wounded',
            team: Team.player,
            displayName: wounded.name,
            maxHp: 100,
            position: const GridPos(1, 2),
            movementRange: 5,
            baseAccuracy: 90,
            weapon: kWeaponCatalog['rifle_mk1']!,
            soldierId: wounded.id,
            currentHp: 30, // < 50% -> should become wounded.
          ),
          TacticalUnit(
            id: 'p_dead',
            team: Team.player,
            displayName: dead.name,
            maxHp: 100,
            position: const GridPos(1, 3),
            movementRange: 5,
            baseAccuracy: 90,
            weapon: kWeaponCatalog['rifle_mk1']!,
            soldierId: dead.id,
            currentHp: 0, // dead -> permadeath, removed from roster.
          ),
          TacticalUnit(
            id: 'e_target',
            team: Team.enemy,
            displayName: 'Test Drone',
            maxHp: 1,
            position: const GridPos(2, 1),
            movementRange: 4,
            baseAccuracy: 10,
            weapon: kWeaponCatalog['pistol_mk1']!,
          ),
        ];

        final battle = BattleController(
          map: map,
          units: units,
          combatResolver: CombatResolver(random: _AlwaysZeroRandom()),
        );
        battle.selectUnit('p_survivor');
        final result = battle.attackTarget('e_target');
        expect(result!.hit, isTrue);
        expect(battle.phase, BattlePhase.victory);

        final missionResult = notifier.resolveMission(
          mission: mission,
          battle: battle,
          squadSoldierIds: [survivor.id, wounded.id, dead.id],
        );

        expect(missionResult.victory, isTrue);
        expect(missionResult.loot.credits, greaterThan(0));
        expect(missionResult.killedInAction, contains(dead.name));
        expect(missionResult.wounded, contains(wounded.name));

        final save = container.read(gameStateProvider);

        // Dead soldier permanently removed from the roster.
        expect(save.soldiers.any((s) => s.id == dead.id), isFalse);

        // Survivor fully healed and credited with a mission.
        final survivorAfter = save.soldiers.firstWhere(
          (s) => s.id == survivor.id,
        );
        expect(survivorAfter.status, SoldierStatus.active);
        expect(survivorAfter.currentHp, survivorAfter.maxHp);
        expect(survivorAfter.missionsSurvived, 1);

        // Wounded soldier flagged with a recovery timer.
        final woundedAfter = save.soldiers.firstWhere(
          (s) => s.id == wounded.id,
        );
        expect(woundedAfter.status, SoldierStatus.wounded);
        expect(woundedAfter.recoveryDaysLeft, greaterThan(0));
        expect(woundedAfter.currentHp, 30);

        // Untouched soldier (not part of the squad) is unaffected.
        final untouchedAfter = save.soldiers.firstWhere(
          (s) => s.id == untouched.id,
        );
        expect(untouchedAfter.status, SoldierStatus.active);
        expect(untouchedAfter.missionsSurvived, 0);

        // Loot applied to resources.
        expect(save.resources.credits, greaterThan(500));

        // Faction threat for the targeted faction decreased; mission removed.
        final threat = save.factionThreats.firstWhere(
          (f) => f.factionId == mission.factionId,
        );
        expect(threat.threatLevel, lessThan(10));
        expect(save.activeMissions.any((m) => m.id == mission.id), isFalse);
      },
    );

    test('defeat grants no loot and raises faction threat & chaos', () {
      final soldiers = container.read(gameStateProvider).soldiers;
      final squad = soldiers.take(2).toList();
      final mission = _mission(
        difficulty: 3,
        faction: EnemyFactionId.titanDynamics,
      );
      notifier.loadSave(
        container.read(gameStateProvider).copyWith(activeMissions: [mission]),
      );
      final chaosBefore = container.read(gameStateProvider).chaosLevel;

      final map = TacticalMap(width: 6, height: 6);
      final units = [
        TacticalUnit(
          id: 'p1',
          team: Team.player,
          displayName: squad[0].name,
          maxHp: 100,
          position: const GridPos(1, 1),
          movementRange: 5,
          baseAccuracy: 10,
          weapon: kWeaponCatalog['pistol_mk1']!,
          soldierId: squad[0].id,
          currentHp: 0,
        ),
        TacticalUnit(
          id: 'p2',
          team: Team.player,
          displayName: squad[1].name,
          maxHp: 100,
          position: const GridPos(1, 2),
          movementRange: 5,
          baseAccuracy: 10,
          weapon: kWeaponCatalog['pistol_mk1']!,
          soldierId: squad[1].id,
          currentHp: 0,
        ),
        TacticalUnit(
          id: 'e1',
          team: Team.enemy,
          displayName: 'Test Merc',
          maxHp: 100,
          position: const GridPos(2, 1),
          movementRange: 4,
          baseAccuracy: 90,
          weapon: kWeaponCatalog['rifle_mk1']!,
        ),
      ];
      final battle = BattleController(map: map, units: units);
      // Force the defeat check: both player units already have 0 HP (dead).
      battle.endPlayerTurn();
      expect(battle.phase, BattlePhase.defeat);

      final missionResult = notifier.resolveMission(
        mission: mission,
        battle: battle,
        squadSoldierIds: [squad[0].id, squad[1].id],
      );

      expect(missionResult.victory, isFalse);
      expect(missionResult.loot.credits, 0);
      expect(missionResult.killedInAction.length, 2);

      final save = container.read(gameStateProvider);
      final threat = save.factionThreats.firstWhere(
        (f) => f.factionId == mission.factionId,
      );
      expect(threat.threatLevel, greaterThan(10));
      expect(save.chaosLevel, greaterThan(chaosBefore));
      expect(save.soldiers.any((s) => s.id == squad[0].id), isFalse);
      expect(save.soldiers.any((s) => s.id == squad[1].id), isFalse);
    });
  });

  group('GameStateNotifier facilities & research', () {
    test('upgradeFacility deducts resources and increases level', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(gameStateProvider.notifier);
      notifier.loadSave(
        container
            .read(gameStateProvider)
            .copyWith(
              resources: container
                  .read(gameStateProvider)
                  .resources
                  .copyWith(credits: 10000, materials: 1000),
            ),
      );

      final before = container.read(gameStateProvider).base.warehouseLevel;
      final ok = notifier.upgradeFacility('warehouse');
      expect(ok, isTrue);
      expect(container.read(gameStateProvider).base.warehouseLevel, before + 1);
      expect(
        container.read(gameStateProvider).resources.credits,
        lessThan(10000),
      );
    });

    test('completeResearch respects prerequisites and cost', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(gameStateProvider.notifier);
      notifier.loadSave(
        container
            .read(gameStateProvider)
            .copyWith(
              resources: container
                  .read(gameStateProvider)
                  .resources
                  .copyWith(data: 1000),
            ),
      );

      // res_smg_arc requires res_rifle_mk1 first.
      expect(notifier.canResearch('res_smg_arc'), isFalse);
      expect(notifier.completeResearch('res_rifle_mk1'), isTrue);
      expect(notifier.canResearch('res_smg_arc'), isTrue);
      expect(notifier.completeResearch('res_smg_arc'), isTrue);
      expect(
        container.read(gameStateProvider).unlockedWeaponIds,
        containsAll(['rifle_mk1', 'smg_arc']),
      );
    });
  });
}
