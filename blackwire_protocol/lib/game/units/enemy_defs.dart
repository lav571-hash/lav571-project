import '../../data/content/equipment_catalog.dart';
import '../../data/models/equipment.dart';
import '../../data/models/faction.dart';

/// Base stat block for an enemy archetype belonging to a faction. Stats are
/// mildly scaled by mission difficulty (1-5) when instantiated.
class EnemyDef {
  final EnemyFactionId factionId;
  final String name;
  final int maxHp;
  final int movementRange;
  final int baseAccuracy;
  final WeaponDef weapon;
  final int damageReduction;

  const EnemyDef({
    required this.factionId,
    required this.name,
    required this.maxHp,
    required this.movementRange,
    required this.baseAccuracy,
    required this.weapon,
    this.damageReduction = 0,
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
  ),
  EnemyFactionId.nexusRobotics: EnemyDef(
    factionId: EnemyFactionId.nexusRobotics,
    name: 'Боевой дроид',
    maxHp: 55,
    movementRange: 4,
    baseAccuracy: 54,
    weapon: kWeaponCatalog['pistol_mk1']!,
    damageReduction: 2,
  ),
  EnemyFactionId.chimeraLabs: EnemyDef(
    factionId: EnemyFactionId.chimeraLabs,
    name: 'Мутант-биоформ',
    maxHp: 45,
    movementRange: 6,
    baseAccuracy: 48,
    weapon: kWeaponCatalog['smg_arc']!,
    damageReduction: 0,
  ),
};
