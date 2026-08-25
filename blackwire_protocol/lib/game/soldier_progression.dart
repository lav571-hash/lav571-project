import '../core/constants.dart';
import '../data/models/soldier.dart';
import 'units/tactical_unit.dart';

/// Pure functions computing how a [Soldier] grows after a mission: XP/rank
/// progression (gates specialization + skill choices) and separate
/// practice-based stat growth (HP from wounds, accuracy from shots fired,
/// movement & willpower from missions/successful actions).
///
/// Kept free of Riverpod/state-notifier concerns so it can be unit tested
/// in isolation.
class SoldierProgression {
  SoldierProgression._();

  static int computeXp(TacticalUnit unit) {
    return GameConfig.xpPerMissionParticipation +
        unit.kills * GameConfig.xpPerKill +
        unit.hits * GameConfig.xpPerHit;
  }

  /// Adds [xpGained] and advances [soldier.rank] through as many thresholds
  /// as now satisfied. Does not auto-pick a specialization or skill - the
  /// caller/UI is expected to surface `hasPendingSpecializationChoice` /
  /// `hasPendingSkillChoice` once rank has advanced.
  static Soldier applyXpAndRankUp(Soldier soldier, int xpGained) {
    final newXp = soldier.xp + xpGained;
    var newRank = soldier.rank;
    while (newRank < GameConfig.maxRank &&
        newXp >= GameConfig.rankXpThresholds[newRank]) {
      newRank++;
    }
    return soldier.copyWith(xp: newXp, rank: newRank);
  }

  /// Applies practice-based growth for a soldier who survived the mission
  /// (wounded or not). [becameWounded] should reflect whether this mission
  /// left them below the wounded HP threshold.
  static Soldier applyPracticeGrowth(
    Soldier soldier,
    TacticalUnit unit, {
    required bool becameWounded,
  }) {
    var result = soldier;

    if (becameWounded) {
      result = result.copyWith(maxHp: result.maxHp + GameConfig.hpGainPerWound);
    }

    final accuracyGain = _bestAccuracyThreshold(unit.shotsFired);
    if (accuracyGain > 0) {
      result = result.copyWith(
        baseAccuracy: result.baseAccuracy + accuracyGain,
      );
    }

    if (result.missionsSurvived % GameConfig.movementMissionsPerBonus == 0 &&
        result.movementBonusStacks < GameConfig.maxMovementBonusStacks) {
      result = result.copyWith(
        movementRange: result.movementRange + 1,
        movementBonusStacks: result.movementBonusStacks + 1,
      );
    }

    final successfulActions = unit.hits + unit.kills;
    if (successfulActions > 0) {
      var counter = result.willProgressCounter + successfulActions;
      var willGain = 0;
      while (counter >= GameConfig.willSuccessfulActionsPerBonus) {
        counter -= GameConfig.willSuccessfulActionsPerBonus;
        willGain++;
      }
      if (willGain > 0 || counter != result.willProgressCounter) {
        result = result.copyWith(
          willpower: result.willpower + willGain,
          willProgressCounter: counter,
        );
      }
    }

    return result;
  }

  /// Returns the highest shots-fired threshold reached this mission (does
  /// not stack - see `GameConfig.accuracyShotThresholds`).
  static int _bestAccuracyThreshold(int shotsFired) {
    var best = 0;
    for (final entry in GameConfig.accuracyShotThresholds.entries) {
      if (shotsFired >= entry.key && entry.value > best) {
        best = entry.value;
      }
    }
    return best;
  }
}
