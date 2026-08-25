import '../models/skill.dart';
import '../models/specialization.dart';

/// Skill catalog for BLACKWIRE PROTOCOL's rank-up system.
///
/// Each specialization has two repeatable "generic" skills that can be
/// picked again at every rank-up, plus two one-time "signature" skills
/// unlocked only at the Rank 5 and Rank 10 milestones. This keeps the
/// content set small and hand-tunable while still giving every one of the
/// 9 rank-up choices (Ranks 2-10) real mechanical weight.
///
/// Technician signatures also unlock battlefield actions (hack a Nexus
/// droid / deploy a turret). Grenade and stim research abilities remain
/// unused and are still a follow-up.
class SkillCatalog {
  SkillCatalog._();

  static const Map<Specialization, List<SkillDef>> _genericPairs = {
    Specialization.assault: [
      SkillDef(
        id: 'assault_gen_accuracy',
        name: 'Свирепость',
        description: '+2 к меткости.',
        specialization: Specialization.assault,
        effect: SkillEffect(SkillEffectType.accuracy, 2),
      ),
      SkillDef(
        id: 'assault_gen_mobility',
        name: 'Прыть',
        description: '+1 клетка движения.',
        specialization: Specialization.assault,
        effect: SkillEffect(SkillEffectType.movement, 1),
      ),
    ],
    Specialization.sniper: [
      SkillDef(
        id: 'sniper_gen_accuracy',
        name: 'Твёрдая рука',
        description: '+2 к меткости.',
        specialization: Specialization.sniper,
        effect: SkillEffect(SkillEffectType.accuracy, 2),
      ),
      SkillDef(
        id: 'sniper_gen_damage',
        name: 'Убойность',
        description: '+2 к урону оружия.',
        specialization: Specialization.sniper,
        effect: SkillEffect(SkillEffectType.weaponDamage, 2),
      ),
    ],
    Specialization.heavy: [
      SkillDef(
        id: 'heavy_gen_hp',
        name: 'Стойкость',
        description: '+5 к максимальному HP.',
        specialization: Specialization.heavy,
        effect: SkillEffect(SkillEffectType.hp, 5),
      ),
      SkillDef(
        id: 'heavy_gen_armor',
        name: 'Бронеплиты',
        description: '+1 к снижению получаемого урона.',
        specialization: Specialization.heavy,
        effect: SkillEffect(SkillEffectType.damageReduction, 1),
      ),
    ],
    Specialization.medic: [
      SkillDef(
        id: 'medic_gen_will',
        name: 'Хладнокровие',
        description: '+3 к психике.',
        specialization: Specialization.medic,
        effect: SkillEffect(SkillEffectType.will, 3),
      ),
      SkillDef(
        id: 'medic_gen_hp',
        name: 'Забота о себе',
        description: '+4 к максимальному HP.',
        specialization: Specialization.medic,
        effect: SkillEffect(SkillEffectType.hp, 4),
      ),
    ],
    Specialization.technician: [
      SkillDef(
        id: 'tech_gen_focus',
        name: 'Хладный расчёт',
        description: '+2 к психике.',
        specialization: Specialization.technician,
        effect: SkillEffect(SkillEffectType.will, 2),
      ),
      SkillDef(
        id: 'tech_gen_firepower',
        name: 'Модуль турели',
        description: '+2 к урону оружия.',
        specialization: Specialization.technician,
        effect: SkillEffect(SkillEffectType.weaponDamage, 2),
      ),
    ],
  };

  static const Map<Specialization, SkillDef> _signatureAtRank5 = {
    Specialization.assault: SkillDef(
      id: 'assault_sig_flank',
      name: 'Инстинкт фланга',
      description:
          '+3 к урону оружия. Раз за бой: натиск в упор — атака в обход укрытия цели.',
      specialization: Specialization.assault,
      effect: SkillEffect(SkillEffectType.weaponDamage, 3),
      repeatable: false,
    ),
    Specialization.sniper: SkillDef(
      id: 'sniper_sig_range',
      name: 'Дальний прицел',
      description:
          '+2 к дальности оружия. Раз за бой: прицельный выстрел без движения — +25 к меткости и +8 к урону.',
      specialization: Specialization.sniper,
      effect: SkillEffect(SkillEffectType.weaponRange, 2),
      repeatable: false,
    ),
    Specialization.heavy: SkillDef(
      id: 'heavy_sig_bulwark',
      name: 'Оплот',
      description:
          '+10 к максимальному HP. Раз за бой: подавляющий огонь — цель не наступает и стреляет с −25 к меткости.',
      specialization: Specialization.heavy,
      effect: SkillEffect(SkillEffectType.hp, 10),
      repeatable: false,
    ),
    Specialization.medic: SkillDef(
      id: 'medic_sig_calm',
      name: 'Спокойствие духа',
      description:
          '+6 к психике. Раз за бой: полевое лечение соседнего бойца на 25 HP; боец в панике снова может двигаться.',
      specialization: Specialization.medic,
      effect: SkillEffect(SkillEffectType.will, 6),
      repeatable: false,
    ),
    Specialization.technician: SkillDef(
      id: 'tech_sig_hack',
      name: 'Протокол взлома',
      description: '+4 к меткости. Раз за бой: взломать видимого боевого дроида Nexus — он переходит под контроль отряда.',
      specialization: Specialization.technician,
      effect: SkillEffect(SkillEffectType.accuracy, 4),
      repeatable: false,
    ),
  };

  static const Map<Specialization, SkillDef> _signatureAtRank10 = {
    Specialization.assault: SkillDef(
      id: 'assault_sig_storm',
      name: 'Клинок бури',
      description: '+8% к шансу критического удара.',
      specialization: Specialization.assault,
      effect: SkillEffect(SkillEffectType.critChance, 8),
      repeatable: false,
    ),
    Specialization.sniper: SkillDef(
      id: 'sniper_sig_deadeye',
      name: 'Мёртвый глаз',
      description: '+12% к шансу критического удара.',
      specialization: Specialization.sniper,
      effect: SkillEffect(SkillEffectType.critChance, 12),
      repeatable: false,
    ),
    Specialization.heavy: SkillDef(
      id: 'heavy_sig_unbreakable',
      name: 'Несокрушимый',
      description: '+3 к снижению получаемого урона.',
      specialization: Specialization.heavy,
      effect: SkillEffect(SkillEffectType.damageReduction, 3),
      repeatable: false,
    ),
    Specialization.medic: SkillDef(
      id: 'medic_sig_guardian',
      name: 'Ангел-хранитель',
      description: '+10 к психике.',
      specialization: Specialization.medic,
      effect: SkillEffect(SkillEffectType.will, 10),
      repeatable: false,
    ),
    Specialization.technician: SkillDef(
      id: 'tech_sig_drone',
      name: 'Боевой дрон',
      description: '+5 к урону оружия. Раз за бой: развернуть турель на соседней клетке; она стреляет в конце хода отряда.',
      specialization: Specialization.technician,
      effect: SkillEffect(SkillEffectType.weaponDamage, 5),
      repeatable: false,
    ),
  };

  /// All skill defs, keyed by id - used to resolve a soldier's already
  /// picked skill ids back into their effects.
  static final Map<String, SkillDef> all = {
    for (final list in _genericPairs.values)
      for (final s in list) s.id: s,
    for (final s in _signatureAtRank5.values) s.id: s,
    for (final s in _signatureAtRank10.values) s.id: s,
  };

  /// Returns the 2 skill choices offered when [specialization] reaches
  /// [rank] (rank must be 2-10). Ranks 5 and 10 swap in a one-time
  /// signature skill alongside one of the generic picks.
  static List<SkillDef> choicesForRank(
    Specialization specialization,
    int rank,
  ) {
    final generic = _genericPairs[specialization]!;
    if (rank == 5) {
      return [_signatureAtRank5[specialization]!, generic[1]];
    }
    if (rank == 10) {
      return [_signatureAtRank10[specialization]!, generic[0]];
    }
    return generic;
  }
}
