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
  final Team team;
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

  bool hasMoved = false;
  bool hasActed = false;

  /// Per-mission combat tallies, used after the battle to grow the
  /// underlying soldier's stats through practice (see
  /// `GameStateNotifier.resolveMission`). Meaningless for enemy units.
  int shotsFired = 0;
  int hits = 0;
  int kills = 0;

  /// Set for one turn when this unit fails a Will check; consumed by
  /// [BattleController] to apply the panic effect immediately.
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
    int? currentHp,
  }) : currentHp = currentHp ?? maxHp;

  int get effectiveWeaponRange => weapon.range + weaponRangeBonus;

  bool get isAlive => currentHp > 0;

  double get hpFraction => currentHp / maxHp;

  void resetTurnFlags() {
    hasMoved = false;
    hasActed = false;
  }

  bool get canAct => isAlive && !(hasMoved && hasActed);

  void applyDamage(int amount) {
    final mitigated = (amount - damageReduction).clamp(1, amount);
    currentHp = (currentHp - mitigated).clamp(0, maxHp);
  }
}
