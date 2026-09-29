import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/external/enlaces_externos.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_bottom_sheet.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/settings_tile.dart';

/// Preguntas frecuentes, tal cual aparecen en la pantalla.
typedef _Pregunta = ({String pregunta, String respuesta});

/// Ayuda y soporte (07.1 SCR-PROF-12).
///
/// Las respuestas viven en la app y no en un documento: son cortas y las
/// necesita quien está atascado en ese momento. Lo que sí sale es el contacto
/// con el equipo, porque una respuesta automática no siempre basta.
class HelpScreen extends ConsumerWidget {
  const HelpScreen({super.key});

  static const _preguntas = <_Pregunta>[
    (
      pregunta: '¿Cómo cambio mi domicilio de entrega?',
      respuesta:
          'Abre Pedidos, elige una dirección guardada y toca Editar. También '
          'puedes añadir otra nueva desde la pantalla de direcciones.',
    ),
    (
      pregunta: '¿Por qué no me aparece un producto?',
      respuesta:
          'Puede que se haya agotado o que esté escondido por un filtro. Revisa '
          'el filtro de la pantalla de inicio; si sigue sin salir, es que ya no '
          'hay stock.',
    ),
    (
      pregunta: '¿Cómo pido una factura?',
      respuesta:
          'Abre el detalle de un pedido entregado y toca Solicitar factura. La '
          'recibes por correo.',
    ),
    (
      pregunta: '¿Puedo pedir sin crear una cuenta?',
      respuesta:
          'No. La cuenta guarda tus pedidos y direcciones para que no tengas que '
          'escribirlos otra vez.',
    ),
    (
      pregunta: '¿Cómo elimino mi cuenta?',
      respuesta:
          'En Cuenta, al final del perfil. La solicitud la procesa el equipo de '
          'forma manual y no se borra nada al instante.',
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ayuda y soporte')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.xl),
        children: [
          const SectionHeader('Preguntas frecuentes'),
          for (final faq in _preguntas)
            ExpansionTile(
              title: Text(faq.pregunta),
              childrenPadding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                AppSpacing.md,
              ),
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    faq.respuesta,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          const Divider(height: AppSpacing.xl),
          const SectionHeader('Contacto'),
          SettingsTile(
            icon: Icons.support_agent_outlined,
            label: 'Contactar soporte',
            subtitle: 'Escribe a ${ref.watch(enlacesExternosProvider).email}.',
            onTap: () => _escribir(
              context,
              ref,
              asunto: 'Duda sobre QuickBite',
              cuerpo: 'Hola, escribo porque: ',
            ),
          ),
          SettingsTile(
            icon: Icons.bug_report_outlined,
            label: 'Reportar un problema',
            subtitle: 'Cuéntanos qué pasó y en qué teléfono.',
            onTap: () => _escribir(
              context,
              ref,
              asunto: 'Reporte de problema',
              cuerpo: '''
Hola, reporto un problema.

Qué hice:
Qué esperaba:
Teléfono y versión de la app:
''',
            ),
          ),
          SettingsTile(
            icon: Icons.menu_book_outlined,
            label: 'Guía rápida',
            subtitle: 'Un recorrido corto por pedir, pagar y seguir tu pedido.',
            onTap: () => _guiaRapida(context),
          ),
        ],
      ),
    );
  }

  /// La guía se muestra dentro de la app: son cuatro pasos, no vale la pena
  /// mandarle a un sitio web por algo que se lee en diez segundos.
  static void _guiaRapida(BuildContext context) {
    AppBottomSheet.show<void>(
      context,
      title: 'Guía rápida',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _Paso(
            'Elige tu sucursal',
            'Los productos que ves son los de la más cercana.',
          ),
          _Paso(
            'Arma tu pedido',
            'Toca + en cada producto y revísalo en el carrito.',
          ),
          _Paso(
            'Paga',
            'Tarjeta o efectivo al recibir. El pedido llega confirmado.',
          ),
          _Paso(
            'Sigue tu pedido',
            'En Pedidos verás el repartidor y su ubicación.',
          ),
        ],
      ),
    );
  }

  static Future<void> _escribir(
    BuildContext context,
    WidgetRef ref, {
    required String asunto,
    required String cuerpo,
  }) async {
    final abierto = await ref
        .read(enlacesExternosProvider)
        .escribirSoporte(asunto: asunto, cuerpo: cuerpo);
    if (!context.mounted || abierto) return;
    AppSnackbar.showError(context, 'No se pudo abrir tu app de correo.');
  }
}

/// Un paso de la guía rápida, con su número en lugar de una viñeta.
class _Paso extends StatelessWidget {
  const _Paso(this.titulo, this.detalle);

  final String titulo;
  final String detalle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          Text(detalle, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
