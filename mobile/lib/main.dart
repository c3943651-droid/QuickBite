import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'src/features/search/presentation/search_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // El historial de búsquedas (05#D-13) vive en preferencias locales, así que
  // se resuelven antes de montar el ProviderScope.
  final preferences = await SharedPreferences.getInstance();
  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
      child: const QuickBiteApp(),
    ),
  );
}
