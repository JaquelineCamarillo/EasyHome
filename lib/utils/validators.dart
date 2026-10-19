/// Validaciones de los formularios de registro e inicio de sesión.
/// Devuelven `null` si el valor es válido, o el mensaje de error a mostrar.
class Validators {
  static final RegExp _emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

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
}