import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/primary_button.dart';
import '../domain/address_entities.dart';
import 'address_providers.dart';

class AddressFormScreen extends ConsumerWidget {
  const AddressFormScreen({super.key, this.addressId});

  final String? addressId;

  bool get isEditing => addressId != null;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = addressId;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar dirección' : 'Agregar dirección'),
      ),
      body: id == null
          ? const _AddressForm()
          : ref
                .watch(addressDetailProvider(id))
                .when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, _) => _LoadError(
                    error: error,
                    onRetry: () => ref.invalidate(addressDetailProvider(id)),
                  ),
                  data: (address) => _AddressForm(address: address),
                ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final failure = error;
    final message = failure is AppException
        ? failure.userMessage
        : 'No pudimos cargar la dirección. Inténtalo de nuevo.';

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

class _AddressForm extends ConsumerStatefulWidget {
  const _AddressForm({this.address});

  final Address? address;

  @override
  ConsumerState<_AddressForm> createState() => _AddressFormState();
}

class _AddressFormState extends ConsumerState<_AddressForm> {
  final _formKey = GlobalKey<FormState>();
  final _aliasController = TextEditingController();
  final _calleController = TextEditingController();
  final _numeroController = TextEditingController();
  final _referenciaController = TextEditingController();
  final _ciudadController = TextEditingController();
  final _latitudController = TextEditingController();
  final _longitudController = TextEditingController();
  bool _esPredeterminada = false;

  bool get _isEditing => widget.address != null;

  @override
  void initState() {
    super.initState();
    _fill(widget.address);
  }

  @override
  void didUpdateWidget(covariant _AddressForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.address?.id != widget.address?.id) {
      _fill(widget.address);
    }
  }

  void _fill(Address? address) {
    _aliasController.text = address?.alias ?? '';
    _calleController.text = address?.calle ?? '';
    _numeroController.text = address?.numero ?? '';
    _referenciaController.text = address?.referencia ?? '';
    _ciudadController.text = address?.ciudad ?? '';
    _latitudController.text = address?.latitud?.toString() ?? '';
    _longitudController.text = address?.longitud?.toString() ?? '';
    _esPredeterminada = address?.esPredeterminada ?? false;
  }

  @override
  void dispose() {
    _aliasController.dispose();
    _calleController.dispose();
    _numeroController.dispose();
    _referenciaController.dispose();
    _ciudadController.dispose();
    _latitudController.dispose();
    _longitudController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    FocusScope.of(context).unfocus();
    final saved = await ref
        .read(addressFormProvider.notifier)
        .save(
          id: widget.address?.id,
          alias: _aliasController.text,
          calle: _calleController.text,
          numero: _numeroController.text,
          referencia: _referenciaController.text,
          ciudad: _ciudadController.text,
          latitud: _parseCoordinate(_latitudController.text),
          longitud: _parseCoordinate(_longitudController.text),
          esPredeterminada: _esPredeterminada,
        );
    if (!mounted) {
      return;
    }
    if (saved) {
      AppSnackbar.showSuccess(
        context,
        _isEditing ? 'Dirección actualizada' : 'Dirección agregada',
      );
      context.pop();
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar dirección'),
        content: const Text('Esta acción no se puede deshacer.'),
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
    final deleted = await ref
        .read(addressFormProvider.notifier)
        .delete(widget.address!.id);
    if (!mounted) {
      return;
    }
    if (deleted) {
      AppSnackbar.showSuccess(context, 'Dirección eliminada');
      context.pop();
    }
  }

  static double? _parseCoordinate(String raw) => double.tryParse(raw.trim());

  static String? _required(String? value, String message) =>
      value == null || value.trim().isEmpty ? message : null;

  static String? _validateCoordinate(String? value) {
    final raw = value?.trim() ?? '';
    if (raw.isEmpty || double.tryParse(raw) != null) {
      return null;
    }
    return 'No es un número';
  }

  @override
  Widget build(BuildContext context) {
    final form = ref.watch(addressFormProvider);

    ref.listen(addressFormProvider, (previous, next) {
      final failure = next.error;
      if (failure == null || previous?.error == failure) {
        return;
      }
      final message = failure is AppException
          ? failure.userMessage
          : 'No pudimos guardar la dirección. Inténtalo de nuevo.';
      AppSnackbar.showError(context, message);
    });

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              label: 'Alias',
              controller: _aliasController,
              hintText: 'Casa, Oficina…',
              prefixIcon: Icons.bookmark_outline,
              textInputAction: TextInputAction.next,
              enabled: !form.loading,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: 'Calle',
              controller: _calleController,
              prefixIcon: Icons.home_outlined,
              textInputAction: TextInputAction.next,
              enabled: !form.loading,
              validator: (value) =>
                  _required(value, 'La calle es obligatoria.'),
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: 'Número',
              controller: _numeroController,
              prefixIcon: Icons.tag,
              textInputAction: TextInputAction.next,
              enabled: !form.loading,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: 'Referencia',
              controller: _referenciaController,
              hintText: 'Portón, piso, entre calles…',
              prefixIcon: Icons.notes_outlined,
              textInputAction: TextInputAction.next,
              enabled: !form.loading,
              maxLength: 255,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: 'Ciudad',
              controller: _ciudadController,
              prefixIcon: Icons.location_city_outlined,
              textInputAction: TextInputAction.next,
              enabled: !form.loading,
              validator: (value) =>
                  _required(value, 'La ciudad es obligatoria.'),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: AppTextField(
                    label: 'Latitud',
                    controller: _latitudController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    textInputAction: TextInputAction.next,
                    enabled: !form.loading,
                    validator: _validateCoordinate,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: AppTextField(
                    label: 'Longitud',
                    controller: _longitudController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    textInputAction: TextInputAction.next,
                    enabled: !form.loading,
                    validator: _validateCoordinate,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            CheckboxListTile(
              value: _esPredeterminada,
              onChanged: form.loading
                  ? null
                  : (value) =>
                        setState(() => _esPredeterminada = value ?? false),
              title: const Text('Marcar como predeterminada'),
              contentPadding: EdgeInsets.zero,
              activeColor: AppColors.accent,
              controlAffinity: ListTileControlAffinity.leading,
            ),
            const SizedBox(height: AppSpacing.md),
            PrimaryButton(
              label: 'Guardar',
              isLoading: form.loading,
              onPressed: () => _save(),
            ),
            if (_isEditing) ...[
              const SizedBox(height: AppSpacing.sm),
              PrimaryButton(
                label: 'Eliminar',
                icon: Icons.delete_outline,
                onPressed: form.loading ? null : () => _delete(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
