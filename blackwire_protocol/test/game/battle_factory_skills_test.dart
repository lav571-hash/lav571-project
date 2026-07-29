import 'package:blackwire_protocol/data/models/faction.dart';
import 'package:blackwire_protocol/data/models/soldier.dart';
import 'package:blackwire_protocol/data/models/specialization.dart';
import 'package:blackwire_protocol/game/battle_factory.dart';
import 'package:blackwire_protocol/game/units/tactical_unit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BattleFactory applies soldier skill bonuses to tactical units', () {
    test('a soldier with picked skills gets boosted combat stats', () {
      const baseline = Soldier(
        id: 's1',
        name: 'Baseline',
        maxHp: 100,
        baseAccuracy: 65,
        movementRange: 5,
        willpower: 50,
      );
      final upgraded = baseline.copyWith(
        specialization: Specialization.heavy,
        unlockedSkillIds: [
          'heavy_gen_hp', // +5 hp
          'heavy_gen_armor', // +1 damage reduction
          'heavy_sig_bulwark', // +10 hp
        ],
      );

      final baselineBattle = BattleFactory.createMission(
        squad: [baseline],
        factionId: EnemyFactionId.titanDynamics,
        difficulty: 1,
      );
      final upgradedBattle = BattleFactory.createMission(
        squad: [upgraded],
        factionId: EnemyFactionId.titanDynamics,
        difficulty: 1,
      );

      final baselineUnit = baselineBattle.units.firstWhere(
        (u) => u.team == Team.player,
      );
      final upgradedUnit = upgradedBattle.units.firstWhere(
        (u) => u.team == Team.player,
      );

      expect(upgradedUnit.maxHp, baselineUnit.maxHp + 15);
      expect(upgradedUnit.damageReduction, baselineUnit.damageReduction + 1);
    });

    test(
      'accuracy, movement, crit and will skill bonuses all carry through',
      () {
        const soldier = Soldier(
          id: 's2',
          name: 'Sniper',
          baseAccuracy: 60,
          movementRange: 4,
          willpower: 50,
        );
        final withSkills = soldier.copyWith(
          specialization: Specialization.sniper,
          unlockedSkillIds: ['sniper_gen_accuracy', 'sniper_sig_deadeye'],
        );

        final battle = BattleFactory.createMission(
          squad: [withSkills],
          factionId: EnemyFactionId.nexusRobotics,
          difficulty: 1,
        );
        final unit = battle.units.firstWhere((u) => u.team == Team.player);

        expect(unit.baseAccuracy, 60 + 2);
        expect(unit.critChance, 12);
      },
    );
  });
}
