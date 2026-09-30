import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quickbite_mobile/src/features/delivery/data/location_permission_service.dart';
import 'package:quickbite_mobile/src/features/delivery/domain/models/location_permission_status.dart';

// ---------------------------------------------------------------------------
// Fakes & Mocks
// ---------------------------------------------------------------------------

class _MockGeolocatorPlatform extends Mock implements GeolocatorPlatform {}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

GeolocatorPlatform _buildMock({
  required bool serviceEnabled,
  required LocationPermission permission,
}) {
  final mock = _MockGeolocatorPlatform();
  when(() => mock.isLocationServiceEnabled()).thenAnswer((_) async => serviceEnabled);
  when(() => mock.checkPermission()).thenAnswer((_) async => permission);
  when(() => mock.requestPermission()).thenAnswer((_) async => permission);
  return mock;
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('LocationPermissionService', () {
    // -----------------------------------------------------------------------
    // checkStatus
    // -----------------------------------------------------------------------
    group('checkStatus', () {
      test(
        'retorna serviceDisabled cuando el GPS del dispositivo está apagado',
        () async {
          // Arrange
          final platform = _buildMock(
            serviceEnabled: false,
            permission: LocationPermission.denied,
          );
          final sut = LocationPermissionService(platform: platform);

          // Act
          final result = await sut.checkStatus();

          // Assert
          expect(result, LocationPermissionStatus.serviceDisabled);
          // No debería consultar el permiso si el servicio está apagado
          verifyNever(() => platform.checkPermission());
        },
      );

      test(
        'retorna whenInUse cuando el GPS está habilitado y el permiso es whileInUse',
        () async {
          final platform = _buildMock(
            serviceEnabled: true,
            permission: LocationPermission.whileInUse,
          );
          final sut = LocationPermissionService(platform: platform);

          final result = await sut.checkStatus();

          expect(result, LocationPermissionStatus.whenInUse);
        },
      );

      test(
        'retorna always cuando el GPS está habilitado y el permiso es always',
        () async {
          final platform = _buildMock(
            serviceEnabled: true,
            permission: LocationPermission.always,
          );
          final sut = LocationPermissionService(platform: platform);

          final result = await sut.checkStatus();

          expect(result, LocationPermissionStatus.always);
        },
      );

      test(
        'retorna denied cuando el GPS está habilitado y el permiso es denied',
        () async {
          final platform = _buildMock(
            serviceEnabled: true,
            permission: LocationPermission.denied,
          );
          final sut = LocationPermissionService(platform: platform);

          final result = await sut.checkStatus();

          expect(result, LocationPermissionStatus.denied);
        },
      );

      test(
        'retorna deniedForever cuando el permiso es deniedForever',
        () async {
          final platform = _buildMock(
            serviceEnabled: true,
            permission: LocationPermission.deniedForever,
          );
          final sut = LocationPermissionService(platform: platform);

          final result = await sut.checkStatus();

          expect(result, LocationPermissionStatus.deniedForever);
        },
      );
    });

    // -----------------------------------------------------------------------
    // requestPermission
    // -----------------------------------------------------------------------
    group('requestPermission', () {
      test(
        'retorna serviceDisabled sin solicitar permiso cuando el GPS está apagado',
        () async {
          final platform = _buildMock(
            serviceEnabled: false,
            permission: LocationPermission.denied,
          );
          final sut = LocationPermissionService(platform: platform);

          final result = await sut.requestPermission();

          expect(result, LocationPermissionStatus.serviceDisabled);
          verifyNever(() => platform.requestPermission());
        },
      );

      test(
        'retorna whenInUse cuando el usuario concede whileInUse tras solicitud',
        () async {
          final mock = _MockGeolocatorPlatform();
          when(() => mock.isLocationServiceEnabled()).thenAnswer((_) async => true);
          when(() => mock.checkPermission()).thenAnswer((_) async => LocationPermission.denied);
          when(() => mock.requestPermission()).thenAnswer((_) async => LocationPermission.whileInUse);
          final sut = LocationPermissionService(platform: mock);

          final result = await sut.requestPermission();

          expect(result, LocationPermissionStatus.whenInUse);
          verify(() => mock.requestPermission()).called(1);
        },
      );

      test(
        'retorna deniedForever sin relanzar solicitud cuando el permiso ya es deniedForever',
        () async {
          final mock = _MockGeolocatorPlatform();
          when(() => mock.isLocationServiceEnabled()).thenAnswer((_) async => true);
          when(() => mock.checkPermission()).thenAnswer((_) async => LocationPermission.deniedForever);
          final sut = LocationPermissionService(platform: mock);

          final result = await sut.requestPermission();

          expect(result, LocationPermissionStatus.deniedForever);
          verifyNever(() => mock.requestPermission());
        },
      );

      test(
        'retorna denied cuando el usuario deniega la solicitud en tiempo de ejecución',
        () async {
          final mock = _MockGeolocatorPlatform();
          when(() => mock.isLocationServiceEnabled()).thenAnswer((_) async => true);
          when(() => mock.checkPermission()).thenAnswer((_) async => LocationPermission.denied);
          when(() => mock.requestPermission()).thenAnswer((_) async => LocationPermission.denied);
          final sut = LocationPermissionService(platform: mock);

          final result = await sut.requestPermission();

          expect(result, LocationPermissionStatus.denied);
        },
      );
    });
  });
}
