import 'package:flutter/painting.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Limpieza de la caché de imágenes (07.1 SCR-PROF-14).
///
/// Las imágenes de producto llegan de Supabase y las guarda
/// `cached_network_image` en dos sitios: la caché de imágenes de Flutter (que
/// vive mientras la app está abierta) y la de disco, que sobrevive al cierre.
/// Liberar solo una deja el espacio ocupado, así que se limpian las dos.
///
/// Va detrás de una interfaz para que los tests no dependan del disco.
abstract interface class ImageCacheCleaner {
  Future<void> limpiar();
}

class DefaultImageCacheCleaner implements ImageCacheCleaner {
  const DefaultImageCacheCleaner();

  @override
  Future<void> limpiar() async {
    PaintingBinding.instance.imageCache
      ..clear()
      ..clearLiveImages();
    await DefaultCacheManager().emptyCache();
  }
}
