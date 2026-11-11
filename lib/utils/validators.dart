/// Validaciones de los formularios de registro, inicio de sesión y hogar.
/// Devuelven `null` si el valor es válido, o el mensaje de error a mostrar.
class Validators {
  static final RegExp _emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  static const int maxNombreHogar = 30;
  static const int minContrasena = 8;

  /// Sanitización básica para textos ingresados por el usuario
  static String sanitizarTexto(String? value) => (value ?? '').trim();

  static String? nombre(String? value) {
    if ((value ?? '').trim().isEmpty) return 'Ingresa tu nombre';
    return null;
  }

  static String? correo(String? value) {
    final texto = (value ?? '').trim();
    if (texto.isEmpty || !_emailRegex.hasMatch(texto)) return 'Correo inválido';
    return null;
  }

  /// Registro y cambio: política fortalecida (#22) con mínimo 8 caracteres, al menos 1 letra y 1 número.
  static String? contrasena(String? value) {
    final texto = value ?? '';
    if (texto.length < minContrasena) {
      return 'La contraseña debe tener al menos 8 caracteres';
    }
    if (!tieneLetra(texto)) {
      return 'La contraseña debe incluir al menos una letra';
    }
    if (!tieneNumero(texto)) {
      return 'La contraseña debe incluir al menos un número';
    }
    return null;
  }

  /// Login: solo se exige que no esté vacía.
  static String? contrasenaNoVacia(String? value) {
    if ((value ?? '').isEmpty) return 'Ingresa tu contraseña';
    return null;
  }

  static String? confirmarContrasena(String? value, String contrasena) {
    if (value != contrasena) return 'Las contraseñas no coinciden';
    return null;
  }

  /// Nombre del hogar: obligatorio y máximo [maxNombreHogar] caracteres.
  static String? nombreHogar(String? value) {
    final texto = (value ?? '').trim();
    if (texto.isEmpty) return 'Ingresa el nombre del hogar';
    if (texto.length > maxNombreHogar) {
      return 'Máximo $maxNombreHogar caracteres';
    }
    return null;
  }

  /// Nombre del producto: obligatorio y no vacío.
  static String? nombreProducto(String? value) {
    final texto = (value ?? '').trim();
    if (texto.isEmpty) return 'Ingresa el nombre del producto';
    if (texto.length < 2) return 'El nombre debe tener al menos 2 letras';
    return null;
  }

  /// Cantidad del producto: número entero mayor a 0.
  static String? cantidadProducto(String? value) {
    final texto = (value ?? '').trim();
    if (texto.isEmpty) return 'Ingresa la cantidad';
    final numero = int.tryParse(texto);
    if (numero == null || numero <= 0) {
      return 'La cantidad debe ser un número entero mayor a 0';
    }
    return null;
  }

  /// Título del quehacer: obligatorio y no solo espacios (#17).
  static String? tituloQuehacer(String? value) {
    final texto = (value ?? '').trim();
    if (texto.isEmpty) return 'Ingresa el título del quehacer';
    return null;
  }

  static String? titulo(String? value) => tituloQuehacer(value);

  // --- Indicadores visuales de formato de contraseña ---
  static bool tieneMinimo6(String? value) => (value ?? '').length >= 6;
  static bool tieneMinimo8(String? value) => (value ?? '').length >= 8;
  static bool tieneLetra(String? value) => RegExp(r'[a-zA-Z]').hasMatch(value ?? '');
  static bool tieneNumero(String? value) => RegExp(r'[0-9]').hasMatch(value ?? '');
  static bool tieneMayuscula(String? value) => RegExp(r'[A-Z]').hasMatch(value ?? '');

  /// Nivel de seguridad entre 0.0 y 1.0 para el indicador visual (#22)
  static double nivelSeguridadContrasena(String? value) {
    if (value == null || value.isEmpty) return 0.0;
    double score = 0.0;
    if (value.length >= 8) {
      score += 0.40;
    } else if (value.length >= 6) {
      score += 0.20;
    }
    if (tieneLetra(value)) score += 0.30;
    if (tieneNumero(value)) score += 0.30;
    return score.clamp(0.0, 1.0);
  }
}
