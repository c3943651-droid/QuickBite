import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.label,
    required this.controller,
    this.hintText,
    this.errorText,
    this.keyboardType,
    this.obscureText = false,
    this.onToggleObscure,
    this.prefixIcon,
    this.enabled = true,
    this.onChanged,
    this.onSubmitted,
    this.textInputAction,
    this.validator,
    this.autofillHints,
    this.maxLength,
  });

  final String label;
  final TextEditingController controller;
  final String? hintText;
  final String? errorText;
  final TextInputType? keyboardType;
  final bool obscureText;
  final VoidCallback? onToggleObscure;
  final IconData? prefixIcon;
  final bool enabled;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputAction? textInputAction;
  final FormFieldValidator<String>? validator;
  final Iterable<String>? autofillHints;
  final int? maxLength;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      enabled: enabled,
      keyboardType: keyboardType,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      textInputAction: textInputAction,
      validator: validator,
      autofillHints: autofillHints,
      maxLength: maxLength,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        errorText: errorText,
        prefixIcon: prefixIcon == null ? null : Icon(prefixIcon, size: 20),
        suffixIcon: onToggleObscure == null
            ? null
            : IconButton(
                onPressed: onToggleObscure,
                icon: Icon(
                  obscureText
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 20,
                ),
                tooltip: obscureText
                    ? 'Mostrar contraseña'
                    : 'Ocultar contraseña',
                constraints: const BoxConstraints.tightFor(
                  width: AppSizes.minTapTarget,
                  height: AppSizes.minTapTarget,
                ),
              ),
      ),
    );
  }
}
