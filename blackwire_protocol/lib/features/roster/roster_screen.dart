import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../data/content/equipment_catalog.dart';
import '../../data/content/skill_catalog.dart';
import '../../data/models/soldier.dart';
import '../../data/models/specialization.dart';
import '../../state/game_state_notifier.dart';
import 'promotion_dialog.dart';

class RosterScreen extends ConsumerWidget {
  const RosterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final save = ref.watch(gameStateProvider);
    final notifier = ref.read(gameStateProvider.notifier);
    final canHire =
        save.soldiers.length < save.base.rosterCapacity &&
        save.resources.credits >= notifier.hireCost;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Text(
                'ОТРЯД (${save.soldiers.length}/${save.base.rosterCapacity})',
                style: const TextStyle(
                  color: AppColors.neonCyan,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: canHire ? () => notifier.hireSoldier() : null,
                icon: const Icon(Icons.person_add, size: 18),
                label: Text('Нанять (₡${notifier.hireCost})'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.neonMagenta,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: save.soldiers.isEmpty
              ? const Center(
                  child: Text(
                    'В отряде никого нет.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  itemCount: save.soldiers.length,
                  itemBuilder: (context, i) =>
                      _SoldierCard(soldier: save.soldiers[i]),
                ),
        ),
      ],
    );
  }
}

class _StatRow extends StatelessWidget {
  final Soldier soldier;
  const _StatRow({required this.soldier});

  @override
  Widget build(BuildContext context) {
    final xpForNext = soldier.xpForNextRank;
    final xpProgress = soldier.rank >= 10
        ? 1.0
        : (soldier.xp / (xpForNext == 0 ? 1 : xpForNext)).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _statChip(Icons.favorite, '${soldier.maxHp}', AppColors.neonGreen),
            _statChip(
              Icons.track_changes,
              '${soldier.baseAccuracy}',
              AppColors.neonCyan,
            ),
            _statChip(
              Icons.directions_run,
              '${soldier.movementRange}',
              AppColors.neonYellow,
            ),
            _statChip(
              Icons.psychology,
              '${soldier.willpower}',
              AppColors.neonMagenta,
            ),
          ],
        ),
        if (soldier.rank < 10) ...[
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: xpProgress,
              minHeight: 4,
              backgroundColor: Colors.black45,
              color: AppColors.neonCyan,
            ),
          ),
          Text(
            'XP ${soldier.xp}/$xpForNext',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
            ),
          ),
        ],
      ],
    );
  }

  Widget _statChip(IconData icon, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Row(
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 3),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SoldierCard extends ConsumerWidget {
  final Soldier soldier;
  const _SoldierCard({required this.soldier});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final save = ref.watch(gameStateProvider);
    final notifier = ref.read(gameStateProvider.notifier);
    final armor = soldier.armorId != null
        ? kArmorCatalog[soldier.armorId]
        : null;

    final statusColor = switch (soldier.status) {
      SoldierStatus.active => AppColors.neonGreen,
      SoldierStatus.wounded => AppColors.neonYellow,
      SoldierStatus.dead => AppColors.danger,
    };
    final statusLabel = switch (soldier.status) {
      SoldierStatus.active => 'Готов',
      SoldierStatus.wounded => 'Ранен · ${soldier.recoveryDaysLeft} дн.',
      SoldierStatus.dead => 'Погиб',
    };

    final availableWeapons = [
      'pistol_mk1',
      ...save.unlockedWeaponIds.where(
        (id) => id != 'pistol_mk1' && (save.weaponStock[id] ?? 0) > 0,
      ),
    ];
    final availableArmors = save.unlockedArmorIds
        .where((id) => (save.armorStock[id] ?? 0) > 0)
        .toList();

    return Card(
      color: AppColors.surface,
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: statusColor.withValues(alpha: 0.25),
                  child: Icon(Icons.person, color: statusColor),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        soldier.name,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${soldier.rankName} (Ранг ${soldier.rank})'
                        '${soldier.specialization != null ? ' · ${kSpecializationDefs[soldier.specialization]!.name}' : ''}',
                        style: const TextStyle(
                          color: AppColors.neonCyan,
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        statusLabel,
                        style: TextStyle(color: statusColor, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${soldier.missionsSurvived} миссий',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            if (soldier.status != SoldierStatus.dead) ...[
              const SizedBox(height: 8),
              _StatRow(soldier: soldier),
            ],
            if (soldier.hasPendingPromotion) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => showPromotionDialog(context, ref, soldier),
                  icon: const Icon(Icons.military_tech, size: 18),
                  label: const Text('ПОВЫШЕНИЕ ДОСТУПНО!'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.neonYellow,
                    foregroundColor: Colors.black,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _dropdown(
                  label: 'Оружие',
                  value: soldier.weaponId,
                  items: availableWeapons,
                  labelBuilder: (id) => kWeaponCatalog[id]!.name,
                  onChanged: soldier.status == SoldierStatus.dead
                      ? null
                      : (id) => notifier.equipSoldier(soldier.id, weaponId: id),
                ),
                if (availableArmors.isNotEmpty || armor != null)
                  _dropdown(
                    label: 'Броня',
                    value: soldier.armorId,
                    items: availableArmors,
                    labelBuilder: (id) => kArmorCatalog[id]!.name,
                    onChanged: soldier.status == SoldierStatus.dead
                        ? null
                        : (id) =>
                              notifier.equipSoldier(soldier.id, armorId: id),
                  ),
              ],
            ),
            if (soldier.unlockedSkillIds.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: soldier.unlockedSkillIds.map((id) {
                  final def = SkillCatalog.all[id];
                  return Chip(
                    label: Text(
                      def?.name ?? id,
                      style: const TextStyle(fontSize: 11),
                    ),
                    backgroundColor: AppColors.surfaceAlt,
                    labelStyle: const TextStyle(color: AppColors.textPrimary),
                    visualDensity: VisualDensity.compact,
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _dropdown({
    required String label,
    required String? value,
    required List<String> items,
    required String Function(String) labelBuilder,
    required void Function(String?)? onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(6),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value != null && items.contains(value) ? value : null,
          hint: Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          dropdownColor: AppColors.surfaceAlt,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 12),
          items: items
              .map(
                (id) =>
                    DropdownMenuItem(value: id, child: Text(labelBuilder(id))),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
