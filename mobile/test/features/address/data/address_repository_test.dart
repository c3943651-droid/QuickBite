import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickbite_mobile/src/core/error/app_exception.dart';
import 'package:quickbite_mobile/src/core/network/dio_client.dart';
import 'package:quickbite_mobile/src/features/address/data/address_remote_data_source.dart';
import 'package:quickbite_mobile/src/features/address/data/address_repository_impl.dart';

import '../../../support/fake_http.dart';

const addressId = '55555555-5555-5555-5555-555555555555';

void main() {
  late FakeHttpAdapter http;
  late AddressRepositoryImpl repository;

  setUp(() {
    http = FakeHttpAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'https://api.test/api/v1'))
      ..httpClientAdapter = http;
    repository = AddressRepositoryImpl(
      AddressRemoteDataSource(ApiClient(dio: dio)),
    );
  });

  group('listar (04 §4.4)', () {
    test('mapea la respuesta con es_predeterminada en snake_case', () async {
      http.on('GET', '/users/addresses', [addressJson()]);

      final addresses = await repository.fetchAddresses();

      expect(http.lastRequest().path, '/users/addresses');
      expect(addresses, hasLength(1));
      expect(addresses.single.alias, 'Casa');
      expect(addresses.single.calle, 'Av. Insurgentes');
      expect(addresses.single.numero, '123');
      expect(addresses.single.referencia, 'Portón azul');
      expect(addresses.single.ciudad, 'CDMX');
      expect(addresses.single.latitud, 19.4326);
      expect(addresses.single.longitud, -99.1332);
      expect(addresses.single.esPredeterminada, isTrue);
      expect(addresses.single.creadoEn, isNotNull);
    });

    test('una lista vacía no es un error', () async {
      http.on('GET', '/users/addresses', <Map<String, dynamic>>[]);

      expect(await repository.fetchAddresses(), isEmpty);
    });
  });

  group('crear (04 §4.5)', () {
    test('envía calle y ciudad obligatorias', () async {
      http.on('POST', '/users/addresses', addressJson(), statusCode: 201);

      final created = await repository.createAddress(
        alias: 'Casa',
        calle: 'Av. Insurgentes',
        numero: '123',
        referencia: 'Portón azul',
        ciudad: 'CDMX',
        esPredeterminada: true,
      );

      expect(http.lastRequest().method, 'POST');
      expect(http.lastRequest().data, {
        'alias': 'Casa',
        'calle': 'Av. Insurgentes',
        'numero': '123',
        'referencia': 'Portón azul',
        'ciudad': 'CDMX',
        'es_predeterminada': true,
      });
      expect(created.esPredeterminada, isTrue);
    });

    test('los campos opcionales vacíos no se envían', () async {
      http.on('POST', '/users/addresses', addressJson(), statusCode: 201);

      await repository.createAddress(
        calle: 'Av. Insurgentes',
        ciudad: 'CDMX',
        esPredeterminada: false,
      );

      final data = http.lastRequest().data as Map<String, dynamic>;
      expect(data.containsKey('alias'), isFalse);
      expect(data.containsKey('numero'), isFalse);
      expect(data.containsKey('referencia'), isFalse);
      expect(data.containsKey('latitud'), isFalse);
      expect(data['es_predeterminada'], isFalse);
    });
  });

  group('editar (04 §4.6)', () {
    test('envía el id en la ruta y los campos editables', () async {
      http.on('PUT', '/users/addresses/$addressId', addressJson());

      await repository.updateAddress(
        id: addressId,
        alias: 'Trabajo',
        calle: 'Av. Reforma',
        numero: '222',
        ciudad: 'CDMX',
      );

      expect(http.lastRequest().method, 'PUT');
      expect(http.lastRequest().path, '/users/addresses/$addressId');
      expect(http.lastRequest().data, {
        'alias': 'Trabajo',
        'calle': 'Av. Reforma',
        'numero': '222',
        'ciudad': 'CDMX',
      });
    });

    test('un 404 llega como NotFoundException', () async {
      http.onError(
        'PUT',
        '/users/addresses/$addressId',
        statusCode: 404,
        body: errorBodyJson('Dirección no encontrada.', status: 404),
      );

      expect(
        () => repository.updateAddress(id: addressId, calle: 'X', ciudad: 'Y'),
        throwsA(isA<NotFoundException>()),
      );
    });
  });

  group('eliminar (04 §4.7)', () {
    test('envía DELETE y no espera cuerpo', () async {
      http.on('DELETE', '/users/addresses/$addressId', <String, dynamic>{});

      await repository.deleteAddress(addressId);

      expect(http.lastRequest().method, 'DELETE');
      expect(http.lastRequest().path, '/users/addresses/$addressId');
    });
  });

  group('predeterminada (04 §4.8)', () {
    test('PATCH set-default marca la dirección', () async {
      http.on(
        'PATCH',
        '/users/addresses/$addressId/set-default',
        addressJson(),
      );

      final updated = await repository.setDefaultAddress(addressId);

      expect(http.lastRequest().method, 'PATCH');
      expect(
        http.lastRequest().path,
        '/users/addresses/$addressId/set-default',
      );
      expect(updated.esPredeterminada, isTrue);
    });
  });
}
