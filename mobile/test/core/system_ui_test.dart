import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickbite_mobile/src/core/system_ui.dart';
import 'package:quickbite_mobile/src/core/theme/app_colors.dart';
import 'package:quickbite_mobile/src/core/theme/app_radius.dart';

/// Android 15 (API 35) fuerza edge-to-edge: la app dibuja detrás de la barra de
/// estado y del gesto inferior. Si no se declara, el contenido queda bajo la
/// muesca o la barra de navegación se solapa con la interfaz.
void main() {
  group('AppSystemUi (edge-to-edge, Android 15)', () {
    test('el modo edge-to-edge es el que se pide al sistema', () {
      expect(AppSystemUi.modo, SystemUiMode.edgeToEdge);
    });

    test('las barras del sistema son transparentes', () {
      final estilo = AppSystemUi.estiloPara(Brightness.light);

      expect(estilo.statusBarColor, Colors.transparent);
      expect(estilo.systemNavigationBarColor, Colors.transparent);
      expect(estilo.statusBarIconBrightness, Brightness.dark);
    });

    testWidgets('aplicar pide edge-to-edge al sistema', (tester) async {
      var modoPedido = '';
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
            if (call.method == 'SystemChrome.setEnabledSystemUIMode') {
              modoPedido = '${call.arguments}';
            }
            return null;
          });
      addTearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null);
      });

      await AppSystemUi.aplicar();

      expect(modoPedido, contains('edgeToEdge'));
    });
  });

  group('tarjetas de superficie compartida', () {
    test('el radio de tarjeta es 18 px y el de campo 12 px', () {
      expect(AppRadius.card, 18);
      expect(AppRadius.field, 12);
    });

    test('el borde de marca es el pizarra 200', () {
      expect(AppColors.border, const Color(0xFFE2E8F0));
    });
  });

  group('modo oscuro', () {
    test('los iconos de la barra se vuelven claros', () {
      final estilo = AppSystemUi.estiloPara(Brightness.dark);

      expect(estilo.statusBarIconBrightness, Brightness.light);
      expect(estilo.systemNavigationBarIconBrightness, Brightness.light);
    });
  });
}
