import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/primary_button.dart';
import 'auth_providers.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key, required this.token});

  final String token;

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscure = true;
  bool _obscureConfirm = true;
  String? _mismatch;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _validateConfirm() {
    final mismatch =
        _passwordController.text.isNotEmpty &&
            _passwordController.text != _confirmController.text
        ? 'Las contraseñas no coinciden.'
        : null;
    if (mismatch != _mismatch) {
      setState(() => _mismatch = mismatch);
    }
  }

  Future<void> _submit() async {
    _validateConfirm();
    if (!(_formKey.currentState?.validate() ?? false) || _mismatch != null) {
      return;
    }
    FocusScope.of(context).unfocus();
    final succeeded = await ref
        .read(passwordRecoveryProvider.notifier)
        .submitNewPassword(
          token: widget.token,
          newPassword: _passwordController.text,
        );
    if (!mounted) {
      return;
    }
    if (succeeded) {
      context.go('/login');
    }
  }

  void _showError(Object error) {
    final message = error is AppException
        ? error.userMessage
        : 'Ocurrió un error inesperado. Inténtalo de nuevo.';
    AppSnackbar.showError(context, message);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(passwordRecoveryProvider, (previous, next) {
      final error = next.error;
      if (error != null && previous?.error != error) {
        _showError(error);
      }
    });

    final recovery = ref.watch(passwordRecoveryProvider);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: widget.token.isEmpty
              ? const _MissingToken()
              : _ResetForm(
                  formKey: _formKey,
                  passwordController: _passwordController,
                  confirmController: _confirmController,
                  obscure: _obscure,
                  obscureConfirm: _obscureConfirm,
                  mismatch: _mismatch,
                  isLoading: recovery.loading,
                  onToggleObscure: () => setState(() => _obscure = !_obscure),
                  onToggleObscureConfirm: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                  onChangedConfirm: _validateConfirm,
                  onSubmit: _submit,
                ),
        ),
      ),
    );
  }
}

class _MissingToken extends StatelessWidget {
  const _MissingToken();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.xl),
        const Icon(Icons.link_off, size: 56, color: AppColors.accent),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Enlace incompleto',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.displayLarge,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Este enlace de restablecimiento no es válido. Solicita uno nuevo '
          'para continuar.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: AppSpacing.lg),
        PrimaryButton(
          label: 'Solicitar un nuevo enlace',
          onPressed: () => context.go('/forgot-password'),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextButton(
          onPressed: () => context.go('/login'),
          child: const Text('Volver a iniciar sesión'),
        ),
      ],
    );
  }
}

class _ResetForm extends StatelessWidget {
  const _ResetForm({
    required this.formKey,
    required this.passwordController,
    required this.confirmController,
    required this.obscure,
    required this.obscureConfirm,
    required this.mismatch,
    required this.isLoading,
    required this.onToggleObscure,
    required this.onToggleObscureConfirm,
    required this.onChangedConfirm,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController passwordController;
  final TextEditingController confirmController;
  final bool obscure;
  final bool obscureConfirm;
  final String? mismatch;
  final bool isLoading;
  final VoidCallback onToggleObscure;
  final VoidCallback onToggleObscureConfirm;
  final VoidCallback onChangedConfirm;
  final Future<void> Function() onSubmit;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.xl),
          const Icon(Icons.password, size: 56, color: AppColors.accent),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Restablece tu contraseña',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.displayLarge,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Elige una contraseña que no hayas usado antes.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: AppSpacing.xl),
          AppTextField(
            label: 'Nueva contraseña',
            controller: passwordController,
            obscureText: obscure,
            onToggleObscure: onToggleObscure,
            prefixIcon: Icons.lock_outline,
            textInputAction: TextInputAction.next,
            enabled: !isLoading,
            validator: AppValidators.passwordError,
            autofillHints: const [AutofillHints.newPassword],
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: 'Confirmar contraseña',
            controller: confirmController,
            errorText: mismatch,
            obscureText: obscureConfirm,
            onToggleObscure: onToggleObscureConfirm,
            prefixIcon: Icons.lock_outline,
            textInputAction: TextInputAction.done,
            enabled: !isLoading,
            onChanged: (_) => onChangedConfirm(),
            onSubmitted: (_) => onSubmit(),
            validator: (_) => mismatch,
            autofillHints: const [AutofillHints.newPassword],
          ),
          const SizedBox(height: AppSpacing.md),
          PrimaryButton(
            label: 'Restablecer contraseña',
            isLoading: isLoading,
            onPressed: () => onSubmit(),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: isLoading ? null : () => context.go('/forgot-password'),
            child: const Text('Solicitar un nuevo enlace'),
          ),
        ],
      ),
    );
  }
}
