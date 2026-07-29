import 'dart:math';

import 'package:blackwire_protocol/data/content/equipment_catalog.dart';
import 'package:blackwire_protocol/game/ai/simple_ai.dart';
import 'package:blackwire_protocol/game/battle_controller.dart';
import 'package:blackwire_protocol/game/combat/combat_resolver.dart';
import 'package:blackwire_protocol/game/map/tactical_map.dart';
import 'package:blackwire_protocol/game/map/tile.dart';
import 'package:blackwire_protocol/game/units/tactical_unit.dart';
import 'package:flutter_test/flutter_test.dart';

/// Always returns 0: guarantees combat hits/crits and, for panic rolls,
/// guarantees both a failed Will check (roll 0 < any positive panic chance)
/// and a deterministic "lose turn" panic effect (nextInt(3) == 0).
class _AlwaysZeroRandom implements Random {
  @override
  int nextInt(int max) => 0;
  @override
  double nextDouble() => 0;
  @override
  bool nextBool() => false;
}

/// Never triggers panic (roll always at the top of the range) and never
/// rolls a hit either, used to keep unrelated units' combat rolls inert.
class _AlwaysMaxRandom implements Random {
  @override
  int nextInt(int max) => max - 1;
  @override
  double nextDouble() => 0.999;
  @override
  bool nextBool() => true;
}

void main() {
  group('BattleController panic mechanic', () {
    test('ally death within line of sight can trigger a panic check', () {
      final map = TacticalMap(width: 8, height: 8);
      final doomedAlly = TacticalUnit(
        id: 'p_doomed',
        team: Team.player,
        displayName: 'Doomed',
        maxHp: 1,
        position: const GridPos(3, 3),
        movementRange: 5,
        baseAccuracy: 10,
        weapon: kWeaponCatalog['pistol_mk1']!,
      );
      final witness = TacticalUnit(
        id: 'p_witness',
        team: Team.player,
        displayName: 'Witness',
        maxHp: 100,
        position: const GridPos(3, 4),
        movementRange: 5,
        baseAccuracy: 65,
        weapon: kWeaponCatalog['pistol_mk1']!,
        willpower: 50,
      );
      // No enemyFactionId set -> SimpleAi treats it as having no fear
      // attack, isolating this test to the ally-death panic trigger only.
      final enemy = TacticalUnit(
        id: 'e1',
        team: Team.enemy,
        displayName: 'Enemy',
        maxHp: 50,
        position: const GridPos(3, 2),
        movementRange: 4,
        baseAccuracy: 90,
        weapon: kWeaponCatalog['rifle_mk1']!,
      );

      final controller = BattleController(
        map: map,
        units: [doomedAlly, witness, enemy],
        ai: SimpleAi(
          combatResolver: CombatResolver(random: _AlwaysZeroRandom()),
        ),
        random: _AlwaysZeroRandom(),
      );

      controller.endPlayerTurn();

      expect(doomedAlly.isAlive, isFalse);
      expect(controller.phase, BattlePhase.playerTurn);
      // The witness had line of sight to the doomed ally and, with the
      // always-zero RNG, must have failed the Will check and immediately
      // suffered the (deterministic) "lose turn" panic effect for this new
      // player turn.
      expect(witness.hasMoved, isTrue);
      expect(witness.hasActed, isTrue);
      expect(
        controller.log.any(
          (e) => e.text.contains('панике') || e.text.contains('паники'),
        ),
        isTrue,
      );
    });

    test(
      'a unit with very high willpower resists panic even on a death nearby',
      () {
        final map = TacticalMap(width: 8, height: 8);
        final doomedAlly = TacticalUnit(
          id: 'p_doomed',
          team: Team.player,
          displayName: 'Doomed',
          maxHp: 1,
          position: const GridPos(3, 3),
          movementRange: 5,
          baseAccuracy: 10,
          weapon: kWeaponCatalog['pistol_mk1']!,
        );
        final steady = TacticalUnit(
          id: 'p_steady',
          team: Team.player,
          displayName: 'Steady',
          maxHp: 100,
          position: const GridPos(3, 4),
          movementRange: 5,
          baseAccuracy: 65,
          weapon: kWeaponCatalog['pistol_mk1']!,
          willpower: 200, // panic chance clamps to the 5% floor.
        );
        final enemy = TacticalUnit(
          id: 'e1',
          team: Team.enemy,
          displayName: 'Enemy',
          maxHp: 50,
          position: const GridPos(3, 2),
          movementRange: 4,
          baseAccuracy: 90,
          weapon: kWeaponCatalog['rifle_mk1']!,
        );

        final controller = BattleController(
          map: map,
          units: [doomedAlly, steady, enemy],
          ai: SimpleAi(
            combatResolver: CombatResolver(random: _AlwaysZeroRandom()),
          ),
          random: _AlwaysMaxRandom(), // roll always the highest possible value.
        );

        controller.endPlayerTurn();

        expect(doomedAlly.isAlive, isFalse);
        // A max roll can never be below any panic chance (max 95%), so the
        // steady soldier must not have panicked.
        expect(steady.hasMoved, isFalse);
        expect(steady.hasActed, isFalse);
      },
    );
  });
}
