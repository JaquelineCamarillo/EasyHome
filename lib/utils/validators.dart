/// Validaciones de los formularios de registro, inicio de sesión y hogar.
/// Devuelven `null` si el valor es válido, o el mensaje de error a mostrar.
class Validators {
  static final RegExp _emailRegex =
      RegExp(r'^[a-zA-Z0-9.!#$%&*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)+$');

  static const int maxNombreHogar = 30;
  static const int minContrasena = 8;
  static const int maxNombreUsuario = 60;
  static const int maxTituloQuehacer = 120;
  static const int maxNombreProducto = 120;

  /// Sanitiza entradas de texto previniendo caracteres nulos o de control invisibles.
  static String sanitizar(String? input) {
    if (input == null) return '';
    return input.replaceAll(RegExp(r'[\u0000-\u0008\u000B\u000C\u000E-\u001F]'), '').trim();
  }

  /// Sanitización básica para textos ingresados por el usuario
  static String sanitizarTexto(String? value) => sanitizar(value);

  static String? nombre(String? value) {
    final texto = (value ?? '').trim();
    if (texto.isEmpty) return 'Ingresa tu nombre';
    if (texto.length > maxNombreUsuario) return 'Máximo $maxNombreUsuario caracteres';
    return null;
  }

  static String? correo(String? value) {
    final texto = (value ?? '').trim();
    if (texto.isEmpty || !_emailRegex.hasMatch(texto)) return 'Correo inválido';
    if (texto.length > 120) return 'Correo demasiado largo';
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
    if (texto.length > maxNombreProducto) {
      return 'Máximo $maxNombreProducto caracteres';
    }
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
    if (numero > 99999) {
      return 'La cantidad no puede superar 99,999';
    }
    return null;
  }

  /// Título del quehacer: obligatorio y no solo espacios (#17).
  static String? tituloQuehacer(String? value) {
    final texto = (value ?? '').trim();
    if (texto.isEmpty) return 'Ingresa el título del quehacer';
    if (texto.length > maxTituloQuehacer) {
      return 'Máximo $maxTituloQuehacer caracteres';
    }
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
