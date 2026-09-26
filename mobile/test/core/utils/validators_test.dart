import 'package:flutter_test/flutter_test.dart';
import 'package:quickbite_mobile/src/core/utils/validators.dart';

void main() {
  group('AppValidators.email', () {
    test('acepta correos válidos', () {
      expect(AppValidators.email('carlos@quickbite.mx'), isNull);
      expect(AppValidators.email('  carlos+pedidos@sub.dominio.com  '), isNull);
    });

    test('rechaza vacío, nulo y formatos inválidos', () {
      expect(AppValidators.email(null), AppValidators.emailRequired);
      expect(AppValidators.email('   '), AppValidators.emailRequired);
      expect(AppValidators.email('carlos@'), AppValidators.emailInvalid);
      expect(AppValidators.email('sin-arroba.com'), AppValidators.emailInvalid);
      expect(AppValidators.email('a@b'), AppValidators.emailInvalid);
    });
  });

  group('AppValidators.password', () {
    test('acepta contraseña que cumple los cuatro requisitos', () {
      expect(AppValidators.password('Password1!'), isNull);
    });

    test('reporta cada requisito incumplido en orden', () {
      expect(AppValidators.password(null), AppValidators.passwordRequired);
      expect(AppValidators.password(''), AppValidators.passwordRequired);
      expect(AppValidators.password('Ab1!'), AppValidators.passwordMinLength);
      expect(
        AppValidators.password('password1!'),
        AppValidators.passwordNeedsUppercase,
      );
      expect(
        AppValidators.password('Password!'),
        AppValidators.passwordNeedsNumber,
      );
      expect(
        AppValidators.password('Password1'),
        AppValidators.passwordNeedsSymbol,
      );
    });

    test('acepta acentos en la letra mayúscula', () {
      expect(AppValidators.password('Ábc1234!'), isNull);
    });
  });

  group('AppValidators.passwordRequirements', () {
    test('marca cumplidos los requisitos de una contraseña válida', () {
      final requirements = AppValidators.passwordRequirements('Password1!');
      expect(requirements, hasLength(4));
      expect(requirements.every((r) => r.met), isTrue);
      expect(requirements.every((r) => !r.unmet), isTrue);
    });

    test('marca pendientes los requisitos no cumplidos', () {
      final requirements = AppValidators.passwordRequirements('abc');
      expect(requirements.where((r) => r.unmet), hasLength(4));
    });

    test('cumple solo los requisitos ya alcanzados', () {
      final requirements = AppValidators.passwordRequirements('Password1');
      expect(requirements.where((r) => r.met).map((r) => r.label), [
        'Mínimo 8 caracteres',
        'Al menos una mayúscula',
        'Al menos un número',
      ]);
    });
  });

  group('AppValidators.name', () {
    test('exige nombre y limita a 150 caracteres', () {
      expect(AppValidators.name(null), AppValidators.nameRequired);
      expect(AppValidators.name('  '), AppValidators.nameRequired);
      expect(AppValidators.name('Carlos'), isNull);
      expect(AppValidators.name('a' * 151), AppValidators.nameMaxLength);
      expect(AppValidators.name('a' * 150), isNull);
    });
  });

  group('AppValidators.phone', () {
    test('es opcional pero debe tener formato válido', () {
      expect(AppValidators.phone(null), isNull);
      expect(AppValidators.phone(''), isNull);
      expect(AppValidators.phone('55 1234 5678'), isNull);
      expect(AppValidators.phone('+52 55 1234 5678'), isNull);
      expect(AppValidators.phone('abc12345'), AppValidators.phoneInvalid);
      expect(AppValidators.phone('1' * 21), AppValidators.phoneInvalid);
    });
  });
}
