import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quickbite_mobile/src/features/delivery/data/location_permission_service.dart';
import 'package:quickbite_mobile/src/features/delivery/domain/models/location_permission_status.dart';
import 'package:quickbite_mobile/src/features/delivery/presentation/delivery_providers.dart';

class MockLocationPermissionService extends Mock
    implements LocationPermissionService {}

void main() {
  group('LocationPermissionNotifier', () {
    late MockLocationPermissionService mockService;
    late ProviderContainer container;

    setUp(() {
      mockService = MockLocationPermissionService();
      container = ProviderContainer(
        overrides: [
          locationPermissionServiceProvider.overrideWithValue(mockService),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state is AsyncLoading, then resolves to checkStatus result',
        () async {
      when(() => mockService.checkStatus())
          .thenAnswer((_) async => LocationPermissionStatus.notDetermined);

      final sub = container.listen(
        locationPermissionProvider,
        (_, _) {},
        fireImmediately: true,
      );

      // Initially loading
      expect(sub.read().isLoading, true);

      // Wait for future to complete
      await container.read(locationPermissionProvider.future);

      // Then resolves to notDetermined
      expect(sub.read().value, LocationPermissionStatus.notDetermined);
      verify(() => mockService.checkStatus()).called(1);
    });

    test('requestPermission calls service and updates state', () async {
      when(() => mockService.checkStatus())
          .thenAnswer((_) async => LocationPermissionStatus.notDetermined);
      when(() => mockService.requestPermission())
          .thenAnswer((_) async => LocationPermissionStatus.whenInUse);

      await container.read(locationPermissionProvider.future);

      final notifier = container.read(locationPermissionProvider.notifier);
      await notifier.requestPermission();

      final state = container.read(locationPermissionProvider);
      expect(state.value, LocationPermissionStatus.whenInUse);
      verify(() => mockService.requestPermission()).called(1);
    });
  });
}
