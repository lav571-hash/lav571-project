import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../data/content/equipment_catalog.dart';
import '../../state/game_state_notifier.dart';

class BaseScreen extends ConsumerWidget {
  const BaseScreen({super.key});

  static const _facilities = [
    ('barracks', 'Казармы', Icons.bed, 'Вместимость отряда'),
    (
      'workshop',
      'Мастерская',
      Icons.precision_manufacturing,
      'Производство снаряжения',
    ),
    ('lab', 'Лаборатория', Icons.biotech, 'Скорость исследований'),
    ('hangar', 'Ангар', Icons.local_shipping, 'Одновременные миссии'),
    ('warehouse', 'Склад', Icons.warehouse, 'Лимит хранения ресурсов'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final save = ref.watch(gameStateProvider);
    final notifier = ref.read(gameStateProvider.notifier);

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        const _SectionTitle('БАЗА RECLAIM'),
        const SizedBox(height: 8),
        ..._facilities.map((f) {
          final (id, name, icon, desc) = f;
          final level = notifier.currentLevel(id);
          final creditCost = FacilityCosts.creditsFor(id, level + 1);
          final materialCost = FacilityCosts.materialsFor(id, level + 1);
          final affordable =
              save.resources.credits >= creditCost &&
              save.resources.materials >= materialCost;
          String statValue = switch (id) {
            'barracks' =>
              '${save.soldiers.length}/${save.base.rosterCapacity} бойцов',
            'hangar' => '${save.base.parallelMissionSlots} слот(ов) миссий',
            'warehouse' => 'лимит ${save.base.resourceStorageCap}',
            _ => 'ур. $level',
          };

          return Card(
            color: AppColors.surface,
            margin: const EdgeInsets.only(bottom: 10),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Icon(icon, color: AppColors.neonCyan, size: 30),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$name · ур.$level',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          desc,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          statValue,
                          style: const TextStyle(
                            color: AppColors.neonGreen,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      ElevatedButton(
                        onPressed: affordable
                            ? () => notifier.upgradeFacility(id)
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.neonMagenta,
                          disabledBackgroundColor: Colors.black26,
                        ),
                        child: const Text('Улучшить'),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₡$creditCost / ⚙$materialCost',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 16),
        const _SectionTitle('МАСТЕРСКАЯ: ПРОИЗВОДСТВО'),
        const SizedBox(height: 8),
        if (save.unlockedWeaponIds.length <= 1 && save.unlockedArmorIds.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'Пока нет новых чертежей. Исследуйте технологии в лаборатории, чтобы открыть производство.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ...save.unlockedWeaponIds.where((id) => id != 'pistol_mk1').map((id) {
          final def = kWeaponCatalog[id]!;
          final cost = notifier.craftCost(id, isWeapon: true);
          final stock = save.weaponStock[id] ?? 0;
          return _craftTile(
            def.name,
            'оружие · тир ${def.tier}',
            stock,
            cost,
            save.resources.materials >= cost,
            () => notifier.craftWeapon(id),
          );
        }),
        ...save.unlockedArmorIds.map((id) {
          final def = kArmorCatalog[id]!;
          final cost = notifier.craftCost(id, isWeapon: false);
          final stock = save.armorStock[id] ?? 0;
          return _craftTile(
            def.name,
            'броня · тир ${def.tier}',
            stock,
            cost,
            save.resources.materials >= cost,
            () => notifier.craftArmor(id),
          );
        }),
      ],
    );
  }

  Widget _craftTile(
    String name,
    String subtitle,
    int stock,
    int cost,
    bool affordable,
    VoidCallback onCraft,
  ) {
    return Card(
      color: AppColors.surfaceAlt,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(name, style: const TextStyle(color: AppColors.textPrimary)),
        subtitle: Text(
          '$subtitle · на складе: $stock',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        trailing: ElevatedButton(
          onPressed: affordable ? onCraft : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.neonGreen,
            foregroundColor: Colors.black,
          ),
          child: Text('Произвести (⚙$cost)'),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.neonCyan,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
    );
  }
}
