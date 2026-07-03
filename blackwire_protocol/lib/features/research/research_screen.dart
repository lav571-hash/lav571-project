import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../data/content/research_catalog.dart';
import '../../state/game_state_notifier.dart';

class ResearchScreen extends ConsumerWidget {
  const ResearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final save = ref.watch(gameStateProvider);
    final notifier = ref.read(gameStateProvider.notifier);

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        Text(
          'ЛАБОРАТОРИЯ · Данные: ${save.resources.data}',
          style: const TextStyle(
            color: AppColors.neonCyan,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 10),
        ...kResearchTree.map((node) {
          final completed = save.completedResearchIds.contains(node.id);
          final prereqsOk = node.prerequisites.every(
            save.completedResearchIds.contains,
          );
          final canResearch =
              !completed && prereqsOk && save.resources.data >= node.dataCost;
          final locked = !completed && !prereqsOk;

          return Card(
            color: completed ? AppColors.surfaceAlt : AppColors.surface,
            margin: const EdgeInsets.only(bottom: 10),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(
                    completed
                        ? Icons.check_circle
                        : (locked ? Icons.lock : Icons.science_outlined),
                    color: completed
                        ? AppColors.neonGreen
                        : (locked
                              ? AppColors.textSecondary
                              : AppColors.neonCyan),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          node.name,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          node.description,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        if (locked)
                          Text(
                            'Требуется: ${node.prerequisites.map((p) => kResearchTree.firstWhere((n) => n.id == p).name).join(', ')}',
                            style: const TextStyle(
                              color: AppColors.danger,
                              fontSize: 11,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (!completed)
                    ElevatedButton(
                      onPressed: canResearch
                          ? () => notifier.completeResearch(node.id)
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.neonMagenta,
                        disabledBackgroundColor: Colors.black26,
                      ),
                      child: Text('◆${node.dataCost}'),
                    ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
