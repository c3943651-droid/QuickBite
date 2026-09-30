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

/// Texto único de confirmación: no distingue entre correo existente y
/// inexistente para no filtrar qué correos están registrados (05#D-04).
const String _genericConfirmation = 'Si el correo existe, recibirás un enlace';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    FocusScope.of(context).unfocus();
    await ref
        .read(passwordRecoveryProvider.notifier)
        .requestLink(email: _emailController.text.trim());
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
          child: recovery.sent
              ? _Confirmation(email: _emailController.text.trim())
              : _RequestForm(
                  formKey: _formKey,
                  emailController: _emailController,
                  isLoading: recovery.loading,
                  onSubmit: _submit,
                ),
        ),
      ),
    );
  }
}

class _RequestForm extends StatelessWidget {
  const _RequestForm({
    required this.formKey,
    required this.emailController,
    required this.isLoading,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final bool isLoading;
  final Future<void> Function() onSubmit;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.xl),
          const Icon(Icons.lock_reset, size: 56, color: AppColors.accent),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Recupera tu contraseña',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.displayLarge,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Te enviaremos un enlace para crear una contraseña nueva.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: AppSpacing.xl),
          AppTextField(
            label: 'Correo electrónico',
            controller: emailController,
            hintText: 'tucorreo@ejemplo.com',
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icons.mail_outline,
            textInputAction: TextInputAction.done,
            enabled: !isLoading,
            onSubmitted: (_) => onSubmit(),
            validator: AppValidators.email,
            autofillHints: const [AutofillHints.email],
          ),
          const SizedBox(height: AppSpacing.md),
          PrimaryButton(
            label: 'Enviar enlace',
            isLoading: isLoading,
            onPressed: () => onSubmit(),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: isLoading ? null : () => context.go('/login'),
            child: const Text('Volver a iniciar sesión'),
          ),
        ],
      ),
    );
  }
}

class _Confirmation extends StatelessWidget {
  const _Confirmation({required this.email});

  final String email;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.xl),
        const Icon(
          Icons.mark_email_read_outlined,
          size: 56,
          color: AppColors.accent,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Revisa tu correo',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.displayLarge,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          _genericConfirmation,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        if (email.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            email,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        Text(
          'El enlace caduca por seguridad. Revisa también la carpeta de spam.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: AppSpacing.lg),
        PrimaryButton(
          label: 'Volver a iniciar sesión',
          onPressed: () => context.go('/login'),
        ),
      ],
    );
  }
}
