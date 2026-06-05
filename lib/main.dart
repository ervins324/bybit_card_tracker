import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:bybit_card_tracker/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  // Open boxes needed for providers on startup
  await Hive.openBox('settings');
  await Hive.openBox<Map>('transactions');

  runApp(
    const ProviderScope(
      child: BybitCardTrackerApp(),
    ),
  );
}
