import 'package:flutter/material.dart';

import '../../../core/widgets/chips.dart';
import '../domain/order_entities.dart';

/// Presentación de [EstadoPedido]: el color y el icono de cada estado se
/// deciden en un solo lugar (09 §8.4) para que las pantallas no los inventen.
extension EstadoPedidoUi on EstadoPedido {
  StatusTone get tone => switch (this) {
    EstadoPedido.pendiente => StatusTone.info,
    EstadoPedido.confirmado => StatusTone.info,
    EstadoPedido.preparando => StatusTone.progress,
    EstadoPedido.listo => StatusTone.progress,
    EstadoPedido.enCamino => StatusTone.warning,
    EstadoPedido.entregado => StatusTone.success,
    EstadoPedido.cancelado => StatusTone.danger,
  };

  IconData get icono => switch (this) {
    EstadoPedido.pendiente => Icons.receipt_long,
    EstadoPedido.confirmado => Icons.check_circle_outline,
    EstadoPedido.preparando => Icons.soup_kitchen,
    EstadoPedido.listo => Icons.shopping_bag_outlined,
    EstadoPedido.enCamino => Icons.delivery_dining,
    EstadoPedido.entregado => Icons.home_work,
    EstadoPedido.cancelado => Icons.cancel_outlined,
  };
}
