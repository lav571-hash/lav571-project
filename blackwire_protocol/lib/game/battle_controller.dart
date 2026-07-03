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
/// fog of war and win/loss detection. Pure Dart - independent of Flame/UI,
/// which makes it straightforward to unit test.
class BattleController {
  final TacticalMap map;
  final List<TacticalUnit> units;
  final CombatResolver combatResolver;
  final SimpleAi ai;

  BattlePhase phase = BattlePhase.playerTurn;
  String? selectedUnitId;
  final Set<GridPos> exploredTiles = {};
  final List<CombatLogEntry> log = [];
  int turnNumber = 1;

  BattleController({
    required this.map,
    required this.units,
    CombatResolver? combatResolver,
    SimpleAi? ai,
  }) : combatResolver = combatResolver ?? CombatResolver(),
       ai = ai ?? SimpleAi() {
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
      if (result.attackResult != null && result.attackedTarget != null) {
        final r = result.attackResult!;
        log.add(
          CombatLogEntry(
            r.hit
                ? '${enemy.displayName} попадает по ${result.attackedTarget!.displayName} (${r.damage} урона)${r.targetKilled ? ' — боец погиб!' : ''}'
                : '${enemy.displayName} промахивается по ${result.attackedTarget!.displayName}.',
          ),
        );
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
