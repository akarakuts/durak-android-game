/// Точка входа: [ProviderScope], [MaterialApp] и маршруты экранов.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/home_screen.dart';
import 'screens/game_screen.dart';
import 'screens/stats_screen.dart';
import 'l10n/app_strings.dart';
import 'utils/constants.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

/// Корневой виджет приложения (тема Material 3 и named routes).
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppConstants.accentColor,
          brightness: Brightness.dark,
          surface: AppConstants.surfaceColor,
        ),
        scaffoldBackgroundColor: AppConstants.primaryColor,
        fontFamily: 'Roboto',
        useMaterial3: true,
        iconTheme: const IconThemeData(color: AppConstants.ivoryColor),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
        '/game': (context) => const GameScreen(),
        '/stats': (context) => const StatsScreen(),
      },
    );
  }
}
