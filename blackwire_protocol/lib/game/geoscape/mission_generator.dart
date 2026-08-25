import 'dart:math';

import '../../core/constants.dart';
import '../../data/content/regions.dart';
import '../../data/models/faction.dart';
import '../../data/models/mission_site.dart';

class MissionGenerator {
  static MissionSite generate(Random random, {EnemyFactionId? forceFaction}) {
    final factionId =
        forceFaction ??
        EnemyFactionId.values[random.nextInt(EnemyFactionId.values.length)];
    final type = MissionType.values[random.nextInt(MissionType.values.length)];
    final region = kRegionNames[random.nextInt(kRegionNames.length)];
    final difficulty = 1 + random.nextInt(4);
    final lifetime = 60.0 * GameConfig.missionLifetimeMinutes;

    return MissionSite(
      id: 'mission_${DateTime.now().microsecondsSinceEpoch}_${random.nextInt(99999)}',
      factionId: factionId,
      type: type,
      regionName: region,
      x: 0.08 + random.nextDouble() * 0.84,
      y: 0.12 + random.nextDouble() * 0.76,
      difficulty: difficulty,
      secondsRemaining: lifetime,
      totalLifetimeSeconds: lifetime,
    );
  }
}
