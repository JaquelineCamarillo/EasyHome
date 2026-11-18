import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Widget con el logo oficial de EasyHome con fondo transparente y alta resolución.
class EasyHomeLogo extends StatelessWidget {
  const EasyHomeLogo({
    super.key,
    this.size = 80,
    this.mostrarSombra = true,
  });

  final double size;
  final bool mostrarSombra;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: mostrarSombra
            ? [
                BoxShadow(
                  color: AppColors.verdeOliva.withValues(alpha: 0.16),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: AppColors.arenaTaupe.withValues(alpha: 0.22),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      padding: EdgeInsets.all(size * 0.16),
      child: Image.asset(
        'assets/images/logo.png',
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          // Fallback seguro en entornos sin carga de assets de disco
          return Icon(
            Icons.home_work_rounded,
            size: size * 0.55,
            color: AppColors.verdeOliva,
          );
        },
      ),
    );
  }
}
