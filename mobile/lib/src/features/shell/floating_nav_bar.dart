import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/haptics.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../auth/presentation/auth_providers.dart';
import 'app_router.dart';

/// Barra de navegación inferior flotante.
///
/// Sustituye a la `NavigationBar` pegada al borde. Tres cambios que se ven en el
/// móvil:
///
/// - **Flota**: tarjeta redondeada con margen y sombra difusa, en vez de una
///   franja de color plano que comía altura de pantalla.
/// - **Respeta el tema**: superficie translúcida en vez de blanco fijo, que en
///   modo oscuro era una mancha ilegible.
/// - **Respeta el gesto**: vive en un `SafeArea` inferior, porque en Android 15
///   el gesto de "ir atrás" ocupa la franja de abajo.
/// Envoltura del shell con la barra flotante.
///
/// Se mantiene la firma que el router ya usaba (`navigationShell`) para no tocar
/// el grafo de navegación: solo cambia el widget que se pinta debajo.
class PremiumMainShell extends ConsumerWidget {
  const PremiumMainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rol = ref.watch(sessionProvider).value?.user.rol ?? 'cliente';
    final tema = Theme.of(context);
    final oscuro = tema.brightness == Brightness.dark;
    final superficie = oscuro ? AppColors.nightSurface : AppColors.surface;

    return Scaffold(
      // La barra flota sobre el contenido, que es de donde sale el efecto de
      // "tarjeta suspendida" en vez de franja pegada.
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.md,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: superficie,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(
              color: oscuro ? AppColors.nightBorder : AppColors.border,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x140F172A),
                blurRadius: 28,
                spreadRadius: -8,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.card),
            child: NavigationBar(
              selectedIndex: _indiceActivo(rol),
              // Sin color de fondo: `NavigationBar` pinta el suyo encima, y en
              // modo oscuro el blanco fijo era justo lo que se iba a quitar.
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              indicatorColor: AppColors.accent,
              indicatorShape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(AppRadius.chip)),
              ),
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              onDestinationSelected: (index) {
                AppHaptics.selection();
                navigationShell.goBranch(
                  shellTabsFor(rol)[index].branchIndex,
                  initialLocation: index == 0,
                );
              },
              destinations: [
                for (final tab in shellTabsFor(rol))
                  NavigationDestination(
                    icon: Icon(tab.icon),
                    selectedIcon: Icon(tab.selectedIcon),
                    label: tab.label,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  int _indiceActivo(String rol) {
    final tabs = shellTabsFor(rol);
    final indice = tabs.indexWhere(
      (tab) => tab.branchIndex == navigationShell.currentIndex,
    );
    return indice < 0 ? 0 : indice;
  }
}
