import 'dart:math';

import '../combat/combat_resolver.dart';
import '../map/line_of_sight.dart';
import '../map/pathfinding.dart';
import '../map/tactical_map.dart';
import '../map/tile.dart';
import '../units/enemy_defs.dart';
import '../units/tactical_unit.dart';

class AiTurnResult {
  final TacticalUnit enemy;
  final List<GridPos>? movePath;
  final TacticalUnit? attackedTarget;
  final AttackResult? attackResult;

  /// Non-empty when this attack was a faction "fear attack" - every unit
  /// listed here must roll a Will (panic) check.
  final List<TacticalUnit> panicTargets;
  final String? fearAttackName;

  const AiTurnResult({
    required this.enemy,
    this.movePath,
    this.attackedTarget,
    this.attackResult,
    this.panicTargets = const [],
    this.fearAttackName,
  });
}

/// A deliberately simple enemy AI for the MVP:
/// 1. If a player unit is visible and in weapon range -> attack it.
/// 2. Else if a player unit is visible but out of range -> move as close as
///    possible, then attack if now in range.
/// 3. Else -> move to a random reachable tile (patrol behaviour).
class SimpleAi {
  final Random random;
  final CombatResolver combatResolver;
  static const int detectionRange = 10;

  SimpleAi({Random? random, CombatResolver? combatResolver})
    : random = random ?? Random(),
      combatResolver = combatResolver ?? CombatResolver();

  AiTurnResult takeTurn(
    TacticalMap map,
    TacticalUnit enemy,
    List<TacticalUnit> allUnits,
  ) {
    final targets = allUnits
        .where((u) => u.team == Team.player && u.isAlive)
        .toList();
    final visibleTargets = targets
        .where(
          (t) =>
              t.position.chebyshevDistanceTo(enemy.position) <= detectionRange,
        )
        .where(
          (t) => LineOfSight.hasLineOfSight(map, enemy.position, t.position),
        )
        .toList();

    List<GridPos>? movePath;

    TacticalUnit? inRangeTarget = _bestAttackTarget(map, enemy, visibleTargets);

    if (inRangeTarget == null && visibleTargets.isNotEmpty) {
      // Move toward the nearest visible target.
      final blocked = allUnits
          .where((u) => u.isAlive && u.id != enemy.id)
          .map((u) => u.position)
          .toSet();
      final reachable = Pathfinding.reachableTiles(
        map,
        enemy.position,
        enemy.movementRange,
        blocked: blocked,
      );
      GridPos? bestTile;
      double bestDist = double.infinity;
      final nearestTarget = visibleTargets.reduce(
        (a, b) =>
            a.position.chebyshevDistanceTo(enemy.position) <=
                b.position.chebyshevDistanceTo(enemy.position)
            ? a
            : b,
      );
      for (final tile in reachable.keys) {
        final d = tile.distanceTo(nearestTarget.position);
        if (d < bestDist) {
          bestDist = d;
          bestTile = tile;
        }
      }
      if (bestTile != null) {
        movePath = reachable[bestTile];
        enemy.position = bestTile;
        enemy.hasMoved = true;
      }
      // Re-evaluate targets after moving.
      final visibleAfterMove = targets
          .where(
            (t) => LineOfSight.hasLineOfSight(map, enemy.position, t.position),
          )
          .toList();
      inRangeTarget = _bestAttackTarget(map, enemy, visibleAfterMove);
    } else if (visibleTargets.isEmpty) {
      // Patrol: move to a random reachable tile.
      final blocked = allUnits
          .where((u) => u.isAlive && u.id != enemy.id)
          .map((u) => u.position)
          .toSet();
      final reachable = Pathfinding.reachableTiles(
        map,
        enemy.position,
        enemy.movementRange,
        blocked: blocked,
      );
      if (reachable.isNotEmpty && random.nextBool()) {
        final keys = reachable.keys.toList();
        final chosen = keys[random.nextInt(keys.length)];
        movePath = reachable[chosen];
        enemy.position = chosen;
        enemy.hasMoved = true;
      }
    }

    AttackResult? attackResult;
    List<TacticalUnit> panicTargets = const [];
    String? fearAttackName;
    if (inRangeTarget != null) {
      attackResult = combatResolver.resolveAttack(map, enemy, inRangeTarget);
      enemy.hasActed = true;

      final enemyDef = enemy.enemyFactionId == null
          ? null
          : kEnemyDefs[enemy.enemyFactionId];
      if (enemyDef != null && random.nextDouble() < enemyDef.fearAttackChance) {
        fearAttackName = enemyDef.fearAttackName;
        panicTargets = targets
            .where((t) => t.isAlive)
            .where(
              (t) =>
                  t.position.distanceTo(inRangeTarget!.position) <=
                  enemyDef.fearAttackRadius,
            )
            .toList();
      }
    }

    enemy.hasMoved = true; // Enemies use their whole turn at once in the MVP.
    enemy.hasActed = true;

    return AiTurnResult(
      enemy: enemy,
      movePath: movePath,
      attackedTarget: inRangeTarget,
      attackResult: attackResult,
      panicTargets: panicTargets,
      fearAttackName: fearAttackName,
    );
  }

  TacticalUnit? _bestAttackTarget(
    TacticalMap map,
    TacticalUnit enemy,
    List<TacticalUnit> candidates,
  ) {
    final inRange = candidates
        .where((t) => combatResolver.canAttack(map, enemy, t))
        .toList();
    if (inRange.isEmpty) return null;
    inRange.sort((a, b) => a.currentHp.compareTo(b.currentHp));
    return inRange.first;
  }
}
