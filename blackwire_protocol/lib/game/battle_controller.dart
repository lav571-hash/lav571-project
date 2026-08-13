import 'dart:math';

import '../core/constants.dart';
import 'ai/simple_ai.dart';
import 'combat/combat_resolver.dart';
import 'map/line_of_sight.dart';
import 'map/pathfinding.dart';
import 'map/tactical_map.dart';
import 'map/tile.dart';
import 'units/tactical_unit.dart';

enum BattlePhase { playerTurn, enemyTurn, victory, defeat }

class CombatLogEntry {
  final String text;
  const CombatLogEntry(this.text);
}

/// Orchestrates a single tactical battle: turn order, movement, combat,
/// fog of war, panic/morale checks and win/loss detection. Pure Dart -
/// independent of Flame/UI, which makes it straightforward to unit test.
class BattleController {
  final TacticalMap map;
  final List<TacticalUnit> units;
  final CombatResolver combatResolver;
  final SimpleAi ai;
  final Random random;

  BattlePhase phase = BattlePhase.playerTurn;
  String? selectedUnitId;
  final Set<GridPos> exploredTiles = {};
  final List<CombatLogEntry> log = [];
  int turnNumber = 1;

  /// Player units that failed a Will check during the enemy's turn. Their
  /// panic effect is resolved once the new player turn actually begins, so
  /// it isn't immediately wiped out by the end-of-turn flag reset.
  final List<TacticalUnit> _pendingPanicResolutions = [];

  BattleController({
    required this.map,
    required this.units,
    CombatResolver? combatResolver,
    SimpleAi? ai,
    Random? random,
  }) : combatResolver = combatResolver ?? CombatResolver(),
       ai = ai ?? SimpleAi(),
       random = random ?? Random() {
    _recomputeVisibility();
  }

  List<TacticalUnit> get playerUnits =>
      units.where((u) => u.team == Team.player).toList();
  List<TacticalUnit> get enemyUnits =>
      units.where((u) => u.team == Team.enemy).toList();
  List<TacticalUnit> get alivePlayerUnits =>
      playerUnits.where((u) => u.isAlive).toList();
  List<TacticalUnit> get aliveEnemyUnits =>
      enemyUnits.where((u) => u.isAlive).toList();

  TacticalUnit? get selectedUnit {
    if (selectedUnitId == null) return null;
    for (final u in units) {
      if (u.id == selectedUnitId) return u;
    }
    return null;
  }

  Set<GridPos> _visibleTiles = {};
  Set<GridPos> get visibleTiles => _visibleTiles;

  void _recomputeVisibility() {
    final visible = <GridPos>{};
    for (final unit in alivePlayerUnits) {
      visible.addAll(
        LineOfSight.computeVisibleTiles(
          map,
          unit.position,
          GameConfig.baseVisionRange,
        ),
      );
    }
    _visibleTiles = visible;
    exploredTiles.addAll(visible);
  }

  bool isTileVisible(GridPos pos) => _visibleTiles.contains(pos);
  bool isTileExplored(GridPos pos) => exploredTiles.contains(pos);

  bool isEnemyVisible(TacticalUnit enemy) => isTileVisible(enemy.position);

  void selectUnit(String id) {
    final unit = units.where((u) => u.id == id).firstOrNull;
    if (unit == null || unit.team != Team.player || !unit.isAlive) return;
    selectedUnitId = id;
  }

  void clearSelection() => selectedUnitId = null;

  Map<GridPos, List<GridPos>> movementOptionsForSelected() {
    final unit = selectedUnit;
    if (unit == null || unit.hasMoved || phase != BattlePhase.playerTurn) {
      return {};
    }
    final blocked = units
        .where((u) => u.isAlive && u.id != unit.id)
        .map((u) => u.position)
        .toSet();
    return Pathfinding.reachableTiles(
      map,
      unit.position,
      unit.movementRange,
      blocked: blocked,
    );
  }

  bool moveSelectedTo(GridPos target) {
    final unit = selectedUnit;
    if (unit == null || phase != BattlePhase.playerTurn) return false;
    final options = movementOptionsForSelected();
    if (!options.containsKey(target)) return false;
    unit.position = target;
    unit.hasMoved = true;
    _recomputeVisibility();
    log.add(
      CombatLogEntry(
        '${unit.displayName} перемещается на ${target.x},${target.y}.',
      ),
    );
    return true;
  }

  List<TacticalUnit> attackableTargetsForSelected() {
    final unit = selectedUnit;
    if (unit == null || unit.hasActed || phase != BattlePhase.playerTurn) {
      return [];
    }
    return aliveEnemyUnits
        .where((e) => combatResolver.canAttack(map, unit, e))
        .toList();
  }

  AttackResult? attackTarget(String targetId) {
    final unit = selectedUnit;
    if (unit == null || unit.hasActed || phase != BattlePhase.playerTurn) {
      return null;
    }
    final target = units.where((u) => u.id == targetId).firstOrNull;
    if (target == null || !combatResolver.canAttack(map, unit, target)) {
      return null;
    }

    final result = combatResolver.resolveAttack(map, unit, target);
    unit.hasActed = true;
    log.add(
      CombatLogEntry(
        result.hit
            ? '${unit.displayName} попадает по ${target.displayName} (${result.damage} урона)${result.targetKilled ? ' — уничтожен!' : ''}'
            : '${unit.displayName} промахивается по ${target.displayName} (шанс ${result.hitChance}%).',
      ),
    );
    _checkEndConditions();
    return result;
  }

  void skipSelectedUnit() {
    final unit = selectedUnit;
    if (unit == null) return;
    unit.hasMoved = true;
    unit.hasActed = true;
    clearSelection();
  }

  bool get allPlayerUnitsDone =>
      alivePlayerUnits.every((u) => u.hasMoved && u.hasActed);

  void endPlayerTurn() {
    if (phase != BattlePhase.playerTurn) return;
    for (final u in alivePlayerUnits) {
      u.hasMoved = true;
      u.hasActed = true;
    }
    clearSelection();
    _runEnemyTurn();
  }

  void _runEnemyTurn() {
    phase = BattlePhase.enemyTurn;
    _checkEndConditions();
    if (phase != BattlePhase.enemyTurn) return;
    log.add(const CombatLogEntry('--- Ход противника ---'));
    for (final enemy in List<TacticalUnit>.from(aliveEnemyUnits)) {
      if (phase != BattlePhase.enemyTurn) break;
      if (!enemy.isAlive) continue;
      final result = ai.takeTurn(map, enemy, units);
      if (result.movePath != null && result.movePath!.isNotEmpty) {
        log.add(
          CombatLogEntry(
            '${enemy.displayName} перемещается на ${enemy.position.x},${enemy.position.y}.',
          ),
        );
      }
      if (result.attackResult != null && result.attackedTarget != null) {
        final r = result.attackResult!;
        final target = result.attackedTarget!;
        log.add(
          CombatLogEntry(
            r.hit
                ? '${enemy.displayName} попадает по ${target.displayName} (${r.damage} урона)${r.targetKilled ? ' — боец погиб!' : ''}'
                : '${enemy.displayName} промахивается по ${target.displayName}.',
          ),
        );
        if (r.targetKilled && target.team == Team.player) {
          _checkPanicForAlliesOf(target);
        }
      }
      if (result.fearAttackName != null && result.panicTargets.isNotEmpty) {
        log.add(
          CombatLogEntry(
            '${enemy.displayName} применяет способность «${result.fearAttackName}»!',
          ),
        );
        for (final t in result.panicTargets) {
          _rollPanicCheck(t, 'способность «${result.fearAttackName}»');
        }
      }
      _checkEndConditions();
      if (phase != BattlePhase.enemyTurn) break;
    }
    if (phase == BattlePhase.enemyTurn) {
      turnNumber++;
      for (final u in units) {
        u.resetTurnFlags();
      }
      _recomputeVisibility();
      phase = BattlePhase.playerTurn;
      log.add(CombatLogEntry('--- Ход $turnNumber: отряд Reclaim ---'));
      _resolvePendingPanics();
    }
  }

  // ---------------------------------------------------------------------
  // Panic / Will checks
  // ---------------------------------------------------------------------

  void _checkPanicForAlliesOf(TacticalUnit deadUnit) {
    for (final ally in alivePlayerUnits) {
      if (ally.id == deadUnit.id) continue;
      if (LineOfSight.hasLineOfSight(map, ally.position, deadUnit.position)) {
        _rollPanicCheck(ally, 'гибель союзника');
      }
    }
  }

  void _rollPanicCheck(TacticalUnit unit, String reason) {
    if (!unit.isAlive || unit.team != Team.player) return;
    if (_pendingPanicResolutions.contains(unit)) return;
    final panicChance = (GameConfig.basePanicChance - unit.willpower).clamp(
      GameConfig.minPanicChance,
      GameConfig.maxPanicChance,
    );
    if (random.nextInt(100) < panicChance) {
      _pendingPanicResolutions.add(unit);
      log.add(CombatLogEntry('${unit.displayName} на грани паники ($reason)!'));
    }
  }

  void _resolvePendingPanics() {
    if (_pendingPanicResolutions.isEmpty) return;
    var moved = false;
    for (final unit in _pendingPanicResolutions) {
      if (!unit.isAlive) continue;
      moved = _applyPanicEffect(unit) || moved;
    }
    _pendingPanicResolutions.clear();
    if (moved) _recomputeVisibility();
  }

  /// Applies one of three random panic effects to [unit]. Returns true if
  /// the unit's position changed (so callers know to refresh visibility).
  bool _applyPanicEffect(TacticalUnit unit) {
    final effect = random.nextInt(3);
    switch (effect) {
      case 0:
        unit.hasMoved = true;
        unit.hasActed = true;
        log.add(
          CombatLogEntry(
            '${unit.displayName} теряет самообладание и упускает ход.',
          ),
        );
        return false;
      case 1:
        final targets = aliveEnemyUnits
            .where((e) => combatResolver.canAttack(map, unit, e))
            .toList();
        if (targets.isNotEmpty) {
          final target = targets[random.nextInt(targets.length)];
          final result = combatResolver.resolveAttack(
            map,
            unit,
            target,
            accuracyPenalty: GameConfig.panicFireAccuracyPenalty,
          );
          log.add(
            CombatLogEntry(
              result.hit
                  ? '${unit.displayName} в панике открывает беспорядочный огонь по ${target.displayName} (${result.damage} урона)!'
                  : '${unit.displayName} в панике палит мимо ${target.displayName}!',
            ),
          );
          _checkEndConditions();
        } else {
          log.add(
            CombatLogEntry('${unit.displayName} в панике палит в пустоту.'),
          );
        }
        unit.hasMoved = true;
        unit.hasActed = true;
        return false;
      default:
        final blocked = units
            .where((u) => u.isAlive && u.id != unit.id)
            .map((u) => u.position)
            .toSet();
        final reachable = Pathfinding.reachableTiles(
          map,
          unit.position,
          unit.movementRange,
          blocked: blocked,
        );
        GridPos? bestTile;
        double bestScore = -1;
        for (final tile in reachable.keys) {
          double score = 0;
          for (final n in map.neighbors4(tile)) {
            if (map.tileAt(n) == TileType.wall) {
              score += 2;
            } else if (map.tileAt(n) == TileType.crate) {
              score += 1;
            }
          }
          if (aliveEnemyUnits.isNotEmpty) {
            score += aliveEnemyUnits
                .map((e) => tile.distanceTo(e.position))
                .reduce(min);
          }
          if (score > bestScore) {
            bestScore = score;
            bestTile = tile;
          }
        }
        unit.hasMoved = true;
        unit.hasActed = true;
        if (bestTile != null) {
          unit.position = bestTile;
          log.add(
            CombatLogEntry('${unit.displayName} в панике отступает в укрытие.'),
          );
          return true;
        }
        log.add(
          CombatLogEntry('${unit.displayName} в панике, но бежать некуда.'),
        );
        return false;
    }
  }

  void _checkEndConditions() {
    if (aliveEnemyUnits.isEmpty) {
      phase = BattlePhase.victory;
      log.add(const CombatLogEntry('Миссия выполнена. Все враги уничтожены.'));
    } else if (alivePlayerUnits.isEmpty) {
      phase = BattlePhase.defeat;
      log.add(const CombatLogEntry('Отряд уничтожен. Миссия провалена.'));
    }
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
