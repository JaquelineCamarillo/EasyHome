import 'package:flutter/material.dart';

/// Paleta de colores oficial de EasyHome basada en la identidad gráfica del logo.
class AppColors {
  // Los 5 colores oficiales de la marca
  static const Color azulPizarra = Color(0xFFAABACA); // #AABACA
  static const Color verdeOliva = Color(0xFF787F5D);  // #787F5D (Color principal)
  static const Color arenaTaupe = Color(0xFFBEA489);  // #BEA489 (Tonal / Acento cálido)
  static const Color bronceMocha = Color(0xFFA68568); // #A68568 (Acento secundario)
  static const Color linoClaro = Color(0xFFD3CCC4);   // #D3CCC4 (Bordes y separadores)

  // Colores de soporte y experiencia de usuario
  static const Color fondo = Color(0xFFF8F7F3);       // Crema lino muy suave y elegante
  static const Color superficie = Colors.white;       // Blanco puro para tarjetas
  static const Color borde = Color(0xFFE2DED6);        // Borde fino y sutil
  static const Color textoPrincipal = Color(0xFF2A2D25); // Carbón olivo profundo
  static const Color textoSecundario = Color(0xFF676B61); // Gris salvia suave
  static const Color exito = Color(0xFF4E775B);       // Verde natural de éxito
  static const Color error = Color(0xFFBA4A43);       // Rojo terracota suave
}

/// Definición del tema visual integral de EasyHome.
class AppTheme {
  static ThemeData get tema {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme(
        brightness: Brightness.light,
        primary: AppColors.verdeOliva,
        onPrimary: Colors.white,
        primaryContainer: const Color(0xFFE5E9DF),
        onPrimaryContainer: const Color(0xFF232B1E),
        secondary: AppColors.bronceMocha,
        onSecondary: Colors.white,
        secondaryContainer: const Color(0xFFF0E8DF),
        onSecondaryContainer: const Color(0xFF33251A),
        tertiary: AppColors.azulPizarra,
        onTertiary: Colors.white,
        tertiaryContainer: const Color(0xFFEBF0F5),
        onTertiaryContainer: const Color(0xFF1E2730),
        surface: AppColors.superficie,
        onSurface: AppColors.textoPrincipal,
        error: AppColors.error,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: AppColors.fondo,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: AppColors.textoPrincipal,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.4,
        ),
        iconTheme: IconThemeData(color: AppColors.verdeOliva),
      ),
      cardTheme: CardThemeData(
        color: AppColors.superficie,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.borde, width: 1.2),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.superficie,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        hintStyle: const TextStyle(color: Color(0xFF8F9489), fontSize: 14),
        labelStyle: const TextStyle(color: Color(0xFF676B61), fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.borde, width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.borde, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.verdeOliva, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.error, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.verdeOliva,
          foregroundColor: Colors.white,
          elevation: 1,
          shadowColor: AppColors.verdeOliva.withValues(alpha: 0.3),
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.verdeOliva,
          side: const BorderSide(color: AppColors.borde, width: 1.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
