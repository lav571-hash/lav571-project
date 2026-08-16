import '../../core/constants.dart';
import '../../data/models/equipment.dart';
import '../../data/models/faction.dart';
import '../map/tile.dart';

enum Team { player, enemy }

/// A unit instance on the tactical battlefield. For player units this
/// wraps a roster [Soldier] (referenced by [soldierId]); for enemy units it
/// represents a disposable combatant belonging to an [EnemyFactionId].
class TacticalUnit {
  final String id;
  Team team;
  final String displayName;
  final int maxHp;
  int currentHp;
  GridPos position;
  final int movementRange;
  final int baseAccuracy;
  final WeaponDef weapon;
  final int damageReduction;
  final int weaponDamageBonus;
  final int weaponRangeBonus;
  final int critChance;
  final int willpower;

  final String? soldierId;
  final EnemyFactionId? enemyFactionId;
  final List<String> skillIds;
  final bool isTurret;

  bool hasMoved = false;
  bool hasActed = false;
  bool isHacked = false;

  /// Signature skills already spent this battle. Each signature tactical
  /// action (hack, turret, overrun, aimed shot, suppression, field heal)
  /// may be used once per mission.
  final Set<String> usedSignatures = {};

  /// Remaining turns this unit shoots at a penalty and cannot advance,
  /// applied by the heavy's suppression action.
  int suppressedTurns = 0;

  /// Per-mission combat tallies, used after the battle to grow the
  /// underlying soldier's stats through practice (see
  /// `GameStateNotifier.resolveMission`). Meaningless for enemy units.
  int shotsFired = 0;
  int hits = 0;
  int kills = 0;

  /// Set for the turn a failed Will check costs this unit its turn. The
  /// medic's field heal can rally a unit in this state.
  bool isPanicked = false;

  TacticalUnit({
    required this.id,
    required this.team,
    required this.displayName,
    required this.maxHp,
    required this.position,
    required this.movementRange,
    required this.baseAccuracy,
    required this.weapon,
    this.damageReduction = 0,
    this.weaponDamageBonus = 0,
    this.weaponRangeBonus = 0,
    this.critChance = 0,
    this.willpower = GameConfig.startingWillpower,
    this.soldierId,
    this.enemyFactionId,
    this.skillIds = const [],
    this.isTurret = false,
    int? currentHp,
  }) : currentHp = currentHp ?? maxHp;

  int get effectiveWeaponRange => weapon.range + weaponRangeBonus;

  bool get isSuppressed => suppressedTurns > 0;

  /// True when this unit knows [skillId] and has not spent it yet. Turrets
  /// are autonomous and never carry signature skills.
  bool hasSignatureAvailable(String skillId) =>
      !isTurret && skillIds.contains(skillId) && !usedSignatures.contains(skillId);

  void spendSignature(String skillId) => usedSignatures.add(skillId);

  bool get canHack => hasSignatureAvailable(GameConfig.hackSkillId);
  bool get canDeployTurret => hasSignatureAvailable(GameConfig.turretSkillId);
  bool get canOverrun => hasSignatureAvailable(GameConfig.overrunSkillId);
  bool get canAimedShot =>
      hasSignatureAvailable(GameConfig.aimedShotSkillId) && !hasMoved;
  bool get canSuppress => hasSignatureAvailable(GameConfig.suppressSkillId);
  bool get canFieldHeal => hasSignatureAvailable(GameConfig.fieldHealSkillId);

  bool get hasUsedHack => usedSignatures.contains(GameConfig.hackSkillId);
  bool get hasDeployedTurret =>
      usedSignatures.contains(GameConfig.turretSkillId);

  bool get isAlive => currentHp > 0;

  double get hpFraction => currentHp / maxHp;

  void resetTurnFlags() {
    hasMoved = false;
    hasActed = false;
    isPanicked = false;
  }

  bool get canAct => isAlive && !(hasMoved && hasActed);

  void applyDamage(int amount) {
    final mitigated = (amount - damageReduction).clamp(1, amount);
    currentHp = (currentHp - mitigated).clamp(0, maxHp);
  }
}
