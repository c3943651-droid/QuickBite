import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../connectivity/conectividad.dart';
import '../theme/app_colors.dart';

/// Aviso de falta de conexión (07.1 SCR-COM-01).
///
/// El overlay vive en el `builder` de `MaterialApp`, así que cubre cualquier
/// pantalla sin que cada una tenga que enterarse de que existe internet.
class OverlayConexion extends ConsumerWidget {
  const OverlayConexion({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conexion = ref.watch(conexionProvider).value;

    if (conexion != false) return child;

    return Stack(
      // `expand` porque en un `Scaffold` el body recibe constraints sueltos: sin
      // esto el Stack se ajustaría al hijo y la cinta quedaría del ancho del
      // texto que hubiera debajo.
      fit: StackFit.expand,
      children: [
        child,
        const Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(child: OfflineBanner()),
        ),
      ],
    );
  }
}

/// Cinta compacta de "sin conexión".
///
/// No es la pantalla completa de SCR-COM-01 porque el overlay solo informa: si
/// la app tapara el contenido, la persona usuaria perdería el carrito y el
/// formulario que estaba rellenando justo cuando más los necesita. Quien no
/// pueda mostrar contenido usa [SinConexionView].
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: AppColors.ink,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            const Icon(Icons.cloud_off, color: AppColors.white, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                AvisoRed.sinConexion,
                style: const TextStyle(color: AppColors.white),
              ),
            ),
            TextButton(
              onPressed: () => reintentar(ref),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.white,
                visualDensity: VisualDensity.compact,
              ),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pantalla completa de "sin conexión" (07.1 SCR-COM-01).
///
/// Para las vistas que no tienen nada que mostrar: la lista que no se pudo
/// cargar o la pantalla que depende de un dato remoto.
class SinConexionView extends ConsumerWidget {
  const SinConexionView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 64, color: AppColors.inkMuted),
            const SizedBox(height: AppSpacing.md),
            Text(
              AvisoRed.sinConexion,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              AvisoRed.descripcion,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.lg),
            TextButton(
              onPressed: () => reintentar(ref),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Vuelve a consultar el estado de red para cerrar el aviso en cuanto vuelva.
///
/// Invalida el provider en vez de escribir el resultado a mano: quien observa
/// vuelve a leer la fuente de verdad y no hay dos caminos para actualizar el
/// estado.
Future<void> reintentar(WidgetRef ref) async {
  await ref.read(conectividadProvider).hayConexion();
  ref.invalidate(conexionProvider);
}

abstract final class AvisoRed {
  static const sinConexion = 'Sin conexión a internet';
  static const descripcion = 'Verifica tu conexión e inténtalo de nuevo';
}

/// Ejecuta [accion] solo si hay conexión.
///
/// Para acciones sensibles (cobrar, aceptar un pedido, guardar) no basta con
/// avisar después: si la petición sale sin red, la pantalla queda en un estado
/// que la persona usuaria no entiende. Aquí se corta antes y se dice por qué.
Future<void> guardiaDeRed(
  BuildContext context, {
  required WidgetRef ref,
  required Future<void> Function() accion,
}) async {
  // El `ScaffoldMessenger` se resuelve antes de esperar: después del `await` el
  // `context` podría pertenecer a una pantalla ya desmontada.
  final messenger = ScaffoldMessenger.maybeOf(context);
  final hayConexion = await ref.read(conectividadProvider).hayConexion();
  if (!hayConexion) {
    if (messenger != null) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(AvisoRed.sinConexion),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
    return;
  }
  await accion();
}
