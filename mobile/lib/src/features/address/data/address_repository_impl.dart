import '../domain/address_entities.dart';
import '../domain/address_repository.dart';
import 'address_remote_data_source.dart';

class AddressRepositoryImpl implements AddressRepository {
  const AddressRepositoryImpl(this._remote);

  final AddressRemoteDataSource _remote;

  @override
  Future<List<Address>> fetchAddresses() => _remote.fetchAddresses();

  @override
  Future<Address> createAddress({
    required String calle,
    required String ciudad,
    String? alias,
    String? numero,
    String? referencia,
    double? latitud,
    double? longitud,
    bool esPredeterminada = false,
  }) {
    return _remote.createAddress(
      calle: calle,
      ciudad: ciudad,
      alias: alias,
      numero: numero,
      referencia: referencia,
      latitud: latitud,
      longitud: longitud,
      esPredeterminada: esPredeterminada,
    );
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
  }) {
    return _remote.updateAddress(
      id: id,
      alias: alias,
      calle: calle,
      numero: numero,
      referencia: referencia,
      ciudad: ciudad,
      latitud: latitud,
      longitud: longitud,
    );
  }

  @override
  Future<void> deleteAddress(String id) => _remote.deleteAddress(id);

  @override
  Future<Address> setDefaultAddress(String id) => _remote.setDefaultAddress(id);
}
