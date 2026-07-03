/// A node in the research tree. Completing a node consumes `dataCost` and
/// unlocks either a weapon, armor or ability (referenced by id in the
/// respective catalog).
enum ResearchUnlockType { weapon, armor, ability }

class ResearchNodeDef {
  final String id;
  final String name;
  final String description;
  final int dataCost;
  final List<String> prerequisites;
  final ResearchUnlockType unlockType;
  final String unlockId;

  const ResearchNodeDef({
    required this.id,
    required this.name,
    required this.description,
    required this.dataCost,
    this.prerequisites = const [],
    required this.unlockType,
    required this.unlockId,
  });
}
