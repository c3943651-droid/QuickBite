import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickbite_mobile/src/core/error/app_exception.dart';
import 'package:quickbite_mobile/src/core/session/token_storage.dart';
import 'package:quickbite_mobile/src/features/address/domain/address_entities.dart';
import 'package:quickbite_mobile/src/features/address/domain/address_repository.dart';
import 'package:quickbite_mobile/src/features/address/presentation/address_providers.dart';
import 'package:quickbite_mobile/src/features/auth/domain/auth_entities.dart';
import 'package:quickbite_mobile/src/features/auth/domain/auth_repository.dart';
import 'package:quickbite_mobile/src/features/auth/presentation/auth_providers.dart';
import 'package:quickbite_mobile/src/features/catalog/presentation/catalog_providers.dart';
import 'package:quickbite_mobile/src/features/shell/app_router.dart';

import '../../../support/catalog_fakes.dart';
import '../../../support/fake_token_storage.dart';

const _casa = Address(
  id: '11111111-1111-1111-1111-111111111111',
  alias: 'Casa',
  calle: 'Av. Insurgentes Sur',
  numero: '123',
  ciudad: 'CDMX',
  esPredeterminada: true,
);

const _oficina = Address(
  id: '22222222-2222-2222-2222-222222222222',
  alias: 'Oficina',
  calle: 'Paseo de la Reforma',
  numero: '222',
  ciudad: 'CDMX',
  esPredeterminada: false,
);

typedef CreateAddressCall = ({
  String? alias,
  String calle,
  String? numero,
  String? referencia,
  String ciudad,
  double? latitud,
  double? longitud,
  bool esPredeterminada,
});

typedef UpdateAddressCall = ({
  String? alias,
  String? calle,
  String? numero,
  String? referencia,
  String? ciudad,
  double? latitud,
  double? longitud,
});

class FakeAddressRepository implements AddressRepository {
  FakeAddressRepository({
    this.addresses = const [_casa, _oficina],
    this.listError,
    this.mutationError,
  });

  List<Address> addresses;
  Object? listError;
  final Object? mutationError;
  final List<String> setDefaultCalls = [];
  final List<String> deleteCalls = [];
  final List<CreateAddressCall> creates = [];
  final List<UpdateAddressCall> updates = [];

  @override
  Future<List<Address>> fetchAddresses() async {
    if (listError != null) {
      throw listError!;
    }
    return addresses;
  }

  @override
  Future<Address> createAddress({
    String? alias,
    required String calle,
    String? numero,
    String? referencia,
    required String ciudad,
    double? latitud,
    double? longitud,
    bool esPredeterminada = false,
  }) async {
    creates.add((
      alias: alias,
      calle: calle,
      numero: numero,
      referencia: referencia,
      ciudad: ciudad,
      latitud: latitud,
      longitud: longitud,
      esPredeterminada: esPredeterminada,
    ));
    if (mutationError != null) {
      throw mutationError!;
    }
    return _casa;
  }

  @override
  Future<Address> updateAddress({
    required String id,
    String? alias,
    String? calle,
    String? numero,
    String? referencia,
    String? ciudad,
    double? latitud,
    double? longitud,
  }) async {
    updates.add((
      alias: alias,
      calle: calle,
      numero: numero,
      referencia: referencia,
      ciudad: ciudad,
      latitud: latitud,
      longitud: longitud,
    ));
    if (mutationError != null) {
      throw mutationError!;
    }
    return _casa;
  }

  @override
  Future<void> deleteAddress(String id) async {
    deleteCalls.add(id);
    if (mutationError != null) {
      throw mutationError!;
    }
  }

  @override
  Future<Address> setDefaultAddress(String id) async {
    setDefaultCalls.add(id);
    if (mutationError != null) {
      throw mutationError!;
    }
    return _casa;
  }
}

void main() {
  late FakeAddressRepository addresses;

  const session = AuthSession(
    tokens: AuthTokens(accessToken: 'a', refreshToken: 'r', expiresIn: 3600),
    user: AuthUser(
      id: '33333333-3333-3333-3333-333333333333',
      nombre: 'Carlos Pérez',
      email: 'carlos@quickbite.mx',
      rol: 'cliente',
    ),
  );

  setUp(() => addresses = FakeAddressRepository());

  Future<void> fill(WidgetTester tester, String label, String value) async {
    await tester.enterText(
      find.ancestor(of: find.text(label), matching: find.byType(TextFormField)),
      value,
    );
  }

  Future<void> pumpAt(WidgetTester tester, String location) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final container = ProviderContainer(
      overrides: [
        addressRepositoryProvider.overrideWithValue(addresses),
        authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
        tokenStorageProvider.overrideWithValue(InMemoryTokenStorage()),
        catalogRepositoryProvider.overrideWithValue(FakeCatalogRepository()),
      ],
    );
    addTearDown(container.dispose);

    final router = createRouter(() async => session);
    router.go(location);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('AddressesScreen (07.1 SCR-PROF-06)', () {
    testWidgets('lista alias, dirección completa y badge de predeterminada', (
      tester,
    ) async {
      await pumpAt(tester, '/addresses');

      expect(find.text('Casa'), findsOneWidget);
      expect(find.text('Av. Insurgentes Sur 123'), findsOneWidget);
      expect(find.text('CDMX'), findsNWidgets(2));
      expect(find.text('Predeterminada'), findsOneWidget);
      expect(find.text('Oficina'), findsOneWidget);
      expect(find.text('Paseo de la Reforma 222'), findsOneWidget);
      // La predeterminada no ofrece volver a marcarse: estrella rellena.
      expect(find.byIcon(Icons.star), findsOneWidget);
      expect(find.byIcon(Icons.star_border), findsOneWidget);
    });

    testWidgets('la vacía ofrece agregar y no muestra tarjetas', (
      tester,
    ) async {
      addresses = FakeAddressRepository(addresses: const []);
      await pumpAt(tester, '/addresses');

      expect(find.text('Aún no tienes direcciones'), findsOneWidget);
      expect(find.text('Agregar'), findsOneWidget);
      expect(find.text('Agregar dirección'), findsOneWidget);
      expect(find.text('Casa'), findsNothing);
    });

    testWidgets('un error de carga muestra reintentar y revalida', (
      tester,
    ) async {
      addresses = FakeAddressRepository(
        listError: const NetworkException('Sin conexión'),
      );
      await pumpAt(tester, '/addresses');

      expect(find.text('Reintentar'), findsOneWidget);

      addresses.listError = null;
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();

      expect(find.text('Casa'), findsOneWidget);
    });

    testWidgets('marca predeterminada la tarjeta no predeterminada', (
      tester,
    ) async {
      await pumpAt(tester, '/addresses');

      final star = find.byIcon(Icons.star_border);
      expect(star, findsOneWidget);
      await tester.tap(star);
      await tester.pumpAndSettle();

      expect(addresses.setDefaultCalls, [_oficina.id]);
    });

    testWidgets('la tarjeta predeterminada no ofrece volver a marcarla', (
      tester,
    ) async {
      await pumpAt(tester, '/addresses');

      final predeterminada = find.byIcon(Icons.star);
      expect(predeterminada, findsOneWidget);
      await tester.tap(predeterminada, warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(addresses.setDefaultCalls, isEmpty);
    });

    testWidgets('eliminar exige confirmación y luego llama al repositorio', (
      tester,
    ) async {
      await pumpAt(tester, '/addresses');

      await tester.tap(find.byIcon(Icons.delete_outline).first);
      await tester.pumpAndSettle();

      expect(find.text('Cancelar'), findsOneWidget);
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(addresses.deleteCalls, isEmpty);

      await tester.tap(find.byIcon(Icons.delete_outline).first);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Eliminar'));
      await tester.pumpAndSettle();

      expect(addresses.deleteCalls, [_casa.id]);
    });

    testWidgets('tocar el lápiz de edición navega a la edición de esa dirección', (
      tester,
    ) async {
      await pumpAt(tester, '/addresses');

      await tester.tap(find.byIcon(Icons.edit_outlined).first);
      await tester.pumpAndSettle();

      expect(find.text('Editar dirección'), findsOneWidget);
      expect(find.text('Eliminar'), findsOneWidget);
    });

    testWidgets('el FAB lleva al formulario de creación', (tester) async {
      await pumpAt(tester, '/addresses');

      await tester.tap(find.text('Agregar dirección'));
      await tester.pumpAndSettle();

      expect(find.text('Agregar dirección'), findsOneWidget);
      expect(find.text('Guardar'), findsOneWidget);
      expect(find.text('Eliminar'), findsNothing);
    });
  });

  group('AddressFormScreen (07.1 SCR-PROF-07)', () {
    testWidgets('crear valida calle y ciudad antes de enviar', (tester) async {
      await pumpAt(tester, '/addresses/new');

      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      expect(find.text('La calle es obligatoria.'), findsOneWidget);
      expect(find.text('La ciudad es obligatoria.'), findsOneWidget);
      expect(addresses.creates, isEmpty);
    });

    testWidgets('crear envía los campos escritos y vuelve a la lista', (
      tester,
    ) async {
      await pumpAt(tester, '/addresses/new');

      await fill(tester, 'Alias', 'Casa');
      await fill(tester, 'Calle', 'Av. Insurgentes Sur');
      await fill(tester, 'Número', '123');
      await fill(tester, 'Ciudad', 'CDMX');

      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      expect(addresses.creates, hasLength(1));
      final request = addresses.creates.single;
      expect(request.alias, 'Casa');
      expect(request.calle, 'Av. Insurgentes Sur');
      expect(request.numero, '123');
      expect(request.ciudad, 'CDMX');
      expect(find.text('Casa'), findsOneWidget);
    });

    testWidgets('rechaza coordenadas que no son números', (tester) async {
      await pumpAt(tester, '/addresses/new');

      await fill(tester, 'Calle', 'Av. Insurgentes Sur');
      await fill(tester, 'Ciudad', 'CDMX');
      await fill(tester, 'Latitud', 'norte');

      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      expect(find.text('No es un número'), findsOneWidget);
      expect(addresses.creates, isEmpty);
    });

    testWidgets('editar precarga los valores y ofrece eliminar', (
      tester,
    ) async {
      await pumpAt(tester, '/addresses/${_oficina.id}/edit');

      expect(find.text('Editar dirección'), findsOneWidget);
      expect(find.text('Oficina'), findsOneWidget);
      expect(find.text('Eliminar'), findsOneWidget);
      expect(
        tester.widget<CheckboxListTile>(find.byType(CheckboxListTile)).value,
        isFalse,
      );
    });

    testWidgets('editar actualiza y regresa a la lista', (tester) async {
      await pumpAt(tester, '/addresses/${_oficina.id}/edit');

      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      expect(addresses.updates, hasLength(1));
      expect(addresses.updates.single.calle, 'Paseo de la Reforma');
      expect(find.text('Casa'), findsOneWidget);
    });

    testWidgets('un error al guardar muestra el mensaje del backend', (
      tester,
    ) async {
      addresses = FakeAddressRepository(
        mutationError: const ValidationException('La dirección ya existe.'),
      );
      await pumpAt(tester, '/addresses/new');

      await fill(tester, 'Calle', 'Av. Insurgentes Sur');
      await fill(tester, 'Ciudad', 'CDMX');
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      expect(find.text('La dirección ya existe.'), findsOneWidget);
      expect(find.text('Agregar dirección'), findsOneWidget);
    });

    testWidgets('crear con casilla predeterminada envía esPredeterminada true', (
      tester,
    ) async {
      await pumpAt(tester, '/addresses/new');

      await fill(tester, 'Calle', 'Av. Universidad');
      await fill(tester, 'Ciudad', 'CDMX');
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      expect(addresses.creates.single.esPredeterminada, isTrue);
    });

    testWidgets('eliminar desde el formulario de edición pide confirmación y borra', (
      tester,
    ) async {
      await pumpAt(tester, '/addresses/${_oficina.id}/edit');

      await tester.tap(find.text('Eliminar'));
      await tester.pumpAndSettle();

      expect(find.text('Esta acción no se puede deshacer.'), findsOneWidget);
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.widgetWithText(FilledButton, 'Eliminar'),
        ),
      );
      await tester.pumpAndSettle();

      expect(addresses.deleteCalls, [_oficina.id]);
      expect(find.text('Casa'), findsOneWidget);
    });
  });
}

class _FakeAuthRepository implements AuthRepository {
  @override
  Future<UserProfile> fetchProfile() async => throw UnimplementedError();

  @override
  Future<UserProfile> updateProfile({String? nombre, String? telefono}) async =>
      throw UnimplementedError();

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async => throw UnimplementedError();

  @override
  Future<void> register({
    required String nombre,
    required String email,
    required String password,
    String? telefono,
    required String rol,
  }) async {}

  @override
  Future<void> forgotPassword({required String email}) async {}

  @override
  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {}

  @override
  Future<AuthTokens> refresh({required String refreshToken}) async =>
      const AuthTokens(accessToken: 'a', refreshToken: 'r', expiresIn: 3600);

  @override
  Future<void> logout({required String refreshToken}) async {}

  @override
  Future<StoredSession?> restoreSession() async => null;

  @override
  Future<void> persistSession(AuthSession session) async {}
}
