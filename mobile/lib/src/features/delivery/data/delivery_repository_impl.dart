import '../domain/delivery_repository.dart';
import '../domain/disponibilidad.dart';
import '../domain/estadisticas_repartidor.dart';
import '../domain/pedido_entrega.dart';
import 'delivery_remote_data_source.dart';
import 'dtos/delivery_dtos.dart';

class DeliveryRepositoryImpl implements DeliveryRepository {
  const DeliveryRepositoryImpl(this._remote);

  final DeliveryRemoteDataSource _remote;

  @override
  Future<List<PedidoEntrega>> pedidosDisponibles() async {
    final dtos = await _remote.listarDisponibles();
    return _entregas(dtos);
  }

  @override
  Future<void> aceptar(String pedidoId) => _remote.aceptar(pedidoId);

  @override
  Future<PedidoEntrega?> entregaActiva() async {
    final dtos = await _remote.listarActivos();
    if (dtos.isEmpty) return null;
    // Con más de uno gana el más reciente: es el que el repartidor está
    // llevando y evita mostrar una entrega vieja por delante de la actual.
    final masReciente = _masReciente(dtos);
    return _entrega(masReciente);
  }

  @override
  Future<void> completar(String pedidoId) => _remote.completar(pedidoId);

  @override
  Future<List<PedidoEntrega>> historialEntregas() async {
    final dtos = await _remote.listarHistorial();
    return _entregas(_ordenarPorFecha(dtos));
  }

  @override
  Future<Disponibilidad> disponibilidad() => _remote.disponibilidad();

  @override
  Future<Disponibilidad> cambiarDisponibilidad(DeliveryPersonStatus estado) =>
      _remote.cambiarDisponibilidad(estado);

  @override
  Future<EstadisticasRepartidor> estadisticas() async {
    final dto = await _remote.estadisticas();
    return EstadisticasRepartidor(
      entregasTotales: dto.entregasTotales,
      entregasDelMes: dto.entregasDelMes,
      tiempoPromedioEntregaMinutos: dto.tiempoPromedioEntregaMinutos,
      pedidosAsignados: dto.pedidosAsignadosActivos,
      cancelaciones: dto.cancelaciones,
    );
  }

  /// Del más reciente al más antiguo; los que no traen fecha quedan al final.
  static List<PedidoEntregaDto> _ordenarPorFecha(List<PedidoEntregaDto> dtos) {
    final ordenados = [...dtos];
    ordenados.sort((a, b) {
      final fechaA = a.creadoEn;
      final fechaB = b.creadoEn;
      if (fechaA == null && fechaB == null) return 0;
      if (fechaA == null) return 1;
      if (fechaB == null) return -1;
      return fechaB.toUtc().compareTo(fechaA.toUtc());
    });
    return ordenados;
  }

  static PedidoEntregaDto _masReciente(List<PedidoEntregaDto> dtos) =>
      _ordenarPorFecha(dtos).first;

  static List<PedidoEntrega> _entregas(List<PedidoEntregaDto> dtos) =>
      dtos.map(_entrega).toList(growable: false);

  static PedidoEntrega _entrega(PedidoEntregaDto dto) => PedidoEntrega(
    id: dto.id,
    numeroPedido: dto.numeroPedido,
    estado: dto.estado,
    total: dto.total,
    subtotal: dto.subtotal,
    costoEnvio: dto.costoEnvio,
    items: dto.items,
    creadoEn: dto.creadoEn,
    latitud: dto.latitud,
    cliente: dto.cliente,
    direccion: dto.direccion,
    telefono: dto.telefono,
    longitud: dto.longitud,
  );
}
