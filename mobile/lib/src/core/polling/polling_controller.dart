import 'dart:async';

/// Frecuencias de polling ofrecidas en preferencias (07.3 H5.3, 05 D-01).
///
/// 07 §8.6 exige respetar la preferencia de la persona usuaria "siempre dentro
/// de un rango permitido": por eso normalizar acota en vez de aceptar cualquier
/// valor que venga de almacenamiento local.
class FrecuenciaPolling {
  const FrecuenciaPolling._();

  static const Duration porDefecto = Duration(seconds: 10);
  static const List<Duration> opciones = [
    Duration(seconds: 10),
    Duration(seconds: 30),
    Duration(minutes: 1),
  ];

  static Duration normalizar(Duration preferencia) {
    if (preferencia < opciones.first) return opciones.first;
    if (preferencia > opciones.last) return opciones.last;
    return preferencia;
  }
}

/// Motor de polling reutilizable (07 §8.6).
///
/// Solo maneja el reloj: decide cuándo consultar y cuándo parar. Qué hacer en
/// cada consulta y si el estado ya es final es del notifier que lo usa, que
/// devuelve `true` en [onTick] mientras quiera seguir.
///
/// Aplica las reglas del documento:
/// - arranca al entrar a la pantalla ([start]) y para al salir ([stop]);
/// - se pausa en segundo plano y reanuda al volver ([setVisible]);
/// - se detiene cuando [onTick] responde `false` (estado final);
/// - ante errores espera cada vez más y se pausa al agotar los reintentos.
class PollingController {
  PollingController({
    required this.onTick,
    this.intervalo = FrecuenciaPolling.porDefecto,
    this.maxIntentos = 3,
    this.onError,
    this.onPausa,
  });

  /// Consulta a ejecutar. `true` = seguir, `false` = estado final.
  final Future<bool> Function() onTick;

  /// Cada cuánto consultar.
  final Duration intervalo;

  /// Reintentos permitidos tras un fallo antes de pausar.
  final int maxIntentos;

  final void Function(Object error, int intento)? onError;
  final void Function()? onPausa;

  Timer? _timer;
  int _fallos = 0;
  bool _detenido = true;
  bool _visible = true;
  bool _pausadoPorErrores = false;

  /// Si el reloj está corriendo. Un estado final o una pausa por errores lo
  /// dejan en `false` sin que nadie tenga que llamar a [stop].
  bool get isRunning => _timer != null || !_detenido;

  bool get pausadoPorErrores => _pausadoPorErrores;

  /// Última vez que se intentó consultar, para diagnostics.
  DateTime? get ultimaConsulta => _ultimaConsulta;
  DateTime? _ultimaConsulta;

  void start() {
    if (!_detenido) return;
    _detenido = false;
    _fallos = 0;
    _pausadoPorErrores = false;
    _programar(Duration.zero);
  }

  void stop() {
    _detenido = true;
    _fallos = 0;
    _timer?.cancel();
    _timer = null;
  }

  /// `reanudar` es el "reintentar" manual tras una pausa por errores: limpia el
  /// contador y vuelve a consultar de inmediato.
  void reanudar() {
    _pausadoPorErrores = false;
    _fallos = 0;
    _detenido = false;
    _programar(Duration.zero);
  }

  /// La pantalla está montada y la app en primer plano.
  void setVisible(bool visible) {
    if (_visible == visible) return;
    _visible = visible;
    if (!visible) {
      _timer?.cancel();
      _timer = null;
      return;
    }
    if (!_detenido && _timer == null) _programar(intervalo);
  }

  void _programar(Duration espera) {
    if (_detenido) return;
    _timer?.cancel();
    _timer = Timer(espera, _ejecutar);
  }

  Future<void> _ejecutar() async {
    _timer = null;
    if (_detenido || !_visible) return;
    _ultimaConsulta = DateTime.now();
    try {
      final seguir = await onTick();
      if (!seguir) {
        _detenido = true;
        return;
      }
      _fallos = 0;
      if (_visible) _programar(intervalo);
    } catch (error) {
      _fallos++;
      onError?.call(error, _fallos);
      if (_fallos > maxIntentos) {
        _detenido = true;
        _pausadoPorErrores = true;
        onPausa?.call();
        return;
      }
      if (_visible) _programar(_esperaDeReintento());
    }
  }

  /// Backoff exponencial: 2x, 4x, 8x… el intervalo base.
  Duration _esperaDeReintento() => intervalo * (1 << (_fallos.clamp(1, 8) - 1));
}
