import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quickbite_mobile/src/core/error/app_exception.dart';
import 'package:quickbite_mobile/src/features/address/data/address_remote_data_source.dart';
import 'package:quickbite_mobile/src/features/address/data/address_repository_impl.dart';
import 'package:quickbite_mobile/src/features/address/data/reverse_geocoding_service.dart';
import 'package:quickbite_mobile/src/features/address/domain/address_entities.dart';
import 'package:quickbite_mobile/src/features/address/domain/address_repository.dart';
import 'package:quickbite_mobile/src/features/auth/presentation/auth_providers.dart';

final addressRepositoryProvider = Provider<AddressRepository>((ref) {
  return AddressRepositoryImpl(
    AddressRemoteDataSource(ref.watch(apiClientProvider)),
  );
});

/// Geocodificación inversa del selector de ubicación (07.5 §3.3).
final reverseGeocodingServiceProvider = Provider<ReverseGeocodingService>(
  (ref) => ReverseGeocodingService(),
);

/// Lista de direcciones (07.1 SCR-PROF-06). Se invalida tras cada mutación
/// para que el backend sea la única fuente de verdad: la regla de "solo una
/// predeterminada" (04 §4.8) la aplica el servidor, no el cliente.
/// `retry` se anula a propósito: riverpod 3 reintenta solo y deja el estado en
/// "cargando con error", con lo que la pantalla mostraría un skeleton eterno en
/// vez del error con su botón de reintento (07.1 SCR-PROF-06).
final addressesProvider = FutureProvider.autoDispose<List<Address>>(
  (ref) => ref.watch(addressRepositoryProvider).fetchAddresses(),
  retry: (retryCount, error) => null,
);

final addressDetailProvider = FutureProvider.autoDispose
    .family<Address, String>((ref, id) async {
      final addresses = await ref.watch(addressesProvider.future);
      return addresses.firstWhere(
        (address) => address.id == id,
        orElse: () => throw NotFoundException('La dirección ya no existe.'),
      );
    }, retry: (retryCount, error) => null);

/// Mutaciones del formulario (07.1 SCR-PROF-07). `saved` marca el éxito para que
/// la pantalla vuelva a la lista; tras cualquier operación se invalida la
/// lista porque el backend puede desmarcar la anterior predeterminada.
@immutable
class AddressFormState {
  const AddressFormState({
    this.loading = false,
    this.saved = false,
    this.error,
  });

  final bool loading;
  final bool saved;
  final Object? error;
}

final addressFormProvider =
    NotifierProvider<AddressFormNotifier, AddressFormState>(
      AddressFormNotifier.new,
    );

class AddressFormNotifier extends Notifier<AddressFormState> {
  @override
  AddressFormState build() => const AddressFormState();

  Future<bool> save({
    String? id,
    String? alias,
    required String calle,
    String? numero,
    String? referencia,
    required String ciudad,
    double? latitud,
    double? longitud,
    bool esPredeterminada = false,
  }) async {
    state = const AddressFormState(loading: true);
    try {
      final repository = ref.read(addressRepositoryProvider);
      if (id == null) {
        await repository.createAddress(
          alias: alias,
          calle: calle,
          numero: numero,
          referencia: referencia,
          ciudad: ciudad,
          latitud: latitud,
          longitud: longitud,
          esPredeterminada: esPredeterminada,
        );
      } else {
        await repository.updateAddress(
          id: id,
          alias: alias,
          calle: calle,
          numero: numero,
          referencia: referencia,
          ciudad: ciudad,
          latitud: latitud,
          longitud: longitud,
        );
        if (esPredeterminada) {
          await repository.setDefaultAddress(id);
        }
      }
      ref.invalidate(addressesProvider);
      state = const AddressFormState(saved: true);
      return true;
    } on Object catch (error) {
      state = AddressFormState(error: error);
      return false;
    }
  }

  Future<bool> delete(String id) async {
    state = const AddressFormState(loading: true);
    try {
      await ref.read(addressRepositoryProvider).deleteAddress(id);
      ref.invalidate(addressesProvider);
      state = const AddressFormState(saved: true);
      return true;
    } on Object catch (error) {
      state = AddressFormState(error: error);
      return false;
    }
  }
}
