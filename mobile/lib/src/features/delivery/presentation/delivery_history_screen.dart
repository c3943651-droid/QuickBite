import '../../../core/theme/app_radius.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/chips.dart';
import '../../../core/widgets/state_views.dart';
import '../../order/domain/order_entities.dart';
import '../domain/pedido_entrega.dart';
import 'delivery_providers.dart';

/// Ventana temporal del historial (07.1 SCR-DEL-04).
enum FiltroHistorial {
  hoy('Hoy', 0),
  semana('Semana', 7),
  mes('Mes', 30),
  todo('Todo', null);

  const FiltroHistorial(this.etiqueta, this.dias);

  final String etiqueta;

  /// Días que se incluyen; `null` = sin límite.
  final int? dias;

  bool incluye(PedidoEntrega pedido, DateTime ahora) {
    final limite = dias;
    if (limite == null) return true;
    final creado = pedido.creadoEn;
    if (creado == null) return true;
    return ahora.difference(creado.toUtc()).inDays <= limite;
  }
}

final filtroHistorialProvider =
    NotifierProvider<FiltroHistorialNotifier, FiltroHistorial>(
      FiltroHistorialNotifier.new,
    );

class FiltroHistorialNotifier extends Notifier<FiltroHistorial> {
  @override
  FiltroHistorial build() => FiltroHistorial.todo;

  void seleccionar(FiltroHistorial filtro) => state = filtro;
}

/// Historial de entregas (07.1 SCR-DEL-04).
///
/// El filtro es de fecha porque el repartidor no busca "un pedido" sino "lo que
/// hice hoy": el backend no pagina ni filtra, así que el recorte es de cliente.
class DeliveryHistoryScreen extends ConsumerWidget {
  const DeliveryHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historial = ref.watch(historialEntregasProvider);
    final filtro = ref.watch(filtroHistorialProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Historial de entregas')),
      body: Column(
        children: [
          _Filtros(
            seleccionado: filtro,
            onSeleccionar: (nuevo) =>
                ref.read(filtroHistorialProvider.notifier).seleccionar(nuevo),
          ),
          Expanded(
            child: historial.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => ErrorStateView(
                message: mensaje(error),
                onRetry: () => ref.invalidate(historialEntregasProvider),
              ),
              data: (entregas) => _Lista(entregas: entregas, filtro: filtro),
            ),
          ),
        ],
      ),
    );
  }
}

class _Filtros extends StatelessWidget {
  const _Filtros({required this.seleccionado, required this.onSeleccionar});

  final FiltroHistorial seleccionado;
  final ValueChanged<FiltroHistorial> onSeleccionar;

  @override
  Widget build(BuildContext context) {
    // Sin alto fijo: la fila se mide al chip. Con un `SizedBox(height: 56)` el
    // padding vertical de la lista se comía el espacio y el chip se estrujaba
    // de 37 px a 24, con la etiqueta aplastada a un trazo —y con el tamaño de
    // texto grande de Accesibilidad, aún peor.
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          for (final filtro in FiltroHistorial.values) ...[
            CategoryChip(
              label: filtro.etiqueta,
              selected: filtro == seleccionado,
              onTap: () => onSeleccionar(filtro),
            ),
            if (filtro != FiltroHistorial.values.last)
              const SizedBox(width: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}

class _Lista extends StatelessWidget {
  const _Lista({required this.entregas, required this.filtro});

  final List<PedidoEntrega> entregas;
  final FiltroHistorial filtro;

  @override
  Widget build(BuildContext context) {
    final ahora = DateTime.now();
    // Un pedido cancelado no fue una entrega del repartidor: el backend lo
    // devuelve en el mismo historial y aquí no tiene nada que aparecer.
    final visibles = entregas
        .where((p) => p.estadoPedido != EstadoPedido.cancelado)
        .where((p) => filtro.incluye(p, ahora))
        .toList(growable: false);

    if (visibles.isEmpty) {
      return const EmptyStateView(
        message: 'Todavía no tienes entregas',
        icon: Icons.receipt_long_outlined,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: visibles.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) {
        final entrega = visibles[index];
        return _TarjetaEntrega(
          entrega: entrega,
          onTap: () {
            context
                .push('/delivery/history/${entrega.id}')
                .then(
                  (_) => debugPrint('vuelta de push'),
                  onError: (Object e) => debugPrint('ERROR de push: $e'),
                );
          },
        );
      },
    );
  }
}

class _TarjetaEntrega extends StatelessWidget {
  const _TarjetaEntrega({required this.entrega, required this.onTap});

  final PedidoEntrega entrega;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.all(AppSpacing.md),
        leading: const CircleAvatar(
          backgroundColor: AppColors.accent,
          child: Icon(Icons.check, color: Colors.white),
        ),
        title: Text(entrega.numeroPedido, style: tema.textTheme.titleMedium),
        subtitle: Text(fecha(entrega.creadoEn)),
        trailing: Text(
          CurrencyFormatter.format(entrega.total),
          style: tema.textTheme.titleSmall?.copyWith(color: AppColors.accent),
        ),
      ),
    );
  }
}

/// Detalle de una entrega pasada (07.1 SCR-DEL-05).
class DeliveryHistoryDetailScreen extends ConsumerWidget {
  const DeliveryHistoryDetailScreen({super.key, required this.pedidoId});

  final String pedidoId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historial = ref.watch(historialEntregasProvider);
    final tema = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Entrega')),
      body: historial.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorStateView(
          message: mensaje(error),
          onRetry: () => ref.invalidate(historialEntregasProvider),
        ),
        data: (entregas) {
          final encontradas = entregas.where((p) => p.id == pedidoId);
          if (encontradas.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.xl),
                child: Text(
                  'No encontramos esa entrega',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          final entrega = encontradas.first;
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Text(entrega.numeroPedido, style: tema.textTheme.headlineSmall),
              const SizedBox(height: AppSpacing.lg),
              _Dato(
                titulo: 'Fecha y hora de entrega',
                valor: fecha(entrega.creadoEn),
              ),
              const SizedBox(height: AppSpacing.md),
              _Dato(
                titulo: 'Tiempo total de entrega',
                valor:
                    '${entrega.minutosDesdeCreacion(entrega.creadoEn?.toLocal() ?? DateTime.now()) ?? 0} min',
              ),
              const SizedBox(height: AppSpacing.md),
              // Dirección y productos no llegan: `GET /delivery/history` solo
              // manda número, estado, total y fecha (04 §11.5).
              _Dato(
                titulo: 'Total',
                valor: CurrencyFormatter.format(entrega.total),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Dato extends StatelessWidget {
  const _Dato({required this.titulo, required this.valor});

  final String titulo;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titulo, style: Theme.of(context).textTheme.labelMedium),
        Text(valor, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }
}

/// Fecha corta para las tarjetas del historial.
String fecha(DateTime? value) => value == null
    ? 'Sin fecha'
    : DateFormat('d MMM, HH:mm', 'es').format(value.toLocal());
