import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/native.dart';

import 'app.dart';
import 'src/features/search/presentation/search_providers.dart';
import 'src/core/session/token_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // El historial de búsquedas (05#D-13) vive en SQLite local, así que se
  // inicializa antes de montar el ProviderScope.
  final tokenStorage = SecureTokenStorage(FlutterSecureStorage());
  await tokenStorage.initialize();

  runApp(
    ProviderScope(
      overrides: [
        tokenStorageProvider.overrideWithValue(tokenStorage),
      ],
      child: const QuickBiteApp(),
    ),
  );
}
