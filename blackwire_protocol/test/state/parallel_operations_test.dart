import 'package:blackwire_protocol/data/models/deployed_operation.dart';
import 'package:blackwire_protocol/data/models/faction.dart';
import 'package:blackwire_protocol/data/models/game_save.dart';
import 'package:blackwire_protocol/data/models/mission_site.dart';
import 'package:blackwire_protocol/data/models/soldier.dart';
import 'package:blackwire_protocol/game/auto_operation_resolver.dart';
import 'package:blackwire_protocol/state/game_state_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

MissionSite _mission(String id, {int difficulty = 2}) => MissionSite(
  id: id,
  factionId: EnemyFactionId.titanDynamics,
  type: MissionType.sabotage,
  regionName: 'Sector $id',
  x: 0.4,
  y: 0.6,
  difficulty: difficulty,
  secondsRemaining: 100,
  totalLifetimeSeconds: 100,
);

void main() {
  test(
    'parallel operation fields round-trip and legacy saves default empty',
    () {
      final mission = _mission('one');
      final operation = DeployedOperation(
        id: 'op_one',
        mission: mission,
        soldierIds: const ['s1'],
        secondsRemaining: 20,
        totalDurationSeconds: 50,
        randomSeed: 42,
      );
      final save = GameSave.newGame().copyWith(deployedOperations: [operation]);

      final restored = GameSave.fromJson(save.toJson());
      expect(restored.deployedOperations.single.id, operation.id);
      expect(restored.deployedOperations.single.randomSeed, 42);

      final legacyJson = GameSave.newGame().toJson()
        ..remove('deployedOperations')
        ..remove('operationReports');
      final legacy = GameSave.fromJson(legacyJson);
      expect(legacy.deployedOperations, isEmpty);
      expect(legacy.operationReports, isEmpty);
    },
  );

  test('hangar capacity and deployed soldier availability are enforced', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(gameStateProvider.notifier);
    final firstMission = _mission('one');
    final secondMission = _mission('two');
    const alpha = Soldier(id: 's1', name: 'Alpha');
    const bravo = Soldier(id: 's2', name: 'Bravo');
    notifier.loadSave(
      container
          .read(gameStateProvider)
          .copyWith(
            soldiers: const [alpha, bravo],
            activeMissions: [firstMission, secondMission],
          ),
    );

    expect(notifier.deployMission(firstMission, [alpha.id]), isTrue);
    expect(notifier.inProgressMissionCount, 1);
    expect(notifier.isSoldierAvailable(alpha), isFalse);
    expect(notifier.isSoldierAvailable(bravo), isTrue);
    expect(notifier.deployMission(secondMission, [bravo.id]), isFalse);
    expect(
      container.read(gameStateProvider).activeMissions.map((m) => m.id),
      contains(secondMission.id),
    );
  });

  test('tick completes a deployed operation and creates a report', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(gameStateProvider.notifier);
    final mission = _mission('complete', difficulty: 1);
    const squad = [
      Soldier(id: 's1', name: 'Alpha', rank: 2),
      Soldier(id: 's2', name: 'Bravo', rank: 2),
    ];
    final operation = DeployedOperation(
      id: 'op_complete',
      mission: mission,
      soldierIds: squad.map((s) => s.id).toList(),
      secondsRemaining: 1,
      totalDurationSeconds: 45,
      randomSeed: 7,
    );
    final expected = AutoOperationResolver.resolve(operation, squad);
    notifier.loadSave(
      container
          .read(gameStateProvider)
          .copyWith(soldiers: squad, deployedOperations: [operation]),
    );

    notifier.tick(2);

    final updated = container.read(gameStateProvider);
    expect(updated.deployedOperations, isEmpty);
    expect(updated.operationReports, hasLength(1));
    expect(updated.operationReports.single.victory, expected.victory);
    expect(updated.operationReports.single.regionName, mission.regionName);
    for (final survivor in updated.soldiers) {
      expect(notifier.deployedSoldierIds, isNot(contains(survivor.id)));
      expect(survivor.missionsSurvived, 1);
      expect(survivor.xp, greaterThan(0));
    }
  });

  test('auto operation resolution is deterministic for a persisted seed', () {
    final operation = DeployedOperation(
      id: 'op_seeded',
      mission: _mission('seeded', difficulty: 4),
      soldierIds: const ['s1'],
      secondsRemaining: 1,
      totalDurationSeconds: 75,
      randomSeed: 99,
    );
    const squad = [Soldier(id: 's1', name: 'Alpha')];

    final first = AutoOperationResolver.resolve(operation, squad);
    final second = AutoOperationResolver.resolve(operation, squad);

    expect(second.victory, first.victory);
    expect(second.soldierOutcomes, first.soldierOutcomes);
  });
}
