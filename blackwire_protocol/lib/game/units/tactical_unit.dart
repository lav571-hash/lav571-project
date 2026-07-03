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

  final String? soldierId;
  final EnemyFactionId? enemyFactionId;

  bool hasMoved = false;
  bool hasActed = false;

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
    this.soldierId,
    this.enemyFactionId,
    int? currentHp,
  }) : currentHp = currentHp ?? maxHp;

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
