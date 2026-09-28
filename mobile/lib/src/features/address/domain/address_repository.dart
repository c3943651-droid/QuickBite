import 'address_entities.dart';

abstract interface class AddressRepository {
  Future<List<Address>> fetchAddresses();

  Future<Address> createAddress({
    required String calle,
    required String ciudad,
    String? alias,
    String? numero,
    String? referencia,
    double? latitud,
    double? longitud,
    bool esPredeterminada = false,
  });

  Future<Address> updateAddress({
    required String id,
    String? alias,
    String? calle,
    String? numero,
    String? referencia,
    String? ciudad,
    double? latitud,
    double? longitud,
  });

  Future<void> deleteAddress(String id);

  Future<Address> setDefaultAddress(String id);
}
