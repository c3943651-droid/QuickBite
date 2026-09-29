import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/primary_button.dart';
import 'security_providers.dart';

/// Cambio de contraseña (07.1 SCR-PROF-04).
///
/// Los requisitos se muestran mientras se escribe en lugar de después de
/// guardar: la política del backend es la misma que valida
/// [AppValidators], así que mostrar el error en el servidor cuando ya se puede
/// anticipar localmente solo obliga al usuario a corregir dos veces.
class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _actual = TextEditingController();
  final _nueva = TextEditingController();
  final _confirmar = TextEditingController();

  bool _verActual = false;
  bool _verNueva = false;
  bool _verConfirmar = false;

  @override
  void dispose() {
    _actual.dispose();
    _nueva.dispose();
    _confirmar.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cambioPasswordProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Cambiar contraseña')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          if (state.errorMessage != null) ...[
            _Aviso(mensaje: state.errorMessage!),
            const SizedBox(height: AppSpacing.md),
          ],
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTextField(
                  label: 'Contraseña actual',
                  controller: _actual,
                  prefixIcon: Icons.lock_outline,
                  obscureText: !_verActual,
                  onToggleObscure: () =>
                      setState(() => _verActual = !_verActual),
                  autofillHints: const [AutofillHints.password],
                  validator: (value) => (value ?? '').isEmpty
                      ? AppValidators.passwordRequired
                      : null,
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: 'Nueva contraseña',
                  controller: _nueva,
                  prefixIcon: Icons.lock_reset_outlined,
                  obscureText: !_verNueva,
                  onToggleObscure: () => setState(() => _verNueva = !_verNueva),
                  onChanged: (_) => setState(() {}),
                  validator: AppValidators.password,
                ),
                const SizedBox(height: AppSpacing.sm),
                Requisitos(password: _nueva.text),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: 'Confirmar contraseña',
                  controller: _confirmar,
                  prefixIcon: Icons.lock_outline,
                  obscureText: !_verConfirmar,
                  onToggleObscure: () =>
                      setState(() => _verConfirmar = !_verConfirmar),
                  validator: _validarConfirmacion,
                ),
                const SizedBox(height: AppSpacing.lg),
                PrimaryButton(
                  label: 'Guardar',
                  isLoading: state.loading,
                  onPressed: _guardar,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String? _validarConfirmacion(String? value) {
    if ((value ?? '').isEmpty) {
      return AppValidators.passwordRequired;
    }
    if (value != _nueva.text) {
      return 'Las contraseñas no coinciden';
    }
    return null;
  }

  Future<void> _guardar() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final ok = await ref
        .read(cambioPasswordProvider.notifier)
        .guardar(actual: _actual.text, nueva: _nueva.text);
    if (!ok || !mounted) return;

    AppSnackbar.showSuccess(context, 'Contraseña actualizada');
    context.pop();
  }
}

/// Lista de requisitos con indicador en vivo. Comparte reglas y textos con el
/// registro, de modo que la contraseña válida se escribe una sola vez.
class Requisitos extends StatelessWidget {
  const Requisitos({super.key, required this.password});

  final String password;

  @override
  Widget build(BuildContext context) {
    final requisitos = AppValidators.passwordRequirements(password);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final requisito in requisitos)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Icon(
                  requisito.met
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  size: 16,
                  color: requisito.met
                      ? AppColors.successGreen
                      : AppColors.secondaryGray,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(requisito.label),
              ],
            ),
          ),
      ],
    );
  }
}

class _Aviso extends StatelessWidget {
  const _Aviso({required this.mensaje});

  final String mensaje;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.errorRed.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.field),
        border: Border.all(color: AppColors.errorRed.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.errorRed, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              mensaje,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.errorRed),
            ),
          ),
        ],
      ),
    );
  }
}
