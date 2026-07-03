import '../models/equipment.dart';

/// Static catalog of every weapon in the game, keyed by id.
const Map<String, WeaponDef> kWeaponCatalog = {
  'pistol_mk1': WeaponDef(
    id: 'pistol_mk1',
    name: 'Сидевик Mk1 (пистолет)',
    tier: 1,
    minDamage: 16,
    maxDamage: 26,
    range: 6,
    baseAccuracy: 72,
  ),
  'rifle_mk1': WeaponDef(
    id: 'rifle_mk1',
    name: 'Штурмовая винтовка Mk1',
    tier: 1,
    minDamage: 18,
    maxDamage: 28,
    range: 8,
    baseAccuracy: 65,
  ),
  'rifle_mk2': WeaponDef(
    id: 'rifle_mk2',
    name: 'Штурмовая винтовка Mk2 «Пронзатель»',
    tier: 2,
    minDamage: 26,
    maxDamage: 38,
    range: 9,
    baseAccuracy: 68,
  ),
  'smg_arc': WeaponDef(
    id: 'smg_arc',
    name: 'ПП «Дуга» (ЭМ-разряд)',
    tier: 2,
    minDamage: 14,
    maxDamage: 22,
    range: 5,
    baseAccuracy: 78,
  ),
};

const Map<String, ArmorDef> kArmorCatalog = {
  'vest_light': ArmorDef(
    id: 'vest_light',
    name: 'Лёгкий бронежилет',
    tier: 1,
    damageReduction: 2,
    bonusHp: 10,
  ),
  'exo_plate': ArmorDef(
    id: 'exo_plate',
    name: 'Экзо-пластины «Барьер»',
    tier: 2,
    damageReduction: 5,
    bonusHp: 25,
  ),
};

const Map<String, AbilityDef> kAbilityCatalog = {
  'frag_grenade': AbilityDef(
    id: 'frag_grenade',
    name: 'Осколочная граната',
    description: 'Урон по области, игнорирует укрытия цели.',
  ),
  'combat_stim': AbilityDef(
    id: 'combat_stim',
    name: 'Боевой стимулятор',
    description: '+2 клетки движения и +15% меткости на один ход.',
  ),
};
