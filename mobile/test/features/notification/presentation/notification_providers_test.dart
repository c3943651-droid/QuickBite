import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickbite_mobile/src/core/error/app_exception.dart';
import 'package:quickbite_mobile/src/features/notification/domain/notification_entities.dart';
import 'package:quickbite_mobile/src/features/notification/presentation/notification_providers.dart';

import '../../../support/notification_fakes.dart';

const _pedidoId = '55555555-5555-5555-5555-555555555555';

void main() {
  late FakeNotificationRepository repository;
  late ProviderContainer container;

  ProviderContainer crearContainer() {
    final c = ProviderContainer(
      overrides: [notificationRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(c.dispose);
    return c;
  }

  setUp(() {
    repository = FakeNotificationRepository(
      notificaciones: [
        Notificacion(
          id: 'n1',
          tipo: TipoNotificacion.cambioEstado,
          titulo: 'Tu pedido va en camino',
          mensaje: 'Salió del restaurante.',
          pedidoId: _pedidoId,
          creadoEn: DateTime(2026, 9, 27, 15),
        ),
        Notificacion(
          id: 'n2',
          tipo: TipoNotificacion.sistema,
          titulo: 'Mantenimiento',
          mensaje: 'Domingo de mantenimiento.',
          creadoEn: DateTime(2026, 9, 26, 10),
        ),
        Notificacion(
          id: 'n3',
          tipo: TipoNotificacion.pedidoNuevo,
          titulo: 'Pedido recibido',
          mensaje: 'Estamos preparando tu pedido.',
          pedidoId: _pedidoId,
          leido: true,
          creadoEn: DateTime(2026, 9, 25, 9),
        ),
      ],
    );
    container = crearContainer();
  });

  group('notificationsProvider', () {
    test('carga la bandeja del backend', () async {
      final lista = await container.read(notificationsProvider.future);

      expect(lista, hasLength(3));
      expect(lista.first.id, 'n1');
    });

    test('no reintenta solo: deja el error para la pantalla', () async {
      repository.listError = const ServerException('No pudimos cargar.');

      await expectLater(
        container.read(notificationsProvider.future),
        throwsA(anything),
      );

      final estado = container.read(notificationsProvider);
      expect(estado.hasError, isTrue);
      expect(estado.isLoading, isFalse);
    });
  });

  group('filtros', () {
    test(
      'por defecto se ven todas, de la más reciente a la más antigua',
      () async {
        await container.read(notificationsProvider.future);

        expect(
          container.read(notificationsFiltradasProvider).map((n) => n.id),
          ['n1', 'n2', 'n3'],
        );
      },
    );

    test('el filtro no leídas excluye las ya leídas', () async {
      await container.read(notificationsProvider.future);
      container
          .read(notificationFilterProvider.notifier)
          .seleccionar(FiltroNotificacion.noLeidas);

      expect(container.read(notificationsFiltradasProvider).map((n) => n.id), [
        'n1',
        'n2',
      ]);
    });

    test('el filtro pedidos deja solo los tipos de pedido', () async {
      await container.read(notificationsProvider.future);
      container
          .read(notificationFilterProvider.notifier)
          .seleccionar(FiltroNotificacion.pedidos);

      expect(container.read(notificationsFiltradasProvider).map((n) => n.id), [
        'n1',
        'n3',
      ]);
    });

    test('el filtro sistema deja avisos y recordatorios', () async {
      await container.read(notificationsProvider.future);
      container
          .read(notificationFilterProvider.notifier)
          .seleccionar(FiltroNotificacion.sistema);

      expect(container.read(notificationsFiltradasProvider).map((n) => n.id), [
        'n2',
      ]);
    });
  });

  group('no leídas', () {
    test('cuenta las notificaciones pendientes de leer', () async {
      await container.read(notificationsProvider.future);

      expect(container.read(notificationsNoLeidasProvider), 2);
    });

    test('el contador baja al marcar una como leída', () async {
      await container.read(notificationsProvider.future);

      await container
          .read(notificationAccionesProvider.notifier)
          .marcarLeida('n1');
      await container.read(notificationsProvider.future);

      expect(repository.leidas, ['n1']);
      expect(container.read(notificationsNoLeidasProvider), 1);
    });
  });

  group('acciones', () {
    test('marcar una notificación la deja leída en la bandeja', () async {
      await container.read(notificationsProvider.future);
      final notifier = container.read(notificationAccionesProvider.notifier);

      final ok = await notifier.marcarLeida('n1');

      expect(ok, isTrue);
      final lista = await container.read(notificationsProvider.future);
      expect(lista.firstWhere((n) => n.id == 'n1').leido, isTrue);
    });

    test('marcar todas deja la bandeja sin pendientes', () async {
      await container.read(notificationsProvider.future);
      final notifier = container.read(notificationAccionesProvider.notifier);

      final ok = await notifier.marcarTodasLeidas();
      await container.read(notificationsProvider.future);

      expect(ok, isTrue);
      expect(repository.todasMarcadas, 1);
      expect(container.read(notificationsNoLeidasProvider), 0);
    });

    test(
      'un rechazo de la API se expone como error y no cambia la bandeja',
      () async {
        repository.marcarError = const ServerException('No pudimos marcar.');
        await container.read(notificationsProvider.future);
        final notifier = container.read(notificationAccionesProvider.notifier);

        final ok = await notifier.marcarLeida('n1');

        expect(ok, isFalse);
        expect(container.read(notificationAccionesProvider).error, isNotNull);
        expect(
          container
              .read(notificationsProvider)
              .value!
              .firstWhere((n) => n.id == 'n1')
              .leido,
          isFalse,
        );
      },
    );
  });
}
