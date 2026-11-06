import 'package:flutter/material.dart';

/// Pantalla #17 — Formulario para agregar quehacer.
/// Placeholder para la rama #16 ("Próximamente"). Se completará en #17.
class AgregarQuehacerScreen extends StatelessWidget {
  const AgregarQuehacerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agregar quehacer'),
      ),
      body: const Center(
        child: Text(
          'Próximamente',
          style: TextStyle(fontSize: 18, color: Colors.black54),
        ),
      ),
    );
  }
}
