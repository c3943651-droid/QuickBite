import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../domain/sesion_usuario.dart';
import 'security_providers.dart';

/// Hub de seguridad de la cuenta (07.1 SCR-PROF-03).
///
/// Solo navega: el subhub existe para que "Cambiar contraseña" y "Sesiones
/// activas" no compitan por el mismo peso visual dentro del perfil, que ya
/// mezcla ajustes, datos y salida de sesión.
class SecurityScreen extends ConsumerWidget {
  const SecurityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sesiones = ref.watch(sesionesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Seguridad')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        children: [
          _Fila(
            icon: Icons.lock_outline,
            label: 'Cambiar contraseña',
            onTap: () => context.push('/profile/security/password'),
          ),
          _Fila(
            icon: Icons.devices_outlined,
            label: 'Sesiones activas',
            detalle: _contador(sesiones),
            onTap: () => context.push('/profile/security/sessions'),
          ),
        ],
      ),
    );
  }

  /// El contador se degrada a "—" si la lista no cargó: un "0 sesiones" sería
  /// una afirmación falsa sobre la seguridad de la cuenta.
  static String _contador(AsyncValue<List<SesionUsuario>> sesiones) =>
      switch (sesiones) {
        AsyncData(:final value) => value.isEmpty
            ? 'Sin sesiones'
            : '${value.length} ${value.length == 1 ? 'sesión activa' : 'sesiones activas'}',
        _ => '—',
      };
}

class _Fila extends StatelessWidget {
  const _Fila({
    required this.icon,
    required this.label,
    required this.onTap,
    this.detalle,
  });

  final IconData icon;
  final String label;
  final String? detalle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      subtitle: detalle == null ? null : Text(detalle!),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
