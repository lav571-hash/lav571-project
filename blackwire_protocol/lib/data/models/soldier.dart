import 'dart:math';

import '../../core/constants.dart';
import '../content/skill_catalog.dart';
import 'skill.dart';
import 'specialization.dart';

enum SoldierStatus { active, wounded, dead }

/// A member of the Reclaim roster.
///
/// Progression: soldiers earn XP from missions and gain ranks (1-10). Rank 1
/// unlocks a [Specialization] choice; ranks 2-10 each unlock a skill choice
/// from that specialization's pool. Separately, [maxHp], [baseAccuracy],
/// [movementRange] and [willpower] grow passively through *practice* (wounds
/// survived, shots fired, missions completed, successful actions) rather
/// than automatically per rank.
class Soldier {
  final String id;
  final String name;
  final int maxHp;
  final int currentHp;
  final int movementRange;
  final int baseAccuracy;
  final int willpower;
  final String weaponId;
  final String? armorId;
  final List<String> abilityIds;
  final SoldierStatus status;
  final double recoveryDaysLeft;
  final int missionsSurvived;

  final int rank;
  final int xp;
  final Specialization? specialization;
  final List<String> unlockedSkillIds;
  final int movementBonusStacks;
  final int willProgressCounter;

  const Soldier({
    required this.id,
    required this.name,
    this.maxHp = 100,
    int? currentHp,
    this.movementRange = 5,
    this.baseAccuracy = 65,
    this.willpower = GameConfig.startingWillpower,
    this.weaponId = 'pistol_mk1',
    this.armorId,
    this.abilityIds = const [],
    this.status = SoldierStatus.active,
    this.recoveryDaysLeft = 0,
    this.missionsSurvived = 0,
    this.rank = 0,
    this.xp = 0,
    this.specialization,
    this.unlockedSkillIds = const [],
    this.movementBonusStacks = 0,
    this.willProgressCounter = 0,
  }) : currentHp = currentHp ?? maxHp;

  bool get isAvailable => status == SoldierStatus.active;

  /// True once this soldier has reached Rank 1 but hasn't yet chosen a
  /// specialization.
  bool get hasPendingSpecializationChoice =>
      rank >= 1 && specialization == null;

  /// True if this soldier's rank has advanced past what their recorded
  /// skill picks account for (one skill choice per rank from 2 to [rank]).
  bool get hasPendingSkillChoice =>
      specialization != null &&
      rank >= 2 &&
      unlockedSkillIds.length < (rank - 1);

  bool get hasPendingPromotion =>
      hasPendingSpecializationChoice || hasPendingSkillChoice;

  static const List<String> rankNames = [
    'Новобранец',
    'Оперативник',
    'Специалист',
    'Ветеран',
    'Штурмовик-элита',
    'Теневой агент',
    'Коммандер ячейки',
    'Призрак сети',
    'Легенда Reclaim',
    'Икона Сопротивления',
  ];

  String get rankName =>
      rank == 0 ? 'Новичок' : rankNames[(rank - 1).clamp(0, 9)];

  int get xpForNextRank =>
      rank >= GameConfig.maxRank ? xp : GameConfig.rankXpThresholds[rank];

  /// Sums this soldier's picked skills into flat combat-stat bonuses. Used
  /// by [BattleFactory] when building the tactical unit for a mission.
  ({
    int hp,
    int accuracy,
    int movement,
    int will,
    int damageReduction,
    int weaponDamage,
    int weaponRange,
    int critChance,
  })
  get skillBonuses {
    var hp = 0, accuracy = 0, movement = 0, will = 0;
    var damageReduction = 0, weaponDamage = 0, weaponRange = 0, critChance = 0;
    for (final skillId in unlockedSkillIds) {
      final def = SkillCatalog.all[skillId];
      if (def == null) continue;
      switch (def.effect.type) {
        case SkillEffectType.hp:
          hp += def.effect.value;
        case SkillEffectType.accuracy:
          accuracy += def.effect.value;
        case SkillEffectType.movement:
          movement += def.effect.value;
        case SkillEffectType.will:
          will += def.effect.value;
        case SkillEffectType.damageReduction:
          damageReduction += def.effect.value;
        case SkillEffectType.weaponDamage:
          weaponDamage += def.effect.value;
        case SkillEffectType.weaponRange:
          weaponRange += def.effect.value;
        case SkillEffectType.critChance:
          critChance += def.effect.value;
      }
    }
    return (
      hp: hp,
      accuracy: accuracy,
      movement: movement,
      will: will,
      damageReduction: damageReduction,
      weaponDamage: weaponDamage,
      weaponRange: weaponRange,
      critChance: critChance,
    );
  }

  Soldier copyWith({
    String? id,
    String? name,
    int? maxHp,
    int? currentHp,
    int? movementRange,
    int? baseAccuracy,
    int? willpower,
    String? weaponId,
    String? armorId,
    List<String>? abilityIds,
    SoldierStatus? status,
    double? recoveryDaysLeft,
    int? missionsSurvived,
    int? rank,
    int? xp,
    Specialization? specialization,
    bool clearSpecialization = false,
    List<String>? unlockedSkillIds,
    int? movementBonusStacks,
    int? willProgressCounter,
  }) {
    return Soldier(
      id: id ?? this.id,
      name: name ?? this.name,
      maxHp: maxHp ?? this.maxHp,
      currentHp: currentHp ?? this.currentHp,
      movementRange: movementRange ?? this.movementRange,
      baseAccuracy: baseAccuracy ?? this.baseAccuracy,
      willpower: willpower ?? this.willpower,
      weaponId: weaponId ?? this.weaponId,
      armorId: armorId ?? this.armorId,
      abilityIds: abilityIds ?? this.abilityIds,
      status: status ?? this.status,
      recoveryDaysLeft: recoveryDaysLeft ?? this.recoveryDaysLeft,
      missionsSurvived: missionsSurvived ?? this.missionsSurvived,
      rank: rank ?? this.rank,
      xp: xp ?? this.xp,
      specialization: clearSpecialization
          ? null
          : (specialization ?? this.specialization),
      unlockedSkillIds: unlockedSkillIds ?? this.unlockedSkillIds,
      movementBonusStacks: movementBonusStacks ?? this.movementBonusStacks,
      willProgressCounter: willProgressCounter ?? this.willProgressCounter,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'maxHp': maxHp,
    'currentHp': currentHp,
    'movementRange': movementRange,
    'baseAccuracy': baseAccuracy,
    'willpower': willpower,
    'weaponId': weaponId,
    'armorId': armorId,
    'abilityIds': abilityIds,
    'status': status.name,
    'recoveryDaysLeft': recoveryDaysLeft,
    'missionsSurvived': missionsSurvived,
    'rank': rank,
    'xp': xp,
    'specialization': specialization?.name,
    'unlockedSkillIds': unlockedSkillIds,
    'movementBonusStacks': movementBonusStacks,
    'willProgressCounter': willProgressCounter,
  };

  factory Soldier.fromJson(Map<String, dynamic> json) => Soldier(
    id: json['id'] as String,
    name: json['name'] as String,
    maxHp: json['maxHp'] as int? ?? 100,
    currentHp: json['currentHp'] as int?,
    movementRange: json['movementRange'] as int? ?? 5,
    baseAccuracy: json['baseAccuracy'] as int? ?? 65,
    willpower: json['willpower'] as int? ?? GameConfig.startingWillpower,
    weaponId: json['weaponId'] as String? ?? 'pistol_mk1',
    armorId: json['armorId'] as String?,
    abilityIds: (json['abilityIds'] as List?)?.cast<String>() ?? const [],
    status: SoldierStatus.values.firstWhere(
      (e) => e.name == json['status'],
      orElse: () => SoldierStatus.active,
    ),
    recoveryDaysLeft: (json['recoveryDaysLeft'] as num?)?.toDouble() ?? 0,
    missionsSurvived: json['missionsSurvived'] as int? ?? 0,
    rank: json['rank'] as int? ?? 0,
    xp: json['xp'] as int? ?? 0,
    specialization: (json['specialization'] as String?) == null
        ? null
        : Specialization.values.firstWhere(
            (e) => e.name == json['specialization'],
          ),
    unlockedSkillIds:
        (json['unlockedSkillIds'] as List?)?.cast<String>() ?? const [],
    movementBonusStacks: json['movementBonusStacks'] as int? ?? 0,
    willProgressCounter: json['willProgressCounter'] as int? ?? 0,
  );

  static final List<String> _firstNames = [
    'Alex',
    'Jordan',
    'Riley',
    'Kai',
    'Sasha',
    'Nova',
    'Reo',
    'Vega',
    'Mika',
    'Dex',
    'Zara',
    'Onyx',
    'Juno',
    'Cole',
    'Ivy',
    'Rook',
  ];
  static final List<String> _callSigns = [
    'Ghost',
    'Static',
    'Wren',
    'Cipher',
    'Ash',
    'Vortex',
    'Nyx',
    'Splice',
    'Echo',
    'Fuse',
    'Bishop',
    'Rune',
    'Vane',
    'Talon',
    'Glitch',
    'Halo',
  ];

  static Soldier generateRandom(Random random) {
    final first = _firstNames[random.nextInt(_firstNames.length)];
    final call = _callSigns[random.nextInt(_callSigns.length)];
    return Soldier(
      id: 'sol_${DateTime.now().microsecondsSinceEpoch}_${random.nextInt(99999)}',
      name: '$first "$call"',
      baseAccuracy: 55 + random.nextInt(20),
      movementRange: 4 + random.nextInt(3),
      willpower: GameConfig.startingWillpower - 5 + random.nextInt(11),
    );
  }
}
