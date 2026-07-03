import 'dart:math';

enum SoldierStatus { active, wounded, dead }

/// A member of the Reclaim roster.
///
/// Soldier classes are intentionally omitted from the MVP (planned for a
/// later milestone) - every soldier shares the same base stats, only
/// equipment differentiates them for now.
class Soldier {
  final String id;
  final String name;
  final int maxHp;
  final int currentHp;
  final int movementRange;
  final int baseAccuracy;
  final String weaponId;
  final String? armorId;
  final List<String> abilityIds;
  final SoldierStatus status;
  final int recoveryDaysLeft;
  final int missionsSurvived;

  const Soldier({
    required this.id,
    required this.name,
    this.maxHp = 100,
    int? currentHp,
    this.movementRange = 5,
    this.baseAccuracy = 65,
    this.weaponId = 'pistol_mk1',
    this.armorId,
    this.abilityIds = const [],
    this.status = SoldierStatus.active,
    this.recoveryDaysLeft = 0,
    this.missionsSurvived = 0,
  }) : currentHp = currentHp ?? maxHp;

  bool get isAvailable => status == SoldierStatus.active;

  Soldier copyWith({
    String? id,
    String? name,
    int? maxHp,
    int? currentHp,
    int? movementRange,
    int? baseAccuracy,
    String? weaponId,
    String? armorId,
    List<String>? abilityIds,
    SoldierStatus? status,
    int? recoveryDaysLeft,
    int? missionsSurvived,
  }) {
    return Soldier(
      id: id ?? this.id,
      name: name ?? this.name,
      maxHp: maxHp ?? this.maxHp,
      currentHp: currentHp ?? this.currentHp,
      movementRange: movementRange ?? this.movementRange,
      baseAccuracy: baseAccuracy ?? this.baseAccuracy,
      weaponId: weaponId ?? this.weaponId,
      armorId: armorId ?? this.armorId,
      abilityIds: abilityIds ?? this.abilityIds,
      status: status ?? this.status,
      recoveryDaysLeft: recoveryDaysLeft ?? this.recoveryDaysLeft,
      missionsSurvived: missionsSurvived ?? this.missionsSurvived,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'maxHp': maxHp,
    'currentHp': currentHp,
    'movementRange': movementRange,
    'baseAccuracy': baseAccuracy,
    'weaponId': weaponId,
    'armorId': armorId,
    'abilityIds': abilityIds,
    'status': status.name,
    'recoveryDaysLeft': recoveryDaysLeft,
    'missionsSurvived': missionsSurvived,
  };

  factory Soldier.fromJson(Map<String, dynamic> json) => Soldier(
    id: json['id'] as String,
    name: json['name'] as String,
    maxHp: json['maxHp'] as int? ?? 100,
    currentHp: json['currentHp'] as int?,
    movementRange: json['movementRange'] as int? ?? 5,
    baseAccuracy: json['baseAccuracy'] as int? ?? 65,
    weaponId: json['weaponId'] as String? ?? 'pistol_mk1',
    armorId: json['armorId'] as String?,
    abilityIds: (json['abilityIds'] as List?)?.cast<String>() ?? const [],
    status: SoldierStatus.values.firstWhere(
      (e) => e.name == json['status'],
      orElse: () => SoldierStatus.active,
    ),
    recoveryDaysLeft: json['recoveryDaysLeft'] as int? ?? 0,
    missionsSurvived: json['missionsSurvived'] as int? ?? 0,
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
    );
  }
}
