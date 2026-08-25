import 'resources.dart';

class MissionResult {
  final bool victory;
  final Resources loot;
  final List<String> killedInAction;
  final List<String> wounded;
  final String factionName;
  final int trophiesRecovered;

  const MissionResult({
    required this.victory,
    required this.loot,
    required this.killedInAction,
    required this.wounded,
    required this.factionName,
    this.trophiesRecovered = 0,
  });
}
