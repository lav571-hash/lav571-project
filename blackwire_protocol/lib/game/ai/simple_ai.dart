import 'dart:math';

import '../../core/constants.dart';
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

/// Tactical enemy AI: attacks vulnerable targets, advances through cover,
/// and retreats to a protected position when critically wounded.
class SimpleAi {
  final Random random;
  final CombatResolver combatResolver;
  static const int detectionRange = GameConfig.aiDetectionRange;

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
    var visibleTargets = _visibleTargets(map, enemy, targets);

    List<GridPos>? movePath;

    TacticalUnit? inRangeTarget;
    if (enemy.isSuppressed) {
      // Pinned down by suppressing fire: hold position and shoot wildly.
      inRangeTarget = _bestAttackTarget(map, enemy, visibleTargets);
      return _resolveAttackPhase(
        map,
        enemy,
        targets,
        inRangeTarget,
        null,
        accuracyPenalty: GameConfig.suppressAccuracyPenalty,
      );
    }
    if (enemy.hpFraction <= GameConfig.aiRetreatHpFraction &&
        visibleTargets.isNotEmpty) {
      final reachable = _reachableTiles(map, enemy, allUnits);
      final bestTile = _bestRetreatTile(map, reachable.keys, visibleTargets);
      if (bestTile != null) {
        movePath = reachable[bestTile];
        enemy.position = bestTile;
        enemy.hasMoved = true;
      }
    } else {
      inRangeTarget = _bestAttackTarget(map, enemy, visibleTargets);
    }

    if (inRangeTarget == null &&
        visibleTargets.isNotEmpty &&
        enemy.hpFraction > GameConfig.aiRetreatHpFraction) {
      final reachable = _reachableTiles(map, enemy, allUnits);
      final nearestTarget = visibleTargets.reduce(
        (a, b) =>
            a.position.chebyshevDistanceTo(enemy.position) <=
                b.position.chebyshevDistanceTo(enemy.position)
            ? a
            : b,
      );
      final bestTile = _bestAdvanceTile(
        map,
        enemy,
        reachable.keys,
        nearestTarget,
        visibleTargets,
      );
      if (bestTile != null) {
        movePath = reachable[bestTile];
        enemy.position = bestTile;
        enemy.hasMoved = true;
      }
      visibleTargets = _visibleTargets(map, enemy, targets);
      inRangeTarget = _bestAttackTarget(map, enemy, visibleTargets);
    } else if (visibleTargets.isEmpty) {
      final reachable = _reachableTiles(map, enemy, allUnits);
      if (reachable.isNotEmpty && random.nextBool()) {
        final keys = reachable.keys.toList();
        final chosen = keys[random.nextInt(keys.length)];
        movePath = reachable[chosen];
        enemy.position = chosen;
        enemy.hasMoved = true;
      }
    }

    return _resolveAttackPhase(map, enemy, targets, inRangeTarget, movePath);
  }

  /// Shoots [inRangeTarget] if there is one, rolls the faction fear attack
  /// and closes out the unit's turn.
  AiTurnResult _resolveAttackPhase(
    TacticalMap map,
    TacticalUnit enemy,
    List<TacticalUnit> targets,
    TacticalUnit? inRangeTarget,
    List<GridPos>? movePath, {
    int accuracyPenalty = 0,
  }) {
    AttackResult? attackResult;
    List<TacticalUnit> panicTargets = const [];
    String? fearAttackName;
    if (inRangeTarget != null) {
      attackResult = combatResolver.resolveAttack(
        map,
        enemy,
        inRangeTarget,
        accuracyPenalty: accuracyPenalty,
      );
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
                  t.position.distanceTo(inRangeTarget.position) <=
                  enemyDef.fearAttackRadius,
            )
            .toList();
      }
    }

    enemy.hasMoved = true;
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

  List<TacticalUnit> _visibleTargets(
    TacticalMap map,
    TacticalUnit enemy,
    List<TacticalUnit> targets,
  ) => targets
      .where(
        (target) =>
            target.position.chebyshevDistanceTo(enemy.position) <=
            detectionRange,
      )
      .where(
        (target) =>
            LineOfSight.hasLineOfSight(map, enemy.position, target.position),
      )
      .toList();

  Map<GridPos, List<GridPos>> _reachableTiles(
    TacticalMap map,
    TacticalUnit enemy,
    List<TacticalUnit> allUnits,
  ) {
    final blocked = allUnits
        .where((unit) => unit.isAlive && unit.id != enemy.id)
        .map((unit) => unit.position)
        .toSet();
    return Pathfinding.reachableTiles(
      map,
      enemy.position,
      enemy.movementRange,
      blocked: blocked,
    );
  }

  GridPos? _bestAdvanceTile(
    TacticalMap map,
    TacticalUnit enemy,
    Iterable<GridPos> candidates,
    TacticalUnit nearestTarget,
    List<TacticalUnit> visibleTargets,
  ) {
    GridPos? bestTile;
    var bestScore = -double.infinity;
    for (final tile in candidates) {
      final distance = tile.chebyshevDistanceTo(nearestTarget.position);
      final canAttackAfterMove =
          distance <= enemy.effectiveWeaponRange &&
          LineOfSight.hasLineOfSight(map, tile, nearestTarget.position);
      final cover = _coverScore(map, tile, visibleTargets);
      final score = (canAttackAfterMove ? 1000 : 0) + cover - distance * 10;
      if (score > bestScore ||
          (score == bestScore && _preferredTieBreak(tile, bestTile))) {
        bestScore = score;
        bestTile = tile;
      }
    }
    return bestTile;
  }

  GridPos? _bestRetreatTile(
    TacticalMap map,
    Iterable<GridPos> candidates,
    List<TacticalUnit> threats,
  ) {
    GridPos? bestTile;
    var bestScore = -double.infinity;
    for (final tile in candidates) {
      final cover = _coverScore(map, tile, threats) * 5;
      final distance = threats
          .map((target) => tile.chebyshevDistanceTo(target.position))
          .reduce(min);
      final breaksSight = threats.every(
        (target) => !LineOfSight.hasLineOfSight(map, tile, target.position),
      );
      final score = cover + distance * 5 + (breaksSight ? 200 : 0);
      if (score > bestScore ||
          (score == bestScore && _preferredTieBreak(tile, bestTile))) {
        bestScore = score;
        bestTile = tile;
      }
    }
    return bestTile;
  }

  double _coverScore(
    TacticalMap map,
    GridPos tile,
    List<TacticalUnit> threats,
  ) {
    if (threats.isEmpty) return 0;
    return threats
        .map(
          (target) => CombatResolver.coverPenalty(
            CombatResolver.coverLevelFor(map, tile, target.position),
          ),
        )
        .reduce(max)
        .toDouble();
  }

  bool _preferredTieBreak(GridPos candidate, GridPos? current) =>
      current == null ||
      candidate.y < current.y ||
      (candidate.y == current.y && candidate.x < current.x);

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
