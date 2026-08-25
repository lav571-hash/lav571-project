import 'faction.dart';

enum MissionType { raid, sabotage, extraction, defense }

const Map<MissionType, String> kMissionTypeNames = {
  MissionType.raid: 'Рейд на объект',
  MissionType.sabotage: 'Диверсия',
  MissionType.extraction: 'Эвакуация информатора',
  MissionType.defense: 'Отражение атаки',
};

/// A mission opportunity that appears on the geoscape and expires after
/// [expiresInSeconds] of game-time if not launched.
class MissionSite {
  final String id;
  final EnemyFactionId factionId;
  final MissionType type;
  final String regionName;
  final double x; // 0..1 normalized position on geoscape map
  final double y;
  final int difficulty; // 1..5, scales enemy count/stats
  final double secondsRemaining;
  final double totalLifetimeSeconds;

  const MissionSite({
    required this.id,
    required this.factionId,
    required this.type,
    required this.regionName,
    required this.x,
    required this.y,
    required this.difficulty,
    required this.secondsRemaining,
    required this.totalLifetimeSeconds,
  });

  MissionSite copyWith({double? secondsRemaining}) => MissionSite(
    id: id,
    factionId: factionId,
    type: type,
    regionName: regionName,
    x: x,
    y: y,
    difficulty: difficulty,
    secondsRemaining: secondsRemaining ?? this.secondsRemaining,
    totalLifetimeSeconds: totalLifetimeSeconds,
  );

  bool get isExpired => secondsRemaining <= 0;

  Map<String, dynamic> toJson() => {
    'id': id,
    'factionId': factionId.name,
    'type': type.name,
    'regionName': regionName,
    'x': x,
    'y': y,
    'difficulty': difficulty,
    'secondsRemaining': secondsRemaining,
    'totalLifetimeSeconds': totalLifetimeSeconds,
  };

  factory MissionSite.fromJson(Map<String, dynamic> json) => MissionSite(
    id: json['id'] as String,
    factionId: EnemyFactionId.values.firstWhere(
      (e) => e.name == json['factionId'],
    ),
    type: MissionType.values.firstWhere((e) => e.name == json['type']),
    regionName: json['regionName'] as String,
    x: (json['x'] as num).toDouble(),
    y: (json['y'] as num).toDouble(),
    difficulty: json['difficulty'] as int,
    secondsRemaining: (json['secondsRemaining'] as num).toDouble(),
    totalLifetimeSeconds: (json['totalLifetimeSeconds'] as num).toDouble(),
  );
}
