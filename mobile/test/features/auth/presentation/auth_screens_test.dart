import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:quickbite_mobile/src/core/error/app_exception.dart';
import 'package:quickbite_mobile/src/core/session/token_storage.dart';
import 'package:quickbite_mobile/src/features/auth/domain/auth_entities.dart';
import 'package:quickbite_mobile/src/features/auth/domain/auth_repository.dart';
import 'package:quickbite_mobile/src/features/auth/presentation/auth_providers.dart';
import 'package:quickbite_mobile/src/features/catalog/domain/catalog_entities.dart';
import 'package:quickbite_mobile/src/features/catalog/domain/catalog_repository.dart';
import 'package:quickbite_mobile/src/features/catalog/presentation/catalog_providers.dart';
import 'package:quickbite_mobile/src/features/shell/app_router.dart';

const _session = AuthSession(
  tokens: AuthTokens(accessToken: 'a', refreshToken: 'r', expiresIn: 3600),
  user: AuthUser(
    id: '1',
    nombre: 'Carlos',
    email: 'carlos@quickbite.mx',
    rol: 'cliente',
  ),
);

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.loginError});

  final Object? loginError;
  final List<({String email, String password})> logins = [];
  final List<({String nombre, String email, String rol})> registrations = [];
  StoredSession? persisted;
  bool cleared = false;

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    logins.add((email: email, password: password));
    if (loginError != null) {
      throw loginError!;
    }
    return _session;
  }

  @override
  Future<void> register({
    required String nombre,
    required String email,
    required String password,
    String? telefono,
    required String rol,
  }) async {
    registrations.add((nombre: nombre, email: email, rol: rol));
  }

  @override
  Future<AuthTokens> refresh({required String refreshToken}) async =>
      _session.tokens;

  @override
  Future<void> logout({required String refreshToken}) async => cleared = true;

  @override
  Future<StoredSession?> restoreSession() async => persisted;

  @override
  Future<void> persistSession(AuthSession session) async {
    persisted = StoredSession(
      accessToken: session.tokens.accessToken,
      refreshToken: session.tokens.refreshToken,
      expiresIn: session.tokens.expiresIn,
    );
  }
}

class FakeTokenStorage implements TokenStorage {
  FakeTokenStorage([this.session]);

  StoredSession? session;
  int clearCalls = 0;

  @override
  Future<void> clear() async {
    session = null;
    clearCalls++;
  }

  @override
  Future<StoredSession?> read() async => session;

  @override
  Future<String?> readAccessToken() async => session?.accessToken;

  @override
  Future<void> save(StoredSession value) async => session = value;
}

class FakeCatalogRepository implements CatalogRepository {
  @override
  Future<List<Category>> getCategories() async => const [
    Category(id: 'c1', nombre: 'Tacos', orden: 1, activo: true),
    Category(id: 'c2', nombre: 'Bebidas', orden: 2, activo: true),
  ];

  @override
  Future<Product> getProduct(String id) => throw UnimplementedError();

  @override
  Future<List<ProductOption>> getProductOptions(String id) =>
      throw UnimplementedError();

  @override
  Future<ProductPage> getProducts(ProductFilter filter) async =>
      const ProductPage(
        items: [
          Product(
            id: 'p1',
            nombre: 'Tacos al pastor',
            precio: 85.50,
            disponible: true,
            categoria: Category(
              id: 'c1',
              nombre: 'Tacos',
              orden: 1,
              activo: true,
            ),
          ),
        ],
        page: 1,
        limit: 12,
        total: 1,
        totalPages: 1,
      );
}

/// El viewport por defecto (800x600) no cabe en el formulario de registro.
/// Desplaza el widget hasta que sea visible y lo pulsa.
Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
}

void useTallScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  Future<GoRouter> pumpApp(
    WidgetTester tester, {
    required FakeAuthRepository auth,
    TokenStorage? storage,
  }) async {
    useTallScreen(tester);
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(auth),
        tokenStorageProvider.overrideWithValue(storage ?? FakeTokenStorage()),
        catalogRepositoryProvider.overrideWithValue(FakeCatalogRepository()),
      ],
    );
    addTearDown(container.dispose);
    final router = createRouter(() => container.read(sessionProvider.future));
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    return router;
  }

  group('LoginScreen', () {
    testWidgets('muestra el formulario de acceso', (tester) async {
      await pumpApp(tester, auth: FakeAuthRepository());

      expect(find.text('QuickBite'), findsOneWidget);
      expect(find.text('Bienvenido de nuevo'), findsOneWidget);
      expect(find.text('Correo electrónico'), findsOneWidget);
      expect(find.text('Iniciar sesión'), findsOneWidget);
      expect(find.text('Crear cuenta'), findsOneWidget);
    });

    testWidgets('bloquea el envío con email inválido sin llamar a la API', (
      tester,
    ) async {
      final auth = FakeAuthRepository();
      await pumpApp(tester, auth: auth);

      await tester.enterText(find.byType(TextFormField).first, 'correo-malo');
      await tester.enterText(find.byType(TextFormField).last, 'Password1!');
      await tapVisible(tester, find.text('Iniciar sesión'));
      await tester.pump();

      expect(
        find.text('Ingresa un correo electrónico válido.'),
        findsOneWidget,
      );
      expect(auth.logins, isEmpty);
    });

    testWidgets('bloquea el envío con contraseña débil', (tester) async {
      final auth = FakeAuthRepository();
      await pumpApp(tester, auth: auth);

      await tester.enterText(
        find.byType(TextFormField).first,
        'carlos@quickbite.mx',
      );
      await tester.enterText(find.byType(TextFormField).last, 'debil');
      await tapVisible(tester, find.text('Iniciar sesión'));
      await tester.pump();

      expect(
        find.text('La contraseña debe tener al menos 8 caracteres.'),
        findsOneWidget,
      );
      expect(auth.logins, isEmpty);
    });

    testWidgets(
      'envía las credenciales y navega al catálogo tras un login válido',
      (tester) async {
        final auth = FakeAuthRepository();
        await pumpApp(tester, auth: auth);

        await tester.enterText(
          find.byType(TextFormField).first,
          'carlos@quickbite.mx',
        );
        await tester.enterText(find.byType(TextFormField).last, 'Password1!');
        await tapVisible(tester, find.text('Iniciar sesión'));
        await tester.pumpAndSettle();

        expect(auth.logins.single.email, 'carlos@quickbite.mx');
        expect(auth.logins.single.password, 'Password1!');
        expect(
          find.text('Tacos al pastor'),
          findsOneWidget,
          reason: 'debe navegar a /home y mostrar el catálogo',
        );
      },
    );

    testWidgets('muestra un mensaje de error con credenciales incorrectas', (
      tester,
    ) async {
      await pumpApp(
        tester,
        auth: FakeAuthRepository(loginError: const UnauthorizedException()),
      );

      await tester.enterText(
        find.byType(TextFormField).first,
        'carlos@quickbite.mx',
      );
      await tester.enterText(find.byType(TextFormField).last, 'Password1!');
      await tapVisible(tester, find.text('Iniciar sesión'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('credenciales son incorrectas'),
        findsOneWidget,
      );
      expect(
        find.text('QuickBite'),
        findsOneWidget,
        reason: 'debe permanecer en el login',
      );
    });

    testWidgets('muestra el error de validación por campo del backend', (
      tester,
    ) async {
      await pumpApp(
        tester,
        auth: FakeAuthRepository(
          loginError: const ValidationException(
            'Datos inválidos.',
            fieldErrors: {
              'Email': ['El email no tiene un formato válido.'],
            },
          ),
        ),
      );

      await tester.enterText(
        find.byType(TextFormField).first,
        'carlos@quickbite.mx',
      );
      await tester.enterText(find.byType(TextFormField).last, 'Password1!');
      await tapVisible(tester, find.text('Iniciar sesión'));
      await tester.pumpAndSettle();

      expect(
        find.text('Las credenciales son incorrectas. Inténtalo de nuevo.'),
        findsOneWidget,
      );
    });

    testWidgets('oculta y muestra la contraseña', (tester) async {
      await pumpApp(tester, auth: FakeAuthRepository());

      expect(
        tester.widget<TextField>(find.byType(TextField).last).obscureText,
        isTrue,
      );

      await tester.tap(find.byTooltip('Mostrar contraseña'));
      await tester.pump();

      expect(
        tester.widget<TextField>(find.byType(TextField).last).obscureText,
        isFalse,
      );
      expect(find.byTooltip('Ocultar contraseña'), findsOneWidget);
    });

    testWidgets('navega a registro desde "¿No tienes cuenta?"', (tester) async {
      await pumpApp(tester, auth: FakeAuthRepository());

      await tapVisible(tester, find.text('Crear cuenta'));
      await tester.pumpAndSettle();

      expect(find.text('Crea tu cuenta'), findsOneWidget);
    });
  });

  group('RegisterScreen', () {
    Future<void> openRegister(
      WidgetTester tester,
      FakeAuthRepository auth,
    ) async {
      await pumpApp(tester, auth: auth);
      await tapVisible(tester, find.text('Crear cuenta'));
      await tester.pumpAndSettle();
    }

    testWidgets('exige nombre, email y contraseña antes de enviar', (
      tester,
    ) async {
      final auth = FakeAuthRepository();
      await openRegister(tester, auth);

      await tapVisible(tester, find.text('Registrarse'));
      await tester.pump();

      expect(find.text('El nombre es obligatorio.'), findsOneWidget);
      expect(
        find.text('El correo electrónico es obligatorio.'),
        findsOneWidget,
      );
      expect(find.text('La contraseña es obligatoria.'), findsOneWidget);
      expect(auth.registrations, isEmpty);
    });

    testWidgets('exige aceptar la política de privacidad', (tester) async {
      final auth = FakeAuthRepository();
      await openRegister(tester, auth);

      await tester.enterText(find.byType(TextFormField).at(0), 'Carlos Pérez');
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'carlos@quickbite.mx',
      );
      await tester.enterText(find.byType(TextFormField).at(3), 'Password1!');
      await tester.enterText(find.byType(TextFormField).at(4), 'Password1!');
      await tapVisible(tester, find.text('Registrarse'));
      await tester.pump();

      expect(find.textContaining('política de privacidad'), findsWidgets);
      expect(auth.registrations, isEmpty);
    });

    testWidgets('valida que las contraseñas coincidan', (tester) async {
      final auth = FakeAuthRepository();
      await openRegister(tester, auth);

      await tester.enterText(find.byType(TextFormField).at(0), 'Carlos Pérez');
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'carlos@quickbite.mx',
      );
      await tester.enterText(find.byType(TextFormField).at(3), 'Password1!');
      await tester.enterText(find.byType(TextFormField).at(4), 'OtraClave1!');
      await tapVisible(tester, find.text('Registrarse'));
      await tester.pump();

      expect(find.text('Las contraseñas no coinciden.'), findsOneWidget);
      expect(auth.registrations, isEmpty);
    });

    testWidgets('rechaza un teléfono inválido', (tester) async {
      final auth = FakeAuthRepository();
      await openRegister(tester, auth);

      await tester.enterText(find.byType(TextFormField).at(2), 'abc');
      await tester.enterText(find.byType(TextFormField).at(0), 'Carlos Pérez');
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'carlos@quickbite.mx',
      );
      await tester.enterText(find.byType(TextFormField).at(3), 'Password1!');
      await tester.enterText(find.byType(TextFormField).at(4), 'Password1!');
      await tapVisible(tester, find.text('Registrarse'));
      await tester.pump();

      expect(
        find.text('Ingresa un teléfono válido de hasta 20 caracteres.'),
        findsOneWidget,
      );
      expect(auth.registrations, isEmpty);
    });

    testWidgets('registra como repartidor y vuelve al login', (tester) async {
      final auth = FakeAuthRepository();
      await openRegister(tester, auth);

      await tester.enterText(find.byType(TextFormField).at(0), 'Carlos Pérez');
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'carlos@quickbite.mx',
      );
      await tester.enterText(find.byType(TextFormField).at(2), '55 1234 5678');
      await tester.enterText(find.byType(TextFormField).at(3), 'Password1!');
      await tester.enterText(find.byType(TextFormField).at(4), 'Password1!');
      await tester.tap(find.text('Repartidor'));
      await tester.pump();
      await tapVisible(tester, find.byType(Checkbox));
      await tester.pump();
      await tapVisible(tester, find.text('Registrarse'));
      await tester.pumpAndSettle();

      expect(auth.registrations.single, (
        nombre: 'Carlos Pérez',
        email: 'carlos@quickbite.mx',
        rol: 'repartidor',
      ));
      expect(
        find.text('Bienvenido de nuevo'),
        findsOneWidget,
        reason: 'tras registrarse debe volver al login',
      );
    });

    testWidgets('solo ofrece los roles cliente y repartidor', (tester) async {
      await openRegister(tester, FakeAuthRepository());

      expect(find.text('Cliente'), findsOneWidget);
      expect(find.text('Repartidor'), findsOneWidget);
      expect(find.text('Administrador'), findsNothing);
    });
  });
}
