import 'package:flutter/material.dart';

import 'core/constants.dart';
import 'features/main_menu/main_menu_screen.dart';

class BlackwireApp extends StatelessWidget {
  const BlackwireApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BLACKWIRE PROTOCOL',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.neonCyan,
          brightness: Brightness.dark,
          surface: AppColors.surface,
        ),
        navigationBarTheme: const NavigationBarThemeData(
          backgroundColor: AppColors.surface,
        ),
        cardTheme: const CardThemeData(elevation: 0),
      ),
      home: const MainMenuScreen(),
    );
  }
}
