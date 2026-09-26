abstract final class AppValidators {
  static final RegExp _emailPattern = RegExp(
    r'^[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$',
  );
  static final RegExp _phonePattern = RegExp(r'^\+?[0-9\s\-()]{7,20}$');

  static const String emailRequired = 'El correo electrónico es obligatorio.';
  static const String emailInvalid = 'Ingresa un correo electrónico válido.';
  static const String passwordRequired = 'La contraseña es obligatoria.';
  static const String passwordMinLength =
      'La contraseña debe tener al menos 8 caracteres.';
  static const String passwordNeedsUppercase =
      'Debe incluir al menos una letra mayúscula.';
  static const String passwordNeedsNumber = 'Debe incluir al menos un número.';
  static const String passwordNeedsSymbol = 'Debe incluir al menos un símbolo.';
  static const String nameRequired = 'El nombre es obligatorio.';
  static const String nameMaxLength =
      'El nombre no puede superar 150 caracteres.';
  static const String phoneInvalid =
      'Ingresa un teléfono válido de hasta 20 caracteres.';
  static const String termsRequired =
      'Debes aceptar la política de privacidad.';

  static String? email(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return emailRequired;
    }
    if (!_emailPattern.hasMatch(text)) {
      return emailInvalid;
    }
    return null;
  }

  static String? password(String? value) => passwordError(value);

  static String? passwordError(String? value) {
    final text = value ?? '';
    if (text.isEmpty) {
      return passwordRequired;
    }
    if (text.length < 8) {
      return passwordMinLength;
    }
    if (!RegExp(r'[A-ZÁ-Ú]').hasMatch(text)) {
      return passwordNeedsUppercase;
    }
    if (!RegExp(r'[0-9]').hasMatch(text)) {
      return passwordNeedsNumber;
    }
    if (!RegExp(r'[^A-Za-z0-9]').hasMatch(text)) {
      return passwordNeedsSymbol;
    }
    return null;
  }

  static String? name(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return nameRequired;
    }
    if (text.length > 150) {
      return nameMaxLength;
    }
    return null;
  }

  static String? phone(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return null;
    }
    if (text.length > 20 || !_phonePattern.hasMatch(text)) {
      return phoneInvalid;
    }
    return null;
  }

  static List<PasswordRequirement> passwordRequirements(String? value) {
    final text = value ?? '';
    return [
      PasswordRequirement('Mínimo 8 caracteres', text.length >= 8),
      PasswordRequirement(
        'Al menos una mayúscula',
        RegExp(r'[A-ZÁ-Ú]').hasMatch(text),
      ),
      PasswordRequirement(
        'Al menos un número',
        RegExp(r'[0-9]').hasMatch(text),
      ),
      PasswordRequirement(
        'Al menos un símbolo',
        RegExp(r'[^A-Za-z0-9]').hasMatch(text),
      ),
    ];
  }
}

class PasswordRequirement {
  const PasswordRequirement(this.label, this.met);

  final String label;
  final bool met;

  bool get unmet => !met;
}
