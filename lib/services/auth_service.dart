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

/// Acceso a Firebase Auth + Firestore para registro e inicio de sesión.
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
  static const msgCredencialesIncorrectas = 'Correo o contraseña incorrectos';
  static const msgDemasiadosIntentos = 'Demasiados intentos, espera un momento';

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
      throw AuthException(_traducirRegistro(e.code));
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

  /// Inicia sesión y devuelve el `hogarId` del usuario (`null` si todavía no
  /// pertenece a ningún hogar). Lanza [AuthException] si algo falla.
  Future<String?> iniciarSesion({
    required String correo,
    required String contrasena,
  }) async {
    final UserCredential cred;
    try {
      cred = await _auth.signInWithEmailAndPassword(
        email: correo.trim(),
        password: contrasena,
      );
    } on FirebaseAuthException catch (e) {
      debugPrint('Auth error: ${e.code}');
      throw AuthException(_traducirLogin(e.code));
    }

    final user = cred.user;
    if (user == null) throw const AuthException(msgGenerico);

    try {
      final doc = await _db.collection('usuarios').doc(user.uid).get();
      return doc.data()?['hogarId'] as String?;
    } on FirebaseException catch (e) {
      debugPrint('Firestore error: ${e.code} - ${e.message}');
      // No dejamos una sesión abierta a medias si no pudimos leer el perfil.
      try {
        await _auth.signOut();
      } catch (_) {}
      throw const AuthException(msgSinConexion);
    }
  }

  String _traducirRegistro(String code) {
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

  String _traducirLogin(String code) {
    switch (code) {
      // Mensaje genérico a propósito: no revelar si el correo existe o no.
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return msgCredencialesIncorrectas;
      case 'too-many-requests':
        return msgDemasiadosIntentos;
      case 'network-request-failed':
        return msgSinConexion;
      case 'invalid-email':
        return 'Correo inválido';
      default:
        return msgGenerico;
    }
  }
}