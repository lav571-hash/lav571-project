import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../state/game_state_notifier.dart';
import '../home/home_shell.dart';

class MainMenuScreen extends ConsumerStatefulWidget {
  const MainMenuScreen({super.key});

  @override
  ConsumerState<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends ConsumerState<MainMenuScreen> {
  bool _busy = false;

  Future<void> _start(Future<void> Function() action) async {
    setState(() => _busy = true);
    await action();
    if (!mounted) return;
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const HomeShell()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ShaderMask(
              shaderCallback: (rect) => const LinearGradient(
                colors: [AppColors.neonCyan, AppColors.neonMagenta],
              ).createShader(rect),
              child: const Text(
                'BLACKWIRE\nPROTOCOL',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 44,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4,
                  height: 1.05,
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'RECLAIM vs TITAN DYNAMICS · NEXUS ROBOTICS · CHIMERA LABS',
              style: TextStyle(
                color: AppColors.textSecondary,
                letterSpacing: 1.5,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 48),
            if (_busy)
              const CircularProgressIndicator(color: AppColors.neonCyan)
            else ...[
              _MenuButton(
                label: 'НОВАЯ ИГРА',
                color: AppColors.neonCyan,
                onTap: () => _start(
                  () => ref.read(gameStateProvider.notifier).startNewGame(),
                ),
              ),
              const SizedBox(height: 14),
              _MenuButton(
                label: 'ПРОДОЛЖИТЬ',
                color: AppColors.neonMagenta,
                onTap: () => _start(
                  () => ref.read(gameStateProvider.notifier).resumeGame(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _MenuButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: color, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }
}
