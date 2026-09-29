import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'src/core/system_ui.dart';
import 'src/core/widgets/overlay_conexion.dart';
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
      // Android 15 edge-to-edge: el overlay del sistema se declara aquí para
      // que el reloj y los iconos del gesto inferior tengan buen contraste
      // contra el fondo que la app está usando.
      builder: (context, child) {
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: AppSystemUi.estiloPara(Theme.of(context).brightness),
          child: _construirApp(context, child, preferencias),
        );
      },
      routerConfig: ref.watch(routerProvider),
    );
  }

  Widget _construirApp(
    BuildContext context,
    Widget? child,
    PreferenciasApariencia preferencias,
  ) {
    // `MediaQuery.builder` envuelve la app, así que la escala y la supresión
    // de animaciones se aplican a todas las pantallas sin tocar ninguna. El
    // overlay va aquí dentro para que el aviso de sin conexión cubra cualquier
    // pantalla, incluida la que se está mostrando ahora mismo (SCR-COM-01).
    final media = MediaQuery.of(context);
    return MediaQuery(
      data: media.copyWith(
        textScaler: escalaTexto(preferencias, media.textScaler),
        disableAnimations: sinAnimaciones(
          preferencias,
          media.disableAnimations,
        ),
      ),
      child: OverlayConexion(child: child ?? const SizedBox.shrink()),
    );
  }
}
