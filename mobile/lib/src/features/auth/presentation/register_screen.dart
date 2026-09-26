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

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  static const _roles = <({String value, String label})>[
    (value: 'cliente', label: 'Cliente'),
    (value: 'repartidor', label: 'Repartidor'),
  ];

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  String _role = 'cliente';
  bool _obscure = true;
  bool _obscureConfirm = true;
  bool _acceptedTerms = false;
  bool _showPasswordRules = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    if (!_acceptedTerms) {
      AppSnackbar.showError(context, AppValidators.termsRequired);
      return;
    }
    FocusScope.of(context).unfocus();
    await ref
        .read(sessionProvider.notifier)
        .register(
          nombre: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          telefono: _phoneController.text.trim().isEmpty
              ? null
              : _phoneController.text.trim(),
          rol: _role,
        );
  }

  String? _confirmPasswordError(String? value) {
    final confirmation = value ?? '';
    if (confirmation.isEmpty) {
      return 'Confirma tu contraseña.';
    }
    if (confirmation != _passwordController.text) {
      return 'Las contraseñas no coinciden.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);

    ref.listen(sessionProvider, (previous, next) {
      if (next.hasError && previous?.error != next.error) {
        _showError(next.error!);
        return;
      }
      if (!next.isLoading && !next.hasError && previous?.isLoading == true) {
        AppSnackbar.showSuccess(
          context,
          '¡Cuenta creada! Inicia sesión para continuar.',
        );
        context.go('/login');
      }
    });

    final isLoading = session.isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Crea tu cuenta')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTextField(
                  label: 'Nombre completo',
                  controller: _nameController,
                  prefixIcon: Icons.person_outline,
                  textInputAction: TextInputAction.next,
                  enabled: !isLoading,
                  validator: AppValidators.name,
                  autofillHints: const [AutofillHints.name],
                  maxLength: 150,
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: 'Correo electrónico',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.mail_outline,
                  textInputAction: TextInputAction.next,
                  enabled: !isLoading,
                  validator: AppValidators.email,
                  autofillHints: const [AutofillHints.email],
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: 'Teléfono (opcional)',
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  prefixIcon: Icons.phone_outlined,
                  textInputAction: TextInputAction.next,
                  enabled: !isLoading,
                  validator: AppValidators.phone,
                  maxLength: 20,
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: 'Contraseña',
                  controller: _passwordController,
                  obscureText: _obscure,
                  onToggleObscure: () => setState(() => _obscure = !_obscure),
                  prefixIcon: Icons.lock_outline,
                  textInputAction: TextInputAction.next,
                  enabled: !isLoading,
                  onChanged: (_) => setState(() => _showPasswordRules = true),
                  validator: AppValidators.password,
                ),
                if (_showPasswordRules) ...[
                  const SizedBox(height: AppSpacing.sm),
                  _PasswordRequirements(password: _passwordController.text),
                ],
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: 'Confirmar contraseña',
                  controller: _confirmController,
                  obscureText: _obscureConfirm,
                  onToggleObscure: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                  prefixIcon: Icons.lock_outline,
                  textInputAction: TextInputAction.done,
                  enabled: !isLoading,
                  onChanged: (_) => setState(() {}),
                  validator: _confirmPasswordError,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Quiero registrarme como',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                SegmentedButton<String>(
                  segments: [
                    for (final role in _roles)
                      ButtonSegment(value: role.value, label: Text(role.label)),
                  ],
                  selected: {_role},
                  showSelectedIcon: false,
                  onSelectionChanged: isLoading
                      ? null
                      : (selection) => setState(() => _role = selection.first),
                ),
                const SizedBox(height: AppSpacing.md),
                CheckboxListTile(
                  value: _acceptedTerms,
                  onChanged: isLoading
                      ? null
                      : (value) =>
                            setState(() => _acceptedTerms = value ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  activeColor: AppColors.quickbiteOrange,
                  title: const Text('Acepto la política de privacidad'),
                  subtitle: TextButton(
                    onPressed: () => AppSnackbar.showInfo(
                      context,
                      'La política de privacidad estará disponible próximamente.',
                    ),
                    child: const Text('Ver política'),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                PrimaryButton(
                  label: 'Registrarse',
                  isLoading: isLoading,
                  onPressed: _submit,
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('¿Ya tienes cuenta?'),
                    TextButton(
                      onPressed: isLoading ? null : () => context.go('/login'),
                      child: const Text('Iniciar sesión'),
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

  void _showError(Object error) {
    if (error is ConflictException) {
      AppSnackbar.showError(context, 'El correo ya está registrado');
      return;
    }
    if (error is ValidationException) {
      final messages = error.fieldErrors.values.expand((list) => list).toList();
      AppSnackbar.showError(
        context,
        messages.isEmpty ? error.userMessage : messages.first,
      );
      return;
    }
    AppSnackbar.showError(
      context,
      error is AppException
          ? error.userMessage
          : 'Ocurrió un error inesperado. Inténtalo de nuevo.',
    );
  }
}

class _PasswordRequirements extends StatelessWidget {
  const _PasswordRequirements({required this.password});

  final String password;

  @override
  Widget build(BuildContext context) {
    final requirements = AppValidators.passwordRequirements(password);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final requirement in requirements)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Icon(
                  requirement.met
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  size: 16,
                  color: requirement.met
                      ? AppColors.successGreen
                      : AppColors.secondaryGray,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  requirement.label,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
      ],
    );
  }
}
