# quickbite_mobile

QuickBite - App movil de pedidos. **Solo Android.**

El proyecto no incluye la carpeta `ios/`: la decision canonica es Android unico
(ver `docs/00 — Visión, Alcance y Posicionamiento.md` y `docs/05 — Decisiones
Canónicas y Simplificaciones.md`).

## Requisitos

- Flutter 3.47.4 (stable) o superior compatible con Dart SDK ^3.13.3
- Android SDK con JDK 17

## Comandos

```bash
flutter pub get
flutter run                       # dispositivo o emulador Android
flutter build apk --release       # APK de release
flutter analyze                   # lint (debe salir en 0 issues)
flutter test                      # suite de tests
```

## Estructura

```
lib/
  main.dart                 punto de entrada
  app.dart                  MaterialApp.router + tema
  src/
    core/                   config, red (Dio), errores, sesion, tema, widgets
    features/
      auth/                 login, registro, splash
      catalog/              catalogo de productos
      shell/                router y navegacion
tests en test/              mirrors de lib/ + test/support
```

Las features siguen Clean Architecture por capa: `data/` (DTOs + datasource +
repository impl), `domain/` (entidades + interfaz de repositorio) y
`presentation/` (providers Riverpod + pantallas).

## Documentacion

- `docs/07 — App Móvil Flutter Arquitectura.md`
- `docs/07.1 — Especificación de Pantallas Móviles.md`
- `docs/07.2 — Base Flutter: Estructura, Autenticación y Catálogo.md`
