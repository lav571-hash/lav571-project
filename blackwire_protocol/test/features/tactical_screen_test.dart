import 'dart:math';

import 'package:blackwire_protocol/core/constants.dart';
import 'package:blackwire_protocol/data/content/equipment_catalog.dart';
import 'package:blackwire_protocol/data/models/faction.dart';
import 'package:blackwire_protocol/data/models/mission_site.dart';
import 'package:blackwire_protocol/features/tactical/tactical_screen.dart';
import 'package:blackwire_protocol/game/ai/simple_ai.dart';
import 'package:blackwire_protocol/game/battle_controller.dart';
import 'package:blackwire_protocol/game/combat/combat_resolver.dart';
import 'package:blackwire_protocol/game/map/tactical_map.dart';
import 'package:blackwire_protocol/game/map/tile.dart';
import 'package:blackwire_protocol/game/units/tactical_unit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _ZeroRandom implements Random {
  @override
  bool nextBool() => false;
  @override
  double nextDouble() => 0;
  @override
  int nextInt(int max) => 0;
}

/// [TacticalScreen] hosts a Flame [GameWidget] with a continuously running
/// game loop ticker, so `pumpAndSettle` never settles on it. Use a bounded
/// number of frame pumps instead.
Future<void> _pumpFrames(WidgetTester tester, {int times = 6}) async {
  for (var i = 0; i < times; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

MissionSite _mission() => const MissionSite(
  id: 'm1',
  factionId: EnemyFactionId.titanDynamics,
  type: MissionType.raid,
  regionName: 'Test Sector',
  x: 0.5,
  y: 0.5,
  difficulty: 1,
  secondsRemaining: 100,
  totalLifetimeSeconds: 100,
);

TacticalUnit _playerUnit({int hp = 100}) => TacticalUnit(
  id: 'p1',
  team: Team.player,
  displayName: 'Reclaim-1',
  maxHp: 100,
  position: const GridPos(1, 1),
  movementRange: 5,
  baseAccuracy: 65,
  weapon: kWeaponCatalog['pistol_mk1']!,
  currentHp: hp,
);

void main() {
  testWidgets(
    'renders mission info and turn indicator before the battle concludes',
    (tester) async {
      final map = TacticalMap(width: 6, height: 6);
      final enemy = TacticalUnit(
        id: 'e1',
        team: Team.enemy,
        displayName: 'Test Merc',
        maxHp: 50,
        position: const GridPos(4, 1),
        movementRange: 4,
        baseAccuracy: 10,
        weapon: kWeaponCatalog['pistol_mk1']!,
      );
      final controller = BattleController(
        map: map,
        units: [_playerUnit(), enemy],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                Navigator.of(context).push<BattleController>(
                  MaterialPageRoute(
                    builder: (_) => TacticalScreen(
                      controller: controller,
                      mission: _mission(),
                    ),
                  ),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await _pumpFrames(tester);

      // Turn indicator and mission info render correctly.
      expect(find.textContaining('Test Sector'), findsOneWidget);
      expect(find.textContaining('ХОД 1'), findsOneWidget);

      // No overlay yet since the battle has not concluded.
      expect(find.text('МИССИЯ ВЫПОЛНЕНА'), findsNothing);
    },
  );

  testWidgets(
    'victory overlay appears and returning navigates back with the controller',
    (tester) async {
      final map = TacticalMap(width: 6, height: 6);
      final enemy = TacticalUnit(
        id: 'e1',
        team: Team.enemy,
        displayName: 'Test Merc',
        maxHp: 1,
        position: const GridPos(2, 1),
        movementRange: 4,
        baseAccuracy: 10,
        weapon: kWeaponCatalog['pistol_mk1']!,
        currentHp: 0, // already dead.
      );
      final controller = BattleController(
        map: map,
        units: [_playerUnit(), enemy],
      );

      // The enemy is already dead (currentHp: 0), so ending the player's turn
      // triggers the same win-condition check the real game runs after every
      // kill, and the battle should resolve to victory immediately.
      controller.endPlayerTurn();
      expect(controller.phase, BattlePhase.victory);

      BattleController? poppedResult;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                poppedResult = await Navigator.of(context)
                    .push<BattleController>(
                      MaterialPageRoute(
                        builder: (_) => TacticalScreen(
                          controller: controller,
                          mission: _mission(),
                        ),
                      ),
                    );
              },
              child: const Text('open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await _pumpFrames(tester);

      expect(find.text('МИССИЯ ВЫПОЛНЕНА'), findsOneWidget);

      await tester.tap(find.text('ВЕРНУТЬСЯ НА БАЗУ'));
      await _pumpFrames(tester);

      expect(poppedResult, same(controller));
    },
  );

  testWidgets(
    'ending the player turn surfaces enemy retreat movement in the combat log',
    (tester) async {
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

      await tester.pumpWidget(
        MaterialApp(
          home: TacticalScreen(controller: controller, mission: _mission()),
        ),
      );
      await _pumpFrames(tester);

      await tester.tap(find.text('ЗАКОНЧИТЬ ХОД'));
      await _pumpFrames(tester, times: 8);

      expect(find.textContaining('ХОД 2'), findsOneWidget);
      expect(
        find.textContaining('Wounded Merc перемещается на'),
        findsOneWidget,
      );
    },
  );

  testWidgets('technician HUD hacks a Nexus droid and shows the combat log', (
    tester,
  ) async {
    final tech = TacticalUnit(
      id: 'tech',
      team: Team.player,
      displayName: 'Wire',
      maxHp: 100,
      position: const GridPos(2, 2),
      movementRange: 5,
      baseAccuracy: 65,
      weapon: kWeaponCatalog['pistol_mk1']!,
      skillIds: const [GameConfig.hackSkillId, GameConfig.turretSkillId],
    );
    final droid = TacticalUnit(
      id: 'droid',
      team: Team.enemy,
      displayName: 'Боевой дроид #1',
      maxHp: 50,
      position: const GridPos(4, 2),
      movementRange: 4,
      baseAccuracy: 54,
      weapon: kWeaponCatalog['pistol_mk1']!,
      enemyFactionId: EnemyFactionId.nexusRobotics,
    );
    final controller = BattleController(
      map: TacticalMap(width: 8, height: 6),
      units: [tech, droid],
    );
    controller.selectUnit(tech.id);

    await tester.pumpWidget(
      MaterialApp(
        home: TacticalScreen(controller: controller, mission: _mission()),
      ),
    );
    await _pumpFrames(tester);

    expect(find.text('Взломать'), findsOneWidget);
    expect(find.text('Турель'), findsOneWidget);

    await tester.tap(find.text('Взломать'));
    await _pumpFrames(tester);

    expect(find.textContaining('взламывает'), findsOneWidget);
    expect(find.text('МИССИЯ ВЫПОЛНЕНА'), findsOneWidget);
  });
}
