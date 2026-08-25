import 'dart:math';

import '../data/models/deployed_operation.dart';
import '../data/models/soldier.dart';

enum AutoSoldierOutcome { ready, wounded, killed }

class AutoOperationOutcome {
  final bool victory;
  final Map<String, AutoSoldierOutcome> soldierOutcomes;

  const AutoOperationOutcome({
    required this.victory,
    required this.soldierOutcomes,
  });
}

class AutoOperationResolver {
  AutoOperationResolver._();

  static AutoOperationOutcome resolve(
    DeployedOperation operation,
    List<Soldier> squad,
  ) {
    final random = Random(operation.randomSeed);
    final averageCombatScore = squad.isEmpty
        ? 0
        : squad
                  .map(
                    (s) =>
                        s.baseAccuracy +
                        s.willpower / 2 +
                        s.rank * 5 +
                        s.unlockedSkillIds.length * 3,
                  )
                  .reduce((a, b) => a + b) /
              squad.length;
    final victoryChance =
        (0.52 +
                squad.length * 0.08 +
                averageCombatScore * 0.002 -
                operation.mission.difficulty * 0.10)
            .clamp(0.2, 0.92);
    final victory = random.nextDouble() < victoryChance;

    final outcomes = <String, AutoSoldierOutcome>{};
    for (final soldier in squad) {
      final roll = random.nextDouble();
      if (victory) {
        final deathChance = operation.mission.difficulty * 0.01;
        final woundChance = operation.mission.difficulty * 0.07;
        outcomes[soldier.id] = roll < deathChance
            ? AutoSoldierOutcome.killed
            : roll < deathChance + woundChance
            ? AutoSoldierOutcome.wounded
            : AutoSoldierOutcome.ready;
      } else {
        final deathChance = operation.mission.difficulty * 0.07;
        final woundChance = 0.25 + operation.mission.difficulty * 0.05;
        outcomes[soldier.id] = roll < deathChance
            ? AutoSoldierOutcome.killed
            : roll < deathChance + woundChance
            ? AutoSoldierOutcome.wounded
            : AutoSoldierOutcome.ready;
      }
    }
    return AutoOperationOutcome(victory: victory, soldierOutcomes: outcomes);
  }
}
