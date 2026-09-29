import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/image_picker_sheet.dart';
import '../../../core/widgets/primary_button.dart';
import 'auth_providers.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _telefonoController = TextEditingController();

  @override
  void dispose() {
    _nombreController.dispose();
    _telefonoController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    FocusScope.of(context).unfocus();
    final saved = await ref
        .read(profileEditProvider.notifier)
        .save(
          nombre: _nombreController.text.trim(),
          telefono: _telefonoController.text.trim(),
        );
    if (!mounted) {
      return;
    }
    if (saved) {
      AppSnackbar.showSuccess(context, 'Perfil actualizado');
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileProvider);
    final edit = ref.watch(profileEditProvider);

    ref.listen(profileEditProvider, (previous, next) {
      final failure = next.error;
      if (failure == null || previous?.error == failure) {
        return;
      }
      final message = failure is AppException
          ? failure.userMessage
          : 'No pudimos guardar tus cambios. Inténtalo de nuevo.';
      AppSnackbar.showError(context, message);
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Editar perfil')),
      body: profile.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: PrimaryButton(
            label: 'Reintentar',
            onPressed: () => ref.invalidate(userProfileProvider),
          ),
        ),
        data: (data) => _Form(
          formKey: _formKey,
          nombreController: _nombreController,
          telefonoController: _telefonoController,
          email: data.email,
          initialNombre: data.nombre,
          initialTelefono: data.telefono,
          isLoading: edit.loading,
          onSave: _save,
        ),
      ),
    );
  }
}

class _Form extends StatefulWidget {
  const _Form({
    required this.formKey,
    required this.nombreController,
    required this.telefonoController,
    required this.email,
    required this.initialNombre,
    required this.initialTelefono,
    required this.isLoading,
    required this.onSave,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nombreController;
  final TextEditingController telefonoController;
  final String email;
  final String initialNombre;
  final String? initialTelefono;
  final bool isLoading;
  final Future<void> Function() onSave;

  @override
  State<_Form> createState() => _FormState();
}

class _FormState extends State<_Form> {
  late final TextEditingController _emailController;

  /// Ruta de la imagen recién elegida. El backend todavía no expone carga de
  /// avatar, así que la vista previa es local: al menos la persona usuaria ve
  /// lo que eligió en lugar de un icono que no cambia nunca.
  String? _avatarLocal;

  @override
  void initState() {
    super.initState();
    widget.nombreController.text = widget.initialNombre;
    widget.telefonoController.text = widget.initialTelefono ?? '';
    _emailController = TextEditingController(text: widget.email);
  }

  Future<void> _elegirImagen() async {
    final ruta = await mostrarSelectorImagen(context);
    if (ruta == null || !mounted) return;
    setState(() => _avatarLocal = ruta);
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Form(
        key: widget.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  _Avatar(ruta: _avatarLocal),
                  IconButton.filled(
                    tooltip: 'Cambiar',
                    icon: const Icon(Icons.photo_camera_outlined, size: 18),
                    onPressed: _elegirImagen,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              label: 'Nombre',
              controller: widget.nombreController,
              prefixIcon: Icons.person_outline,
              textInputAction: TextInputAction.next,
              enabled: !widget.isLoading,
              validator: AppValidators.name,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: 'Teléfono',
              controller: widget.telefonoController,
              keyboardType: TextInputType.phone,
              prefixIcon: Icons.phone_outlined,
              textInputAction: TextInputAction.done,
              enabled: !widget.isLoading,
              onSubmitted: (_) => widget.onSave(),
              validator: AppValidators.phone,
              autofillHints: const [AutofillHints.telephoneNumber],
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: 'Correo electrónico',
              controller: _emailController,
              prefixIcon: Icons.mail_outline,
              enabled: false,
            ),
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(
              label: 'Guardar cambios',
              isLoading: widget.isLoading,
              onPressed: () => widget.onSave(),
            ),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.ruta});

  final String? ruta;

  @override
  Widget build(BuildContext context) {
    final ruta = this.ruta;
    return CircleAvatar(
      radius: 44,
      backgroundColor: AppColors.accent,
      backgroundImage: ruta == null ? null : FileImage(File(ruta)),
      child: ruta == null
          ? const Icon(Icons.person, color: Colors.white, size: 46)
          : null,
    );
  }
}
