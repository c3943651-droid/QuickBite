import 'dart:async';

import 'package:intl/date_symbol_data_local.dart';

/// `intl` no trae los datos de idioma de `es`; sin inicializarlos, cualquier
/// `DateFormat(..., 'es')` lanza `LocaleDataException` y las pantallas con fecha
/// (historial de pedidos, historial de entregas) fallan al pintarse.
///
/// Lo hace `lib/main.dart` en la app real; aquí se replica para que los tests
/// recorran el mismo camino que el usuario.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  await initializeDateFormatting('es');
  return testMain();
}
