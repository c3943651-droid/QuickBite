import 'package:equatable/equatable.dart';

/// Métodos de pago simulados (05#D-08). El backend solo acepta `efectivo` y
/// `tarjeta`: el enum `PaymentMethodType` y su validador no contemplan otros
/// valores, así que la app no puede ofrecer otros sin un cambio previo.
enum MetodoPago {
  efectivo('efectivo', 'Efectivo contra entrega'),
  tarjeta('tarjeta', 'Tarjeta (simulado)');

  const MetodoPago(this.api, this.etiqueta);

  /// Valor exacto que espera `POST /orders`.
  final String api;

  final String etiqueta;

  static MetodoPago fromApi(String value) => values.firstWhere(
    (metodo) => metodo.api == value.trim().toLowerCase(),
    orElse: () => MetodoPago.efectivo,
  );
}

class OrderItem extends Equatable {
  const OrderItem({required this.nombre, required this.cantidad});

  final String nombre;
  final int cantidad;

  @override
  List<Object?> get props => [nombre, cantidad];
}

class Order extends Equatable {
  const Order({
    required this.id,
    required this.numeroPedido,
    required this.estado,
    required this.total,
    required this.direccionEntrega,
    required this.items,
    this.subtotal,
    this.costoEnvio,
    this.creadoEn,
    this.latitud,
    this.longitud,
  });

  /// `POST /orders` todavía no devuelve un tiempo estimado (la clave
  /// `tiempo_entrega_estimado` vive en la configuración del panel admin sin
  /// exponerla por API), así que la app muestra su valor por defecto.
  static const int tiempoEntregaEstimadoPorDefecto = 40;

  final String id;
  final String numeroPedido;
  final String estado;
  final double total;
  final String direccionEntrega;
  final List<OrderItem> items;
  final double? subtotal;
  final double? costoEnvio;
  final DateTime? creadoEn;

  /// Coordenadas de destino copiadas de la dirección al crear el pedido
  /// (07.5 §3.3); null cuando la dirección no las tenía.
  final double? latitud;
  final double? longitud;

  /// Estado interpretado: la API manda el texto y la app razona sobre el enum.
  EstadoPedido get estadoPedido => EstadoPedido.fromApi(estado);

  /// El polling solo cambia el estado; el resto del detalle sigue igual.
  Order copyWith({String? estado, DateTime? creadoEn, List<OrderItem>? items}) {
    return Order(
      id: id,
      numeroPedido: numeroPedido,
      estado: estado ?? this.estado,
      total: total,
      direccionEntrega: direccionEntrega,
      items: items ?? this.items,
      subtotal: subtotal,
      costoEnvio: costoEnvio,
      creadoEn: creadoEn ?? this.creadoEn,
      latitud: latitud,
      longitud: longitud,
    );
  }

  int get tiempoEntregaEstimado => tiempoEntregaEstimadoPorDefecto;

  int get cantidadItems =>
      items.fold(0, (total, item) => total + item.cantidad);

  @override
  List<Object?> get props => [
    id,
    numeroPedido,
    estado,
    total,
    direccionEntrega,
  ];
}

/// Estados que devuelve `GET /orders` como el `ToString()` del enum
/// `OrderStatus` del backend. La app los mantiene como texto en [Order.estado]
/// (lo que llegó por el cable) y usa este enum para razonar sobre ellos.
enum EstadoPedido {
  pendiente('Pendiente', 'Pendiente'),
  confirmado('Confirmado', 'Confirmado'),
  preparando('Preparando', 'Preparando'),
  listo('Listo', 'Listo'),
  enCamino('EnCamino', 'En camino'),
  entregado('Entregado', 'Entregado'),
  cancelado('Cancelado', 'Cancelado');

  const EstadoPedido(this.api, this.etiqueta);

  /// Valor exacto con el que responde la API.
  final String api;

  final String etiqueta;

  static EstadoPedido fromApi(String value) => values.firstWhere(
    (estado) => estado.api.toLowerCase() == value.trim().toLowerCase(),
    orElse: () => EstadoPedido.pendiente,
  );

  /// Los seis estados que recorren un pedido completo, en orden.
  static const List<EstadoPedido> linea = [
    EstadoPedido.pendiente,
    EstadoPedido.confirmado,
    EstadoPedido.preparando,
    EstadoPedido.listo,
    EstadoPedido.enCamino,
    EstadoPedido.entregado,
  ];

  /// El pedido todavía puede cambiar: el polling sigue activo.
  bool get esActivo => switch (this) {
    EstadoPedido.entregado || EstadoPedido.cancelado => false,
    _ => true,
  };

  /// 07.1 SCR-ORDER-01 — el botón cancelar solo aparece pendiente o confirmado.
  bool get esCancelable =>
      this == EstadoPedido.pendiente || this == EstadoPedido.confirmado;

  /// Posición en la línea de tiempo; `-1` si el estado no está en ella.
  int get indiceEnLinea => linea.indexOf(this);

  bool get esFinal => !esActivo;
}

/// Filtros de estado del historial (07.1 SCR-ORDER-03). El filtrado es en
/// cliente: la API devuelve todos los pedidos del usuario sin filtros.
enum FiltroPedido {
  todos('Todos', []),
  pendientes('Pendientes', [EstadoPedido.pendiente]),
  enCurso('En curso', [
    EstadoPedido.pendiente,
    EstadoPedido.confirmado,
    EstadoPedido.preparando,
    EstadoPedido.listo,
    EstadoPedido.enCamino,
  ]),
  entregados('Entregados', [EstadoPedido.entregado]),
  cancelados('Cancelados', [EstadoPedido.cancelado]);

  const FiltroPedido(this.etiqueta, this.estados);

  final String etiqueta;

  /// Estados que incluye; vacío significa "sin filtro".
  final List<EstadoPedido> estados;

  bool incluye(EstadoPedido estado) =>
      estados.isEmpty || estados.contains(estado);
}

/// Estado puntual de un pedido (`GET /orders/{id}/status`), que es lo que
/// consulta el polling. Trae el momento del último cambio, no un historial.
class EstadoPedidoActualizado {
  const EstadoPedidoActualizado({
    required this.id,
    required this.estado,
    required this.actualizadoEn,
  });

  final String id;
  final EstadoPedido estado;
  final DateTime actualizadoEn;
}
