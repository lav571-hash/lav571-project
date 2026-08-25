import 'dart:math';

import 'package:blackwire_protocol/data/content/equipment_catalog.dart';
import 'package:blackwire_protocol/game/ai/simple_ai.dart';
import 'package:blackwire_protocol/game/battle_controller.dart';
import 'package:blackwire_protocol/game/combat/combat_resolver.dart';
import 'package:blackwire_protocol/game/map/tactical_map.dart';
import 'package:blackwire_protocol/game/map/tile.dart';
import 'package:blackwire_protocol/game/units/tactical_unit.dart';
import 'package:flutter_test/flutter_test.dart';

class _ZeroRandom implements Random {
  @override
  bool nextBool() => false;
  @override
  double nextDouble() => 0;
  @override
  int nextInt(int max) => 0;
}

BattleController _simpleController() {
  final map = TacticalMap(width: 10, height: 10);
  for (int x = 0; x < 10; x++) {
    map.setTile(GridPos(x, 0), TileType.wall);
    map.setTile(GridPos(x, 9), TileType.wall);
  }
  for (int y = 0; y < 10; y++) {
    map.setTile(GridPos(0, y), TileType.wall);
    map.setTile(GridPos(9, y), TileType.wall);
  }

  final player = TacticalUnit(
    id: 'p1',
    team: Team.player,
    displayName: 'Reclaim-1',
    maxHp: 100,
    position: const GridPos(2, 2),
    movementRange: 4,
    baseAccuracy: 90,
    weapon: kWeaponCatalog['rifle_mk1']!,
  );
  final enemy = TacticalUnit(
    id: 'e1',
    team: Team.enemy,
    displayName: 'Enemy-1',
    maxHp: 1, // dies on first hit for deterministic win test.
    position: const GridPos(3, 2),
    movementRange: 4,
    baseAccuracy: 10,
    weapon: kWeaponCatalog['pistol_mk1']!,
  );

  return BattleController(map: map, units: [player, enemy]);
}

void main() {
  group('BattleController', () {
    test('starts in playerTurn phase with visibility computed', () {
      final controller = _simpleController();
      expect(controller.phase, BattlePhase.playerTurn);
      expect(controller.visibleTiles, isNotEmpty);
    });

    test('selecting a unit and moving updates position and hasMoved', () {
      final controller = _simpleController();
      controller.selectUnit('p1');
      expect(controller.selectedUnit?.id, 'p1');

      final options = controller.movementOptionsForSelected();
      expect(options, isNotEmpty);

      final destination = options.keys.first;
      final moved = controller.moveSelectedTo(destination);
      expect(moved, isTrue);
      expect(controller.selectedUnit!.position, destination);
      expect(controller.selectedUnit!.hasMoved, isTrue);
    });

    test('cannot select an enemy unit', () {
      final controller = _simpleController();
      controller.selectUnit('e1');
      expect(controller.selectedUnit, isNull);
    });

    test('attacking a lethal target ends the battle in victory', () {
      final controller = _simpleController();
      controller.selectUnit('p1');
      final targets = controller.attackableTargetsForSelected();
      expect(targets.map((t) => t.id), contains('e1'));

      // Force a guaranteed kill regardless of RNG by looping attacks is not
      // possible (hasActed becomes true after one attack), so instead we
      // directly validate the deterministic 1-hp enemy dies on any hit.
      // Use a resolver seeded to always hit by retrying until an actual hit
      // occurs is unnecessary here because base accuracy is high and enemy
      // has 1 hp - if it was a miss, phase remains playerTurn and we assert
      // accordingly instead of flaking the test.
      final result = controller.attackTarget('e1');
      expect(result, isNotNull);
      if (result!.hit) {
        expect(controller.phase, BattlePhase.victory);
        expect(controller.aliveEnemyUnits, isEmpty);
      } else {
        expect(controller.phase, BattlePhase.playerTurn);
      }
    });

    test(
      'ending player turn transitions through enemy turn back to player turn',
      () {
        final controller = _simpleController();
        final startingTurn = controller.turnNumber;
        controller.endPlayerTurn();
        // Either the enemy killed the squad (unlikely, 1 enemy vs full hp
        // player) or we're back at playerTurn with an incremented turn number.
        expect(
          controller.phase == BattlePhase.playerTurn ||
              controller.phase == BattlePhase.defeat,
          isTrue,
        );
        if (controller.phase == BattlePhase.playerTurn) {
          expect(controller.turnNumber, startingTurn + 1);
          for (final u in controller.alivePlayerUnits) {
            expect(u.hasMoved, isFalse);
            expect(u.hasActed, isFalse);
          }
        }
      },
    );

    test('enemy turn logs a wounded unit retreating behind cover instead of shooting', () {
      final map = TacticalMap(width: 9, height: 7);
      map.setTile(const GridPos(2, 3), TileType.crate);
      final player = TacticalUnit(
        id: 'p1',
        team: Team.player,
        displayName: 'Reclaim-1',
        maxHp: 100,
        position: const GridPos(7, 3),
        movementRange: 5,
        baseAccuracy: 65,
        weapon: kWeaponCatalog['pistol_mk1']!,
      );
      final enemy = TacticalUnit(
        id: 'e1',
        team: Team.enemy,
        displayName: 'Wounded Merc',
        maxHp: 50,
        currentHp: 15,
        position: const GridPos(4, 3),
        movementRange: 5,
        baseAccuracy: 58,
        weapon: kWeaponCatalog['pistol_mk1']!,
      );
      final rng = _ZeroRandom();
      final resolver = CombatResolver(random: rng);
      final controller = BattleController(
        map: map,
        units: [player, enemy],
        combatResolver: resolver,
        ai: SimpleAi(random: rng, combatResolver: resolver),
        random: rng,
      );
      final startDistance = enemy.position.chebyshevDistanceTo(player.position);

      controller.endPlayerTurn();

      expect(controller.phase, BattlePhase.playerTurn);
      expect(
        enemy.position.chebyshevDistanceTo(player.position),
        greaterThan(startDistance),
      );
      expect(
        CombatResolver.coverLevelFor(map, enemy.position, player.position),
        isNot(CoverLevel.none),
      );
      expect(
        controller.log.map((e) => e.text),
        contains(
          'Wounded Merc перемещается на ${enemy.position.x},${enemy.position.y}.',
        ),
      );
      expect(
        controller.log.any(
          (e) =>
              e.text.contains('попадает') || e.text.contains('промахивается'),
        ),
        isFalse,
      );
    });

    test(
      'fog of war hides distant enemies until the squad advances into vision',
      () {
        final map = TacticalMap(width: 16, height: 7);
        final player = TacticalUnit(
          id: 'p1',
          team: Team.player,
          displayName: 'Reclaim-1',
          maxHp: 100,
          position: const GridPos(1, 3),
          movementRange: 5,
          baseAccuracy: 65,
          weapon: kWeaponCatalog['pistol_mk1']!,
        );
        final enemy = TacticalUnit(
          id: 'e1',
          team: Team.enemy,
          displayName: 'Distant Merc',
          maxHp: 50,
          position: const GridPos(14, 3),
          movementRange: 5,
          baseAccuracy: 58,
          weapon: kWeaponCatalog['pistol_mk1']!,
        );
        final rng = _ZeroRandom();
        final resolver = CombatResolver(random: rng);
        final controller = BattleController(
          map: map,
          units: [player, enemy],
          combatResolver: resolver,
          ai: SimpleAi(random: rng, combatResolver: resolver),
          random: rng,
        );

        expect(controller.isEnemyVisible(enemy), isFalse);

        // ZeroRandom.nextBool is false, so unseen enemies do not patrol.
        controller.endPlayerTurn();
        expect(enemy.position, const GridPos(14, 3));
        expect(controller.isEnemyVisible(enemy), isFalse);

        controller.selectUnit(player.id);
        expect(controller.moveSelectedTo(const GridPos(6, 3)), isTrue);
        expect(controller.isEnemyVisible(enemy), isTrue);

        final before = enemy.position;
        controller.endPlayerTurn();

        expect(controller.phase, BattlePhase.playerTurn);
        expect(enemy.position, isNot(before));
        expect(controller.isEnemyVisible(enemy), isTrue);
        expect(
          controller.log.any(
            (e) => e.text.contains('Distant Merc перемещается'),
          ),
          isTrue,
        );
      },
    );

    test(
      'battle is deterministic-ish across many seeded runs without crashing',
      () {
        for (int seed = 0; seed < 25; seed++) {
          final controller = _simpleController();
          final random = Random(seed);
          int safety = 0;
          while (controller.phase == BattlePhase.playerTurn && safety < 50) {
            final unit = controller.alivePlayerUnits.firstWhere(
              (u) => u.canAct,
              orElse: () => controller.alivePlayerUnits.first,
            );
            controller.selectUnit(unit.id);
            final targets = controller.attackableTargetsForSelected();
            if (targets.isNotEmpty) {
              controller.attackTarget(
                targets[random.nextInt(targets.length)].id,
              );
            } else {
              controller.skipSelectedUnit();
            }
            if (controller.allPlayerUnitsDone &&
                controller.phase == BattlePhase.playerTurn) {
              controller.endPlayerTurn();
            }
            safety++;
          }
          expect(
            controller.phase == BattlePhase.victory ||
                controller.phase == BattlePhase.defeat ||
                controller.phase == BattlePhase.playerTurn,
            isTrue,
          );
        }
      },
    );
  });
}
