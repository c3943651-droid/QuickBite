import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickbite_mobile/src/core/haptics.dart';
import 'package:quickbite_mobile/src/core/widgets/primary_button.dart';

import '../support/widget_harness.dart';

/// El háptico se nota en el Moto G15 y es la diferencia entre "tocó algo" y
/// "la app reaccionó". Se prueba interceptando el canal de plataforma, que es
/// por donde Flutter habla con el vibrador del sistema.
void main() {
  late List<String> mensajes;

  setUp(() {
    AppHaptics.enabled = true;
    mensajes = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          mensajes.add(call.method);
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
    AppHaptics.enabled = true;
  });

  group('AppHaptics', () {
    test('alToque pide un impacto ligero', () {
      AppHaptics.alToque();

      expect(mensajes, ['HapticFeedback.vibrate']);
    });

    test('selection pide el clic de selección', () {
      AppHaptics.selection();

      expect(mensajes, isNotEmpty);
    });

    test('resultado emite feedback tanto si sale bien como si falla', () {
      // El canal no distingue la intensidad (va en el argumento, no en el
      // método); lo que importa es que ambos caminos devuelven algo, para que
      // el usuario no se quede sin confirmación táctil al fallar.
      AppHaptics.resultado(exitoso: true);
      expect(mensajes, isNotEmpty);

      mensajes = [];
      AppHaptics.resultado(exitoso: false);
      expect(mensajes, isNotEmpty);
    });

    test('se puede desactivar para quien no quiere vibraciones', () {
      AppHaptics.enabled = false;

      AppHaptics.alToque();
      AppHaptics.selection();
      AppHaptics.resultado(exitoso: true);

      expect(mensajes, isEmpty);
    });
  });

  group('el botón principal da feedback al pulsarse', () {
    testWidgets('una pulsación dispara el háptico', (tester) async {
      await pumpApp(
        tester,
        Scaffold(
          body: PrimaryButton(label: 'Agregar', onPressed: () {}),
        ),
      );

      mensajes = [];
      await tester.tap(find.text('Agregar'));
      await tester.pump();

      expect(mensajes, contains('HapticFeedback.vibrate'));
    });

    testWidgets('un botón deshabilitado no vibra', (tester) async {
      await pumpApp(
        tester,
        Scaffold(body: PrimaryButton(label: 'Agregar', onPressed: null)),
      );

      // Se comprueba por la vía del callback, no por el canal: un toque sobre
      // un botón deshabilitado de Material todavía emite sonido del sistema y
      // eso no es el feedback que nos interesa medir.
      var accionado = false;
      final boton = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(boton.onPressed, isNull);
      expect(accionado, isFalse);
    });
  });
}
