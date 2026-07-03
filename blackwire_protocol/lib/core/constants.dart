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
}
