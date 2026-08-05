import '../../core/constants.dart';
import 'base_state.dart';
import 'faction.dart';
import 'mission_site.dart';
import 'resources.dart';
import 'soldier.dart';

/// The full persisted state of a Reclaim campaign.
class GameSave {
  final Resources resources;
  final BaseState base;
  final List<Soldier> soldiers;
  final Set<String> completedResearchIds;
  final Set<String> unlockedWeaponIds;
  final Set<String> unlockedArmorIds;
  final Set<String> unlockedAbilityIds;
  final Map<String, int> weaponStock;
  final Map<String, int> armorStock;
  final Map<String, int> intelTrophies;
  final List<FactionThreat> factionThreats;
  final double chaosLevel;
  final List<MissionSite> activeMissions;
  final double elapsedGameSeconds;
  final bool gameOver;
  final bool victory;

  const GameSave({
    required this.resources,
    required this.base,
    required this.soldiers,
    required this.completedResearchIds,
    required this.unlockedWeaponIds,
    required this.unlockedArmorIds,
    required this.unlockedAbilityIds,
    required this.weaponStock,
    required this.armorStock,
    this.intelTrophies = const {},
    required this.factionThreats,
    required this.chaosLevel,
    required this.activeMissions,
    required this.elapsedGameSeconds,
    this.gameOver = false,
    this.victory = false,
  });

  factory GameSave.newGame() => GameSave(
    resources: const Resources(
      credits: GameConfig.startingCredits,
      materials: GameConfig.startingMaterials,
      data: GameConfig.startingData,
    ),
    base: const BaseState(),
    soldiers: [],
    completedResearchIds: {},
    unlockedWeaponIds: {'pistol_mk1'},
    unlockedArmorIds: {},
    unlockedAbilityIds: {},
    weaponStock: {},
    armorStock: {},
    factionThreats: EnemyFactionId.values
        .map((f) => FactionThreat(factionId: f, threatLevel: 10))
        .toList(),
    chaosLevel: 0,
    activeMissions: [],
    elapsedGameSeconds: 0,
  );

  GameSave copyWith({
    Resources? resources,
    BaseState? base,
    List<Soldier>? soldiers,
    Set<String>? completedResearchIds,
    Set<String>? unlockedWeaponIds,
    Set<String>? unlockedArmorIds,
    Set<String>? unlockedAbilityIds,
    Map<String, int>? weaponStock,
    Map<String, int>? armorStock,
    Map<String, int>? intelTrophies,
    List<FactionThreat>? factionThreats,
    double? chaosLevel,
    List<MissionSite>? activeMissions,
    double? elapsedGameSeconds,
    bool? gameOver,
    bool? victory,
  }) {
    return GameSave(
      resources: resources ?? this.resources,
      base: base ?? this.base,
      soldiers: soldiers ?? this.soldiers,
      completedResearchIds: completedResearchIds ?? this.completedResearchIds,
      unlockedWeaponIds: unlockedWeaponIds ?? this.unlockedWeaponIds,
      unlockedArmorIds: unlockedArmorIds ?? this.unlockedArmorIds,
      unlockedAbilityIds: unlockedAbilityIds ?? this.unlockedAbilityIds,
      weaponStock: weaponStock ?? this.weaponStock,
      armorStock: armorStock ?? this.armorStock,
      intelTrophies: intelTrophies ?? this.intelTrophies,
      factionThreats: factionThreats ?? this.factionThreats,
      chaosLevel: chaosLevel ?? this.chaosLevel,
      activeMissions: activeMissions ?? this.activeMissions,
      elapsedGameSeconds: elapsedGameSeconds ?? this.elapsedGameSeconds,
      gameOver: gameOver ?? this.gameOver,
      victory: victory ?? this.victory,
    );
  }

  Map<String, dynamic> toJson() => {
    'resources': resources.toJson(),
    'base': base.toJson(),
    'soldiers': soldiers.map((s) => s.toJson()).toList(),
    'completedResearchIds': completedResearchIds.toList(),
    'unlockedWeaponIds': unlockedWeaponIds.toList(),
    'unlockedArmorIds': unlockedArmorIds.toList(),
    'unlockedAbilityIds': unlockedAbilityIds.toList(),
    'weaponStock': weaponStock,
    'armorStock': armorStock,
    'intelTrophies': intelTrophies,
    'factionThreats': factionThreats.map((f) => f.toJson()).toList(),
    'chaosLevel': chaosLevel,
    'activeMissions': activeMissions.map((m) => m.toJson()).toList(),
    'elapsedGameSeconds': elapsedGameSeconds,
    'gameOver': gameOver,
    'victory': victory,
  };

  factory GameSave.fromJson(Map<String, dynamic> json) => GameSave(
    resources: Resources.fromJson(json['resources'] as Map<String, dynamic>),
    base: BaseState.fromJson(json['base'] as Map<String, dynamic>),
    soldiers: (json['soldiers'] as List)
        .map((s) => Soldier.fromJson(s as Map<String, dynamic>))
        .toList(),
    completedResearchIds: (json['completedResearchIds'] as List)
        .cast<String>()
        .toSet(),
    unlockedWeaponIds: (json['unlockedWeaponIds'] as List)
        .cast<String>()
        .toSet(),
    unlockedArmorIds: (json['unlockedArmorIds'] as List).cast<String>().toSet(),
    unlockedAbilityIds: (json['unlockedAbilityIds'] as List)
        .cast<String>()
        .toSet(),
    weaponStock: Map<String, int>.from(json['weaponStock'] as Map),
    armorStock: Map<String, int>.from(json['armorStock'] as Map),
    intelTrophies: Map<String, int>.from(
      json['intelTrophies'] as Map? ?? const {},
    ),
    factionThreats: (json['factionThreats'] as List)
        .map((f) => FactionThreat.fromJson(f as Map<String, dynamic>))
        .toList(),
    chaosLevel: (json['chaosLevel'] as num).toDouble(),
    activeMissions: (json['activeMissions'] as List)
        .map((m) => MissionSite.fromJson(m as Map<String, dynamic>))
        .toList(),
    elapsedGameSeconds: (json['elapsedGameSeconds'] as num).toDouble(),
    gameOver: json['gameOver'] as bool? ?? false,
    victory: json['victory'] as bool? ?? false,
  );
}
