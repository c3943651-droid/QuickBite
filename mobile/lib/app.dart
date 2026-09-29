import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'src/features/profile/domain/preferencias_apariencia.dart';
import 'src/features/profile/presentation/apariencia_providers.dart';
import 'src/features/profile/presentation/apariencia_theme.dart';
import 'src/features/shell/app_router.dart';

class QuickBiteApp extends ConsumerWidget {
  const QuickBiteApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Se observan las preferencias: el cambio se ve en cuanto se elige en la
    // pantalla de apariencia, sin reiniciar la app (07.1 SCR-PROF-09). Mientras
    // se leen se usan los valores de fábrica, que es lo mismo que ve el usuario
    // antes de tocarlas.
    final preferencias =
        ref.watch(aparienciaProvider).asData?.value ??
        const PreferenciasApariencia();

    return MaterialApp.router(
      title: 'QuickBite',
      debugShowCheckedModeBanner: false,
      theme: temaClaro(preferencias),
      darkTheme: temaOscuro(preferencias),
      themeMode: modoTema(preferencias),
      builder: (context, child) {
        // `MediaQuery.builder` envuelve la app, así que la escala y la supresión
        // de animaciones se aplican a todas las pantallas sin tocar ninguna.
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(
            textScaler: escalaTexto(preferencias, media.textScaler),
            disableAnimations: sinAnimaciones(
              preferencias,
              media.disableAnimations,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      routerConfig: ref.watch(routerProvider),
    );
  }
}
