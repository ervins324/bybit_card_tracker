import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:bybit_card_tracker/core/theme/app_theme.dart';
import 'package:bybit_card_tracker/presentation/providers/credentials_provider.dart';
import 'package:bybit_card_tracker/presentation/screens/home_screen.dart';
import 'package:bybit_card_tracker/presentation/screens/setup_screen.dart';

class BybitCardTrackerApp extends ConsumerWidget {
  const BybitCardTrackerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final credentialsState = ref.watch(credentialsProvider);

    return MaterialApp(
      title: 'Bybit Card Tracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: credentialsState.when(
        data: (creds) {
          if (creds != null && creds.isValid) {
            return const HomeScreen();
          }
          return const SetupScreen();
        },
        loading: () => Scaffold(
          body: Center(
            child: LoadingAnimationWidget.threeRotatingDots(
              color: AppTheme.gold,
              size: 48,
            ),
          ),
        ),
        error: (error, _) => Scaffold(
          body: Center(child: Text('Error loading credentials: $error')),
        ),
      ),
      routes: {
        '/setup': (context) => const SetupScreen(),
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}
