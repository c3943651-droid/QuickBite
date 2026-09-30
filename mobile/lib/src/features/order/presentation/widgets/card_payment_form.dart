import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/utils/validators.dart';

/// Formulario de tarjeta **simulado** (05#D-08).
///
/// Es UI pura: los cuatro valores viven únicamente en los
/// `TextEditingController` locales de este widget y se descartan al desmontar.
/// No hay estado de Riverpod, no se envía nada en `POST /orders` y no se
/// persiste en ninguna capa. La única salida hacia afuera es
/// [onValidityChanged], con la validez del conjunto de campos.
class CardPaymentForm extends StatefulWidget {
  const CardPaymentForm({super.key, required this.onValidityChanged});

  /// Avisa si los cuatro campos ya forman una tarjeta válida.
  final ValueChanged<bool> onValidityChanged;

  @override
  State<CardPaymentForm> createState() => _CardPaymentFormState();
}

class _CardPaymentFormState extends State<CardPaymentForm> {
  late final TextEditingController _numero;
  late final TextEditingController _expiracion;
  late final TextEditingController _cvv;
  late final TextEditingController _nombre;

  @override
  void initState() {
    super.initState();
    _numero = TextEditingController()..addListener(_avisar);
    _expiracion = TextEditingController()..addListener(_avisar);
    _cvv = TextEditingController()..addListener(_avisar);
    _nombre = TextEditingController()..addListener(_avisar);
  }

  @override
  void dispose() {
    _numero
      ..removeListener(_avisar)
      ..dispose();
    _expiracion
      ..removeListener(_avisar)
      ..dispose();
    _cvv
      ..removeListener(_avisar)
      ..dispose();
    _nombre
      ..removeListener(_avisar)
      ..dispose();
    super.dispose();
  }

  void _avisar() => widget.onValidityChanged(_esValido);

  bool get _esValido =>
      AppValidators.tarjetaNumero(_numero.text) &&
      AppValidators.tarjetaExpiracion(_expiracion.text) &&
      AppValidators.tarjetaCvv(_cvv.text) &&
      AppValidators.tarjetaNombre(_nombre.text);

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Datos de la tarjeta', style: tema.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Simulado: los datos no se guardan ni se envían.',
            style: tema.textTheme.labelSmall,
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            key: const ValueKey('tarjeta-numero'),
            controller: _numero,
            keyboardType: TextInputType.number,
            inputFormatters: [CardNumberFormatter()],
            decoration: const InputDecoration(
              labelText: 'Número de tarjeta',
              prefixIcon: Icon(Icons.credit_card),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  key: const ValueKey('tarjeta-expiracion'),
                  controller: _expiracion,
                  keyboardType: TextInputType.number,
                  inputFormatters: [CardExpiryFormatter()],
                  decoration: const InputDecoration(
                    labelText: 'Expiración (MM/AA)',
                    prefixIcon: Icon(Icons.date_range),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: TextField(
                  key: const ValueKey('tarjeta-cvv'),
                  controller: _cvv,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'CVC',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            key: const ValueKey('tarjeta-nombre'),
            controller: _nombre,
            keyboardType: TextInputType.name,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Nombre en la tarjeta',
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
        ],
      ),
    );
  }
}

/// Máscara `XXXX XXXX XXXX XXXX`: conserva solo 16 dígitos y los agrupa.
class CardNumberFormatter extends TextInputFormatter {
  static final RegExp _noDigito = RegExp(r'\D');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitos = newValue.text.replaceAll(_noDigito, '');
    final cortados = digitos.length > 16 ? digitos.substring(0, 16) : digitos;
    final buffer = StringBuffer();
    for (var i = 0; i < cortados.length; i++) {
      if (i > 0 && i % 4 == 0) {
        buffer.write(' ');
      }
      buffer.write(cortados[i]);
    }
    final texto = buffer.toString();
    return TextEditingValue(
      text: texto,
      selection: TextSelection.collapsed(offset: texto.length),
    );
  }
}

/// Máscara `MM/AA`: cuatro dígitos con la barra tras el mes.
class CardExpiryFormatter extends TextInputFormatter {
  static final RegExp _noDigito = RegExp(r'\D');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitos = newValue.text.replaceAll(_noDigito, '');
    final cortados = digitos.length > 4 ? digitos.substring(0, 4) : digitos;
    final texto = cortados.length > 2
        ? '${cortados.substring(0, 2)}/${cortados.substring(2)}'
        : cortados;
    return TextEditingValue(
      text: texto,
      selection: TextSelection.collapsed(offset: texto.length),
    );
  }
}
