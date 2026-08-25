import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../data/models/skill.dart';
import '../../data/models/soldier.dart';
import '../../data/models/specialization.dart';
import '../../state/game_state_notifier.dart';

/// Shows the appropriate rank-up dialog for [soldier]: a specialization
/// pick at Rank 1, or a skill pick at Ranks 2-10.
Future<void> showPromotionDialog(
  BuildContext context,
  WidgetRef ref,
  Soldier soldier,
) {
  if (soldier.hasPendingSpecializationChoice) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _SpecializationDialog(soldier: soldier),
    );
  }
  if (soldier.hasPendingSkillChoice) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _SkillDialog(soldier: soldier),
    );
  }
  return Future.value();
}

class _SpecializationDialog extends ConsumerWidget {
  final Soldier soldier;
  const _SpecializationDialog({required this.soldier});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(gameStateProvider.notifier);
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text(
        '${soldier.name} получает Ранг 1!',
        style: const TextStyle(color: AppColors.neonCyan),
      ),
      content: SizedBox(
        width: 360,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Выберите специализацию бойца:',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 10),
              ...Specialization.values.map((spec) {
                final def = kSpecializationDefs[spec]!;
                return Card(
                  color: AppColors.surfaceAlt,
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(
                      def.name,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      def.description,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    onTap: () {
                      notifier.chooseSpecialization(soldier.id, spec);
                      Navigator.of(context).pop();
                    },
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class _SkillDialog extends ConsumerWidget {
  final Soldier soldier;
  const _SkillDialog({required this.soldier});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(gameStateProvider.notifier);
    final options = notifier.skillChoicesFor(soldier);
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text(
        '${soldier.name} · ${soldier.rankName} (Ранг ${soldier.rank})',
        style: const TextStyle(color: AppColors.neonCyan),
      ),
      content: SizedBox(
        width: 360,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Выберите новый навык:',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 10),
              ...options.map(
                (skill) => Card(
                  color: AppColors.surfaceAlt,
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(
                      skill.name,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      skill.description,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    onTap: () {
                      notifier.chooseSkill(soldier.id, skill.id);
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Human-readable label for a [SkillEffectType], used in the roster's
/// equipped-skills summary.
String skillEffectLabel(SkillEffect effect) {
  final sign = effect.value >= 0 ? '+' : '';
  return switch (effect.type) {
    SkillEffectType.hp => '$sign${effect.value} HP',
    SkillEffectType.accuracy => '$sign${effect.value} меткость',
    SkillEffectType.movement => '$sign${effect.value} движение',
    SkillEffectType.will => '$sign${effect.value} психика',
    SkillEffectType.damageReduction => '$sign${effect.value} защита',
    SkillEffectType.weaponDamage => '$sign${effect.value} урон',
    SkillEffectType.weaponRange => '$sign${effect.value} дальность',
    SkillEffectType.critChance => '$sign${effect.value}% крит',
  };
}
