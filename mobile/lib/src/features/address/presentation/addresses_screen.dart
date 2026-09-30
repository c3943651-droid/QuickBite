import '../../../core/theme/app_radius.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/chips.dart';
import '../domain/address_entities.dart';
import 'address_providers.dart';

class AddressesScreen extends ConsumerWidget {
  const AddressesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addresses = ref.watch(addressesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mis direcciones')),
      body: addresses.when(
        loading: () => const _LoadingList(),
        error: (error, _) => _AddressesError(
          error: error,
          onRetry: () => ref.invalidate(addressesProvider),
        ),
        data: (list) =>
            list.isEmpty ? const _EmptyState() : _AddressList(addresses: list),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/addresses/new'),
        icon: const Icon(Icons.add),
        label: const Text('Agregar dirección'),
      ),
    );
  }
}

class _LoadingList extends StatelessWidget {
  const _LoadingList();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: 3,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) => const _CardSkeleton(),
    );
  }
}

class _CardSkeleton extends StatelessWidget {
  const _CardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 96,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.button),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.location_off_outlined,
              size: 64,
              color: AppColors.accent,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Aún no tienes direcciones',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Agrega una dirección para Lightning Pickup y deliveries.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(
              label: 'Agregar',
              icon: Icons.add,
              onPressed: () => context.push('/addresses/new'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddressesError extends StatelessWidget {
  const _AddressesError({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final failure = error;
    final message = failure is AppException
        ? failure.userMessage
        : 'No pudimos cargar tus direcciones. Inténtalo de nuevo.';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.md),
            PrimaryButton(label: 'Reintentar', onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}

class _AddressList extends ConsumerWidget {
  const _AddressList({required this.addresses});

  final List<Address> addresses;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        96,
      ),
      itemCount: addresses.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) => _AddressCard(address: addresses[index]),
    );
  }
}

class _AddressCard extends ConsumerStatefulWidget {
  const _AddressCard({required this.address});

  final Address address;

  @override
  ConsumerState<_AddressCard> createState() => _AddressCardState();
}

class _AddressCardState extends ConsumerState<_AddressCard> {
  bool _busy = false;

  Future<void> _setDefault() async {
    setState(() => _busy = true);
    try {
      await ref
          .read(addressRepositoryProvider)
          .setDefaultAddress(widget.address.id);
      ref.invalidate(addressesProvider);
    } on Object catch (error) {
      if (mounted) {
        _reportError(error, 'No pudimos marcar la dirección.');
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar dirección'),
        content: const Text(
          'Esta acción no se puede deshacer. Los pedidos ya realizados '
          'conservan su dirección.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    setState(() => _busy = true);
    try {
      await ref
          .read(addressRepositoryProvider)
          .deleteAddress(widget.address.id);
      ref.invalidate(addressesProvider);
      if (mounted) {
        AppSnackbar.showSuccess(context, 'Dirección eliminada');
      }
    } on Object catch (error) {
      if (mounted) {
        _reportError(error, 'No pudimos eliminar la dirección.');
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  void _reportError(Object error, String fallback) {
    final message = error is AppException ? error.userMessage : fallback;
    AppSnackbar.showError(context, message);
  }

  @override
  Widget build(BuildContext context) {
    final address = widget.address;

    return Card(
      child: InkWell(
        onTap: () => context.push('/addresses/${address.id}/edit'),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    address.etiqueta,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  if (address.esPredeterminada)
                    const StatusChip(
                      label: 'Predeterminada',
                      tone: StatusTone.success,
                    ),
                  const Spacer(),
                  IconButton(
                    tooltip: address.esPredeterminada
                        ? 'Predeterminada'
                        : 'Marcar como predeterminada',
                    icon: Icon(
                      address.esPredeterminada ? Icons.star : Icons.star_border,
                    ),
                    onPressed: address.esPredeterminada || _busy
                        ? null
                        : () => _setDefault(),
                  ),
                  IconButton(
                    tooltip: 'Editar',
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () =>
                        context.push('/addresses/${address.id}/edit'),
                  ),
                  IconButton(
                    tooltip: 'Eliminar',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: _busy ? null : () => _delete(),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                address.linea1,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (address.linea2.isNotEmpty)
                Text(
                  address.linea2,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
