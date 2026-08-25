/// Static definition of a weapon. Weapons are unlocked via research and
/// crafted in the Workshop.
class WeaponDef {
  final String id;
  final String name;
  final int tier;
  final int minDamage;
  final int maxDamage;
  final int range;
  final int baseAccuracy; // percent
  final int apCost; // reserved for future TU-style systems.

  const WeaponDef({
    required this.id,
    required this.name,
    required this.tier,
    required this.minDamage,
    required this.maxDamage,
    required this.range,
    required this.baseAccuracy,
    this.apCost = 1,
  });
}

/// Static definition of armor. Reduces incoming damage.
class ArmorDef {
  final String id;
  final String name;
  final int tier;
  final int damageReduction;
  final int bonusHp;

  const ArmorDef({
    required this.id,
    required this.name,
    required this.tier,
    required this.damageReduction,
    required this.bonusHp,
  });
}

/// A passive/active ability granted by an implant/grenade unlocked via
/// research (e.g. frag grenade, combat stim).
class AbilityDef {
  final String id;
  final String name;
  final String description;

  const AbilityDef({
    required this.id,
    required this.name,
    required this.description,
  });
}
