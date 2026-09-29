import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/metric_card.dart';
import '../../../core/widgets/state_views.dart';
import '../domain/estadisticas_repartidor.dart';
import 'delivery_providers.dart';

/// Métricas personales del repartidor (07.1 SCR-DEL-06).
///
/// Son cinco tarjetas y no una gráfica: el repartidor quiere saber de un
/// vistazo cómo va su turno y su promedio, no ver una curva de la semana.
class DeliveryStatsScreen extends ConsumerWidget {
  const DeliveryStatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(estadisticasRepartidorProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mis estadísticas')),
      body: stats.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorStateView(
          message: mensaje(error),
          onRetry: () => ref.invalidate(estadisticasRepartidorProvider),
        ),
        data: (datos) => _Tarjetas(stats: datos),
      ),
    );
  }
}

class _Tarjetas extends StatelessWidget {
  const _Tarjetas({required this.stats});

  final EstadisticasRepartidor stats;

  @override
  Widget build(BuildContext context) {
    // Un repartidor nuevo ve ceros, no una pantalla vacía: los ceros sí son un
    // dato y le dicen que todavía no ha hecho nada.
    if (stats.estaVacia) {
      return Column(
        children: [
          const EmptyStateView(
            message: 'Aún no tienes entregas',
            icon: Icons.insights_outlined,
          ),
          Expanded(child: _Rejilla(stats: stats)),
        ],
      );
    }
    return _Rejilla(stats: stats);
  }
}

class _Rejilla extends StatelessWidget {
  const _Rejilla({required this.stats});

  final EstadisticasRepartidor stats;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      padding: const EdgeInsets.all(AppSpacing.md),
      crossAxisCount: 2,
      mainAxisSpacing: AppSpacing.md,
      crossAxisSpacing: AppSpacing.md,
      childAspectRatio: 1.6,
      children: [
        MetricCard(
          title: 'Entregas totales',
          value: '${stats.entregasTotales}',
          icon: Icons.local_shipping_outlined,
        ),
        MetricCard(
          title: 'Entregas del mes',
          value: '${stats.entregasDelMes}',
          icon: Icons.calendar_month_outlined,
        ),
        MetricCard(
          title: 'Tiempo promedio de entrega',
          value: '${stats.tiempoPromedioEntregaMinutos}',
          subtitle: 'minutos',
          icon: Icons.timer_outlined,
        ),
        MetricCard(
          title: 'Pedidos asignados',
          value: '${stats.pedidosAsignados}',
          icon: Icons.assignment_outlined,
        ),
        MetricCard(
          title: 'Cancelaciones',
          value: '${stats.cancelaciones}',
          icon: Icons.cancel_outlined,
        ),
        // La rejilla es de dos columnas y hay cinco métricas: la última celda
        // se deja con el color de superficie para que no se vea un hueco.
        const ColoredBox(color: AppColors.surfaceMuted),
      ],
    );
  }
}
