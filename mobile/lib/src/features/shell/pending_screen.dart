import 'package:flutter/material.dart';

/// Marcador de una pantalla cuyo hito todavía no ha llegado.
///
/// H0.2 fija la arquitectura de navegación (07 §10.2 y §10.4) antes de que
/// existan las 41 pantallas pendientes, así que cada ruta de la tabla necesita
/// un destino real y verificable. El `ValueKey` permite que los tests
/// comprueben que la ruta existe y resuelve, sin afirmar sobre el texto.
class PendingScreen extends StatelessWidget {
  const PendingScreen({super.key, required this.location, required this.title});

  final String location;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: ValueKey('pending:$location'),
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            '$title llegará en el próximo hito.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ),
    );
  }
}
