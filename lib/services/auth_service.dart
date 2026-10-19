import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Error ya traducido, listo para mostrarse al usuario.
class AuthException implements Exception {
  const AuthException(this.mensaje);
  final String mensaje;

  @override
  String toString() => mensaje;
}

/// Acceso a Firebase Auth + Firestore para el registro de usuarios.
/// Las pantallas no hablan directo con Firebase: pasan por este servicio.
class AuthService {
  AuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _authOverride = auth,
        _firestoreOverride = firestore;

  // Se resuelven de forma perezosa para poder heredar/mockear el servicio
  // en pruebas sin inicializar Firebase.
  final FirebaseAuth? _authOverride;
  final FirebaseFirestore? _firestoreOverride;
  FirebaseAuth get _auth => _authOverride ?? FirebaseAuth.instance;
  FirebaseFirestore get _db => _firestoreOverride ?? FirebaseFirestore.instance;

  static const msgCorreoEnUso = 'Este correo ya tiene una cuenta registrada';
  static const msgSinConexion = 'No se pudo conectar, intenta de nuevo';
  static const msgGenerico = 'Ocurrió un error, intenta de nuevo';

  /// Crea el usuario en Firebase Auth y su documento en `usuarios/{uid}`.
  /// Lanza [AuthException] con un mensaje en español si algo falla.
  Future<void> registrar({
    required String nombre,
    required String correo,
    required String contrasena,
  }) async {
    final UserCredential cred;
    try {
      cred = await _auth.createUserWithEmailAndPassword(
        email: correo.trim(),
        password: contrasena,
      );
    } on FirebaseAuthException catch (e) {
      debugPrint('Auth error: ${e.code}');
      throw AuthException(_traducir(e.code));
    }

    final user = cred.user;
    if (user == null) throw const AuthException(msgGenerico);

    try {
      await _db.collection('usuarios').doc(user.uid).set({
        'nombre': nombre.trim(),
        'esAdministrador': false,
        'hogarId': null,
      });
    } on FirebaseException catch (e) {
      debugPrint('Firestore error: ${e.code} - ${e.message}');
      // Revertimos el usuario de Auth para que no quede una cuenta sin perfil
      // y pueda reintentar el registro con el mismo correo.
      try {
        await user.delete();
      } catch (_) {}
      throw const AuthException(msgSinConexion);
    }
  }

  String _traducir(String code) {
    switch (code) {
      case 'email-already-in-use':
        return msgCorreoEnUso;
      case 'network-request-failed':
        return msgSinConexion;
      case 'invalid-email':
        return 'Correo inválido';
      case 'weak-password':
        return 'La contraseña debe tener al menos 6 caracteres';
      default:
        return msgGenerico;
    }
  }
}