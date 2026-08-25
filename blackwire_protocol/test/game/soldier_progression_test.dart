import 'package:blackwire_protocol/core/constants.dart';
import 'package:blackwire_protocol/data/content/equipment_catalog.dart';
import 'package:blackwire_protocol/data/models/soldier.dart';
import 'package:blackwire_protocol/game/map/tile.dart';
import 'package:blackwire_protocol/game/soldier_progression.dart';
import 'package:blackwire_protocol/game/units/tactical_unit.dart';
import 'package:flutter_test/flutter_test.dart';

TacticalUnit _unit({int hits = 0, int kills = 0, int shotsFired = 0}) {
  final unit = TacticalUnit(
    id: 'u1',
    team: Team.player,
    displayName: 'Test',
    maxHp: 100,
    position: const GridPos(0, 0),
    movementRange: 5,
    baseAccuracy: 65,
    weapon: kWeaponCatalog['pistol_mk1']!,
  );
  unit.hits = hits;
  unit.kills = kills;
  unit.shotsFired = shotsFired;
  return unit;
}

void main() {
  group('SoldierProgression.computeXp', () {
    test('participation-only mission yields the base XP', () {
      final xp = SoldierProgression.computeXp(_unit());
      expect(xp, GameConfig.xpPerMissionParticipation);
    });

    test('kills and hits add their own XP on top of participation', () {
      final xp = SoldierProgression.computeXp(_unit(hits: 2, kills: 1));
      expect(
        xp,
        GameConfig.xpPerMissionParticipation +
            1 * GameConfig.xpPerKill +
            2 * GameConfig.xpPerHit,
      );
    });
  });

  group('SoldierProgression.applyXpAndRankUp', () {
    test('promotes to rank 1 the moment any XP is earned', () {
      const soldier = Soldier(id: 's1', name: 'Test');
      final result = SoldierProgression.applyXpAndRankUp(soldier, 10);
      expect(result.rank, 1);
      expect(result.xp, 10);
      expect(result.hasPendingSpecializationChoice, isTrue);
    });

    test('can skip multiple rank thresholds in a single big XP gain', () {
      const soldier = Soldier(id: 's1', name: 'Test');
      final result = SoldierProgression.applyXpAndRankUp(soldier, 1000);
      expect(result.rank, GameConfig.maxRank);
    });

    test('never exceeds the maximum rank', () {
      const soldier = Soldier(id: 's1', name: 'Test', rank: 10, xp: 1000);
      final result = SoldierProgression.applyXpAndRankUp(soldier, 500);
      expect(result.rank, GameConfig.maxRank);
    });

    test('does not rank up below the next threshold', () {
      const soldier = Soldier(id: 's1', name: 'Test');
      final result = SoldierProgression.applyXpAndRankUp(soldier, 10);
      // 10 XP < 30 (rank index 1 threshold) so stays at rank 1 (index 0
      // threshold is 0, satisfied immediately), not rank 2.
      expect(result.rank, 1);
    });
  });

  group('SoldierProgression.applyPracticeGrowth', () {
    test('a wound grants a flat HP increase', () {
      const soldier = Soldier(id: 's1', name: 'Test', maxHp: 100);
      final result = SoldierProgression.applyPracticeGrowth(
        soldier,
        _unit(),
        becameWounded: true,
      );
      expect(result.maxHp, 100 + GameConfig.hpGainPerWound);
    });

    test('no wound means no HP growth', () {
      const soldier = Soldier(id: 's1', name: 'Test', maxHp: 100);
      final result = SoldierProgression.applyPracticeGrowth(
        soldier,
        _unit(),
        becameWounded: false,
      );
      expect(result.maxHp, 100);
    });

    test('accuracy grows by the highest shots-fired threshold reached', () {
      const soldier = Soldier(id: 's1', name: 'Test', baseAccuracy: 65);

      final below = SoldierProgression.applyPracticeGrowth(
        soldier,
        _unit(shotsFired: 2),
        becameWounded: false,
      );
      expect(below.baseAccuracy, 65);

      final tier1 = SoldierProgression.applyPracticeGrowth(
        soldier,
        _unit(shotsFired: 3),
        becameWounded: false,
      );
      expect(tier1.baseAccuracy, 66);

      final tier2 = SoldierProgression.applyPracticeGrowth(
        soldier,
        _unit(shotsFired: 9),
        becameWounded: false,
      );
      expect(tier2.baseAccuracy, 67);

      final tier3 = SoldierProgression.applyPracticeGrowth(
        soldier,
        _unit(shotsFired: 27),
        becameWounded: false,
      );
      expect(tier3.baseAccuracy, 68);

      // Thresholds do not stack: reaching 27 is still a single +3, not
      // +1 +2 +3.
      final tier3Again = SoldierProgression.applyPracticeGrowth(
        soldier,
        _unit(shotsFired: 100),
        becameWounded: false,
      );
      expect(tier3Again.baseAccuracy, 68);
    });

    test('movement grows every 5 missions survived, capped at +3', () {
      var soldier = const Soldier(id: 's1', name: 'Test', movementRange: 5);
      for (var mission = 1; mission <= 25; mission++) {
        soldier = soldier.copyWith(missionsSurvived: mission);
        soldier = SoldierProgression.applyPracticeGrowth(
          soldier,
          _unit(),
          becameWounded: false,
        );
      }
      // 25 missions / 5 = 5 potential triggers, capped at 3 bonus stacks.
      expect(soldier.movementBonusStacks, GameConfig.maxMovementBonusStacks);
      expect(soldier.movementRange, 5 + GameConfig.maxMovementBonusStacks);
    });

    test(
      'willpower grows by 1 per 3 cumulative successful actions, carrying remainder',
      () {
        var soldier = const Soldier(id: 's1', name: 'Test', willpower: 50);

        soldier = SoldierProgression.applyPracticeGrowth(
          soldier,
          _unit(hits: 2),
          becameWounded: false,
        );
        expect(soldier.willpower, 50);
        expect(soldier.willProgressCounter, 2);

        soldier = SoldierProgression.applyPracticeGrowth(
          soldier,
          _unit(hits: 1),
          becameWounded: false,
        );
        expect(soldier.willpower, 51);
        expect(soldier.willProgressCounter, 0);

        soldier = SoldierProgression.applyPracticeGrowth(
          soldier,
          _unit(kills: 7),
          becameWounded: false,
        );
        expect(soldier.willpower, 51 + 2);
        expect(soldier.willProgressCounter, 1);
      },
    );
  });
}
