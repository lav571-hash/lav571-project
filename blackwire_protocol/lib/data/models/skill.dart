import 'specialization.dart';

/// The kinds of mechanical effects a skill can grant. Kept intentionally
/// simple (flat stat modifiers) so every skill choice has a real, testable
/// impact on combat without requiring bespoke new tactical mechanics.
enum SkillEffectType {
  hp,
  accuracy,
  movement,
  will,
  damageReduction,
  weaponDamage,
  weaponRange,
  critChance,
}

class SkillEffect {
  final SkillEffectType type;
  final int value;

  const SkillEffect(this.type, this.value);
}

/// A single skill offered as a rank-up choice. [repeatable] skills can be
/// picked again at a later rank-up (their effect stacks); signature skills
/// tied to a specific milestone rank are one-time picks.
class SkillDef {
  final String id;
  final String name;
  final String description;
  final Specialization specialization;
  final SkillEffect effect;
  final bool repeatable;

  const SkillDef({
    required this.id,
    required this.name,
    required this.description,
    required this.specialization,
    required this.effect,
    this.repeatable = true,
  });
}
