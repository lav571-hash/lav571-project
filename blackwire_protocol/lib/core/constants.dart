import 'package:flutter/material.dart';

/// Global visual & gameplay constants for BLACKWIRE PROTOCOL.
class AppColors {
  AppColors._();

  static const Color background = Color(0xFF0A0E14);
  static const Color surface = Color(0xFF121826);
  static const Color surfaceAlt = Color(0xFF1B2333);
  static const Color neonCyan = Color(0xFF00E5FF);
  static const Color neonMagenta = Color(0xFFFF2079);
  static const Color neonYellow = Color(0xFFFFD400);
  static const Color neonGreen = Color(0xFF39FF6A);
  static const Color textPrimary = Color(0xFFE6F1FF);
  static const Color textSecondary = Color(0xFF7C8AA5);
  static const Color danger = Color(0xFFFF3B4E);

  // Faction accent colors.
  static const Color titanDynamics = Color(0xFFFF7A29); // PMC - orange
  static const Color nexusRobotics = Color(0xFF29C7FF); // droids - blue
  static const Color chimeraLabs = Color(0xFF9B5CFF); // mutants - purple
}

class GameConfig {
  GameConfig._();

  static const double tileSize = 48.0;
  static const int defaultMapWidth = 16;
  static const int defaultMapHeight = 12;

  static const int startingCredits = 500;
  static const int startingMaterials = 20;
  static const int startingData = 0;

  static const int baseVisionRange = 8;
  static const int chaosGameOverThreshold = 100;

  // Geoscape real-time clock.
  static const double secondsPerGameDay = 24.0;
  static const double missionLifetimeMinutes =
      5.5; // in-game-day-equivalent lifetime, expressed via ticking seconds.
  static const double factionThreatGrowthPerSecond = 0.45;
  static const double chaosGrowthFactor = 0.22;
  static const double meanSecondsBetweenMissions = 26.0;
  static const int maxActiveMissions = 5;
  static const int maxSquadSize = 4;
  static const double autoOperationBaseSeconds = 35;
  static const double autoOperationSecondsPerDifficulty = 10;
  static const int maxOperationReports = 10;

  // --- Tactical AI & difficulty balance ---------------------------------
  static const int aiDetectionRange = 8;
  static const double aiRetreatHpFraction = 0.35;
  static const int enemyHpPerDifficulty = 3;
  static const int enemyAccuracyPerDifficulty = 2;
  static const double enemyFearAttackChance = 0.18;

  // --- Medbay ------------------------------------------------------------
  static const double medbayRecoveryBonusPerLevel = 0.25;
  static const int intensiveCareBaseCost = 50;
  static const int intensiveCareCostPerRecoveryDay = 10;

  // --- Intelligence center ----------------------------------------------
  static const int intelDataPerFacilityLevel = 2;

  // --- Rank / XP progression --------------------------------------------
  /// Cumulative XP required to be at rank index N (index 0 == rank 1, the
  /// starting rank at which a soldier picks their specialization).
  static const List<int> rankXpThresholds = [
    0,
    30,
    70,
    120,
    190,
    280,
    400,
    550,
    750,
    1000,
  ];
  static const int maxRank = 10;
  static const int xpPerMissionParticipation = 10;
  static const int xpPerKill = 15;
  static const int xpPerHit = 3;

  // --- Practice-based stat growth ----------------------------------------
  static const int hpGainPerWound = 3;
  static const int movementMissionsPerBonus = 5;
  static const int maxMovementBonusStacks = 3;
  static const int willSuccessfulActionsPerBonus = 3;

  /// Per-mission shots-fired thresholds -> accuracy bonus (highest reached
  /// threshold wins, does not stack).
  static const Map<int, int> accuracyShotThresholds = {3: 1, 9: 2, 27: 3};

  static const int startingWillpower = 50;

  // --- Panic (Will checks) ------------------------------------------------
  static const int basePanicChance = 70; // minus willpower, clamped below.
  static const int minPanicChance = 5;
  static const int maxPanicChance = 95;
  static const int panicFireAccuracyPenalty = 20;
}
