import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../state/game_state_notifier.dart';
import '../base/base_screen.dart';
import '../geoscape/geoscape_screen.dart';
import '../main_menu/main_menu_screen.dart';
import '../research/research_screen.dart';
import '../roster/roster_screen.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _tabIndex = 1;

  static const _tabs = [
    BaseScreen(),
    GeoscapeScreen(),
    RosterScreen(),
    ResearchScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final save = ref.watch(gameStateProvider);

    if (save.gameOver) {
      return _GameOverScreen(chaos: save.chaosLevel);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _StatusBar(),
            Expanded(
              child: IndexedStack(index: _tabIndex, children: _tabs),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.neonCyan.withValues(alpha: 0.2),
        selectedIndex: _tabIndex,
        onDestinationSelected: (i) => setState(() => _tabIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.apartment), label: 'База'),
          NavigationDestination(icon: Icon(Icons.public), label: 'Геоскейп'),
          NavigationDestination(icon: Icon(Icons.groups), label: 'Отряд'),
          NavigationDestination(
            icon: Icon(Icons.science),
            label: 'Исследования',
          ),
        ],
      ),
    );
  }
}

class _StatusBar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final save = ref.watch(gameStateProvider);
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          _resTag(
            Icons.attach_money,
            '${save.resources.credits}',
            AppColors.neonYellow,
          ),
          const SizedBox(width: 14),
          _resTag(
            Icons.build,
            '${save.resources.materials}',
            AppColors.neonGreen,
          ),
          const SizedBox(width: 14),
          _resTag(Icons.memory, '${save.resources.data}', AppColors.neonCyan),
          const Spacer(),
          const Icon(Icons.warning_amber, color: AppColors.danger, size: 16),
          const SizedBox(width: 4),
          SizedBox(
            width: 90,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: (save.chaosLevel / 100).clamp(0, 1),
                minHeight: 8,
                backgroundColor: Colors.black45,
                color: save.chaosLevel > 66
                    ? AppColors.danger
                    : (save.chaosLevel > 33
                          ? AppColors.neonYellow
                          : AppColors.neonGreen),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'ХАОС ${save.chaosLevel.toInt()}%',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _resTag(IconData icon, String value, Color color) {
    return Row(
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 3),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

class _GameOverScreen extends StatelessWidget {
  final double chaos;
  const _GameOverScreen({required this.chaos});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.dangerous, color: AppColors.danger, size: 64),
            const SizedBox(height: 16),
            const Text(
              'ГОРОД ПОГРУЗИЛСЯ В ХАОС',
              style: TextStyle(
                color: AppColors.danger,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Уровень хаоса достиг ${chaos.toInt()}%. Reclaim не смогли сдержать корпорации.',
              style: const TextStyle(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const MainMenuScreen()),
                (route) => false,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.neonCyan,
                foregroundColor: Colors.black,
              ),
              child: const Text('В ГЛАВНОЕ МЕНЮ'),
            ),
          ],
        ),
      ),
    );
  }
}
