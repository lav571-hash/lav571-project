import 'dart:math';

import '../core/constants.dart';
import '../data/content/equipment_catalog.dart';
import '../data/models/faction.dart';
import '../data/models/soldier.dart';
import 'battle_controller.dart';
import 'map/map_generator.dart';
import 'map/tile.dart';
import 'units/enemy_defs.dart';
import 'units/tactical_unit.dart';

/// Builds a ready-to-play [BattleController] for a mission against
/// [factionId] soldiers drawn from the player's roster, scaled by
/// [difficulty] (1-5).
class BattleFactory {
  static BattleController createMission({
    required List<Soldier> squad,
    required EnemyFactionId factionId,
    required int difficulty,
    Random? random,
  }) {
    final rng = random ?? Random();
    final generator = MapGenerator(random: rng);
    final map = generator.generate(
      width: GameConfig.defaultMapWidth,
      height: GameConfig.defaultMapHeight,
    );

    final playerSpawns = generator.spawnPositions(
      map,
      west: true,
      count: squad.length,
    );
    final enemyCount = (1 + difficulty).clamp(2, 6);
    final enemySpawns = generator.spawnPositions(
      map,
      west: false,
      count: enemyCount,
    );

    final units = <TacticalUnit>[];

    for (int i = 0; i < squad.length; i++) {
      final soldier = squad[i];
      final weapon =
          kWeaponCatalog[soldier.weaponId] ?? kWeaponCatalog['pistol_mk1']!;
      final armor = soldier.armorId != null
          ? kArmorCatalog[soldier.armorId]
          : null;
      final bonuses = soldier.skillBonuses;
      units.add(
        TacticalUnit(
          id: 'unit_${soldier.id}',
          team: Team.player,
          displayName: soldier.name,
          maxHp: soldier.maxHp + (armor?.bonusHp ?? 0) + bonuses.hp,
          position: i < playerSpawns.length ? playerSpawns[i] : GridPos(1, 1),
          movementRange: soldier.movementRange + bonuses.movement,
          baseAccuracy: soldier.baseAccuracy + bonuses.accuracy,
          weapon: weapon,
          damageReduction:
              (armor?.damageReduction ?? 0) + bonuses.damageReduction,
          weaponDamageBonus: bonuses.weaponDamage,
          weaponRangeBonus: bonuses.weaponRange,
          critChance: bonuses.critChance,
          willpower: soldier.willpower + bonuses.will,
          soldierId: soldier.id,
        ),
      );
    }

    final enemyDef = kEnemyDefs[factionId]!;
    for (int i = 0; i < enemySpawns.length; i++) {
      final hpBonus = (difficulty - 1) * 4;
      units.add(
        TacticalUnit(
          id: 'enemy_${factionId.name}_$i',
          team: Team.enemy,
          displayName: '${enemyDef.name} #${i + 1}',
          maxHp: enemyDef.maxHp + hpBonus,
          position: enemySpawns[i],
          movementRange: enemyDef.movementRange,
          baseAccuracy: enemyDef.baseAccuracy,
          weapon: enemyDef.weapon,
          damageReduction: enemyDef.damageReduction,
          enemyFactionId: factionId,
        ),
      );
    }

    return BattleController(map: map, units: units);
  }
}
