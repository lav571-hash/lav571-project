import '../../core/constants.dart';
import '../../data/content/equipment_catalog.dart';
import '../../data/models/equipment.dart';
import '../../data/models/faction.dart';

/// Base stat block for an enemy archetype belonging to a faction. Stats are
/// mildly scaled by mission difficulty (1-5) when instantiated.
///
/// Each faction has one signature "fear attack": after a normal shot, the
/// enemy has a [fearAttackChance] chance to trigger it, forcing a Will check
/// (see `BattleController`) on nearby player units.
class EnemyDef {
  final EnemyFactionId factionId;
  final String name;
  final int maxHp;
  final int movementRange;
  final int baseAccuracy;
  final WeaponDef weapon;
  final int damageReduction;
  final String fearAttackName;
  final double fearAttackChance;
  final int fearAttackRadius;

  const EnemyDef({
    required this.factionId,
    required this.name,
    required this.maxHp,
    required this.movementRange,
    required this.baseAccuracy,
    required this.weapon,
    this.damageReduction = 0,
    required this.fearAttackName,
    this.fearAttackChance = GameConfig.enemyFearAttackChance,
    this.fearAttackRadius = 3,
  });
}

final Map<EnemyFactionId, EnemyDef> kEnemyDefs = {
  EnemyFactionId.titanDynamics: EnemyDef(
    factionId: EnemyFactionId.titanDynamics,
    name: 'PMC-оперативник',
    maxHp: 50,
    movementRange: 5,
    baseAccuracy: 58,
    weapon: kWeaponCatalog['rifle_mk1']!,
    damageReduction: 1,
    fearAttackName: 'Светошумовая граната',
  ),
  EnemyFactionId.nexusRobotics: EnemyDef(
    factionId: EnemyFactionId.nexusRobotics,
    name: 'Боевой дроид',
    maxHp: 55,
    movementRange: 4,
    baseAccuracy: 54,
    weapon: kWeaponCatalog['pistol_mk1']!,
    damageReduction: 2,
    fearAttackName: 'Подавляющий огонь',
  ),
  EnemyFactionId.chimeraLabs: EnemyDef(
    factionId: EnemyFactionId.chimeraLabs,
    name: 'Мутант-биоформ',
    maxHp: 45,
    movementRange: 6,
    baseAccuracy: 48,
    weapon: kWeaponCatalog['smg_arc']!,
    damageReduction: 0,
    fearAttackName: 'Рёв ужаса',
  ),
};
