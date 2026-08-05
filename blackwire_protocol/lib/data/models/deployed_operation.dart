import 'mission_site.dart';
import 'resources.dart';

class DeployedOperation {
  final String id;
  final MissionSite mission;
  final List<String> soldierIds;
  final double secondsRemaining;
  final double totalDurationSeconds;
  final int randomSeed;

  const DeployedOperation({
    required this.id,
    required this.mission,
    required this.soldierIds,
    required this.secondsRemaining,
    required this.totalDurationSeconds,
    required this.randomSeed,
  });

  DeployedOperation copyWith({double? secondsRemaining}) => DeployedOperation(
    id: id,
    mission: mission,
    soldierIds: soldierIds,
    secondsRemaining: secondsRemaining ?? this.secondsRemaining,
    totalDurationSeconds: totalDurationSeconds,
    randomSeed: randomSeed,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'mission': mission.toJson(),
    'soldierIds': soldierIds,
    'secondsRemaining': secondsRemaining,
    'totalDurationSeconds': totalDurationSeconds,
    'randomSeed': randomSeed,
  };

  factory DeployedOperation.fromJson(Map<String, dynamic> json) =>
      DeployedOperation(
        id: json['id'] as String,
        mission: MissionSite.fromJson(json['mission'] as Map<String, dynamic>),
        soldierIds: (json['soldierIds'] as List).cast<String>(),
        secondsRemaining: (json['secondsRemaining'] as num).toDouble(),
        totalDurationSeconds: (json['totalDurationSeconds'] as num).toDouble(),
        randomSeed: json['randomSeed'] as int,
      );
}

class OperationReport {
  final String id;
  final String regionName;
  final String factionName;
  final bool victory;
  final Resources loot;
  final int trophiesRecovered;
  final List<String> wounded;
  final List<String> killedInAction;

  const OperationReport({
    required this.id,
    required this.regionName,
    required this.factionName,
    required this.victory,
    required this.loot,
    required this.trophiesRecovered,
    required this.wounded,
    required this.killedInAction,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'regionName': regionName,
    'factionName': factionName,
    'victory': victory,
    'loot': loot.toJson(),
    'trophiesRecovered': trophiesRecovered,
    'wounded': wounded,
    'killedInAction': killedInAction,
  };

  factory OperationReport.fromJson(Map<String, dynamic> json) =>
      OperationReport(
        id: json['id'] as String,
        regionName: json['regionName'] as String,
        factionName: json['factionName'] as String,
        victory: json['victory'] as bool,
        loot: Resources.fromJson(json['loot'] as Map<String, dynamic>),
        trophiesRecovered: json['trophiesRecovered'] as int? ?? 0,
        wounded: (json['wounded'] as List?)?.cast<String>() ?? const [],
        killedInAction:
            (json['killedInAction'] as List?)?.cast<String>() ?? const [],
      );
}
