import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/primary_button.dart';
import 'auth_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;
  bool _rememberMe = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    FocusScope.of(context).unfocus();
    await ref
        .read(sessionProvider.notifier)
        .login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
  }

  void _showError(Object? error) {
    if (error is UnauthorizedException || error is ValidationException) {
      AppSnackbar.showError(
        context,
        'Las credenciales son incorrectas. Inténtalo de nuevo.',
      );
      return;
    }
    if (error is AccountLockedException) {
      AppSnackbar.showError(context, error.message);
      return;
    }
    final message = error is AppException
        ? error.userMessage
        : 'Ocurrió un error inesperado. Inténtalo de nuevo.';
    AppSnackbar.showError(context, message);
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);

    ref.listen(sessionProvider, (previous, next) {
      final error = next.error;
      if (error != null && previous?.error != error) {
        _showError(error);
        return;
      }
      if (next.value != null && previous?.value == null) {
        context.go('/home');
      }
    });

    final isLoading = session.isLoading;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.xl),
                const Icon(
                  Icons.restaurant,
                  size: 56,
                  color: AppColors.quickbiteOrange,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'QuickBite',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.displayLarge,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Bienvenido de nuevo',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: AppSpacing.xl),
                AppTextField(
                  label: 'Correo electrónico',
                  controller: _emailController,
                  hintText: 'tucorreo@ejemplo.com',
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.mail_outline,
                  textInputAction: TextInputAction.next,
                  enabled: !isLoading,
                  validator: AppValidators.email,
                  autofillHints: const [AutofillHints.email],
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: 'Contraseña',
                  controller: _passwordController,
                  obscureText: _obscure,
                  onToggleObscure: () => setState(() => _obscure = !_obscure),
                  prefixIcon: Icons.lock_outline,
                  textInputAction: TextInputAction.done,
                  enabled: !isLoading,
                  onSubmitted: (_) => _submit(),
                  validator: AppValidators.password,
                  autofillHints: const [AutofillHints.password],
                ),
                const SizedBox(height: AppSpacing.sm),
                SwitchListTile(
                  value: _rememberMe,
                  onChanged: isLoading
                      ? null
                      : (value) => setState(() => _rememberMe = value),
                  title: const Text('Mantener sesión iniciada'),
                  contentPadding: EdgeInsets.zero,
                  activeThumbColor: AppColors.quickbiteOrange,
                ),
                const SizedBox(height: AppSpacing.md),
                PrimaryButton(
                  label: 'Iniciar sesión',
                  isLoading: isLoading,
                  onPressed: _submit,
                ),
                const SizedBox(height: AppSpacing.sm),
                TextButton(
                  onPressed: isLoading
                      ? null
                      : () => AppSnackbar.showInfo(
                          context,
                          'La recuperación de contraseña estará disponible próximamente.',
                        ),
                  child: const Text('¿Olvidaste tu contraseña?'),
                ),
                const Divider(height: AppSpacing.xl),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('¿No tienes cuenta?'),
                    TextButton(
                      onPressed: isLoading
                          ? null
                          : () => context.push('/register'),
                      child: const Text('Crear cuenta'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
