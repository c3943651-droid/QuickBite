/// Riverpod 3 reintenta automáticamente los providers que fallan (hasta 10 veces
/// con backoff exponencial ante cualquier `Exception`). Los providers que
/// alimentan pantallas con estado de error y botón "Reintentar" deben
/// desactivar ese comportamiento: de lo contrario el error se oculta tras un
/// nuevo estado de carga y la petición se repite sin control del usuario.
Duration? noAutoRetry(int retryCount, Object error) => null;
