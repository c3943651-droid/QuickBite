import '../../../core/network/dio_client.dart';
import '../domain/address_entities.dart';
import 'dtos/address_dtos.dart';

class AddressRemoteDataSource {
  const AddressRemoteDataSource(this._client);

  static const _basePath = '/users/addresses';

  final ApiClient _client;

  Future<List<Address>> fetchAddresses() async {
    final response = await _client.get(_basePath);
    final data = response.data as List<dynamic>;
    return data
        .map((item) => AddressDto.fromJson(item as Map<String, dynamic>))
        .map((dto) => dto.toEntity())
        .toList(growable: false);
  }

  Future<Address> createAddress({
    required String calle,
    required String ciudad,
    String? alias,
    String? numero,
    String? referencia,
    double? latitud,
    double? longitud,
    bool esPredeterminada = false,
  }) async {
    final response = await _client.post(
      _basePath,
      data: AddressRequestDto(
        calle: calle.trim(),
        ciudad: ciudad.trim(),
        alias: _clean(alias),
        numero: _clean(numero),
        referencia: _clean(referencia),
        latitud: latitud,
        longitud: longitud,
        esPredeterminada: esPredeterminada,
      ).toJson(),
    );
    return _toEntity(response.data);
  }

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
    final response = await _client.put(
      '$_basePath/$id',
      data: AddressRequestDto(
        calle: _clean(calle),
        ciudad: _clean(ciudad),
        alias: _clean(alias),
        numero: _clean(numero),
        referencia: _clean(referencia),
        latitud: latitud,
        longitud: longitud,
      ).toJson(),
    );
    return _toEntity(response.data);
  }

  Future<void> deleteAddress(String id) async {
    await _client.delete('$_basePath/$id');
  }

  Future<Address> setDefaultAddress(String id) async {
    final response = await _client.patch('$_basePath/$id/set-default');
    return _toEntity(response.data);
  }

  Address _toEntity(Object? data) =>
      AddressDto.fromJson(data as Map<String, dynamic>).toEntity();

  static String? _clean(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}
