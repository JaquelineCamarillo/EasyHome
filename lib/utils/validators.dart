/// Validaciones de los formularios de registro, inicio de sesión y hogar.
/// Devuelven `null` si el valor es válido, o el mensaje de error a mostrar.
class Validators {
  static final RegExp _emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  static const int maxNombreHogar = 30;

  static String? nombre(String? value) {
    if ((value ?? '').trim().isEmpty) return 'Ingresa tu nombre';
    return null;
  }

  static String? correo(String? value) {
    if (!_emailRegex.hasMatch((value ?? '').trim())) return 'Correo inválido';
    return null;
  }

  /// Registro: Firebase Auth exige mínimo 6 caracteres.
  static String? contrasena(String? value) {
    if ((value ?? '').length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres';
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

  /// Nombre del producto: obligatorio.
  static String? nombreProducto(String? value) {
    if ((value ?? '').trim().isEmpty) return 'Ingresa el nombre del producto';
    return null;
  }

  /// Cantidad del producto: obligatoria.
  static String? cantidadProducto(String? value) {
    if ((value ?? '').trim().isEmpty) return 'Ingresa la cantidad';
    return null;
  }
}
