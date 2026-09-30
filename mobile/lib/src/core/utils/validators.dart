abstract final class AppValidators {
  static final RegExp _emailPattern = RegExp(
    r'^[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$',
  );
  static final RegExp _phonePattern = RegExp(r'^\+?[0-9\s\-()]{7,20}$');
  static final RegExp _letraPattern = RegExp(r'[A-Za-zÁÉÍÓÚÜÑáéíóúüñ]');

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

  /// Tarjeta simulada (05#D-08): valida el número con dígitos sueltos o con
  /// la máscara `XXXX XXXX XXXX XXXX`, siempre que pase el dígito Luhn.
  static bool tarjetaNumero(String? value) {
    final digitos = _soloDigitos(value);
    return digitos.length == 16 && _luhn(digitos);
  }

  /// Vigencia `MM/AA` (o `MMAA`): mes de 01 a 12 y no anterior al mes en curso.
  static bool tarjetaExpiracion(String? value) {
    final digitos = _soloDigitos(value);
    if (digitos.length != 4) {
      return false;
    }
    final mes = int.parse(digitos.substring(0, 2));
    if (mes < 1 || mes > 12) {
      return false;
    }
    final anio = 2000 + int.parse(digitos.substring(2));
    final ahora = DateTime.now();
    if (anio < ahora.year) {
      return false;
    }
    return anio != ahora.year || mes >= ahora.month;
  }

  /// CVC de 3 o 4 dígitos, según la red de la tarjeta.
  static bool tarjetaCvv(String? value) {
    final digitos = _soloDigitos(value);
    return digitos.length >= 3 && digitos.length <= 4;
  }

  /// Nombre impreso en la tarjeta: al menos dos caracteres y una letra.
  static bool tarjetaNombre(String? value) {
    final text = value?.trim() ?? '';
    return text.length >= 2 && _letraPattern.hasMatch(text);
  }

  static String _soloDigitos(String? value) =>
      (value ?? '').replaceAll(RegExp(r'\D'), '');

  /// Algoritmo Luhn: descarta números con un dígito verificador erróneo.
  static bool _luhn(String digitos) {
    var suma = 0;
    var doblar = false;
    for (var i = digitos.length - 1; i >= 0; i--) {
      var digito = digitos.codeUnitAt(i) - 48;
      if (doblar) {
        digito *= 2;
        if (digito > 9) {
          digito -= 9;
        }
      }
      suma += digito;
      doblar = !doblar;
    }
    return suma % 10 == 0;
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
