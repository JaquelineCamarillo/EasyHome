import 'package:flutter/material.dart';

import '../routes.dart';

/// PLACEHOLDER del dashboard principal (compras + quehaceres).
/// Reemplazar por la pantalla real. El botón "Perfil del hogar" es temporal:
/// en la pantalla real el acceso será desde la barra de navegación inferior.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Dashboard (pendiente)'),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () =>
                  Navigator.of(context).pushNamed(AppRoutes.perfilHogar),
              icon: const Icon(Icons.group),
              label: const Text('Perfil del hogar'),
            ),
          ],
        ),
      ),
    );
  }
}