import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/usuario.dart';
import '../utils/codigo_invitacion.dart';

class UsuarioException implements Exception {
  const UsuarioException(this.mensaje);
  final String mensaje;

  @override
  String toString() => mensaje;
}

/// Servicio para administración del perfil del usuario y membresía del hogar.
class UsuarioService {
  UsuarioService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    String? usuarioActualId,
  })  : _authOverride = auth,
        _firestoreOverride = firestore,
        _usuarioActualIdOverride = usuarioActualId;

  final FirebaseAuth? _authOverride;
  final FirebaseFirestore? _firestoreOverride;
  final String? _usuarioActualIdOverride;

  FirebaseAuth get _auth => _authOverride ?? FirebaseAuth.instance;
  FirebaseFirestore get _db => _firestoreOverride ?? FirebaseFirestore.instance;

  String? get usuarioActualId {
    if (_usuarioActualIdOverride != null) return _usuarioActualIdOverride;
    try {
      return _auth.currentUser?.uid;
    } catch (_) {
      return null;
    }
  }

  static const msgSinConexion = 'No se pudo conectar, intenta de nuevo';
  static const msgSesionExpirada = 'Tu sesión expiró, inicia sesión de nuevo';
  static const msgErrorActualizar = 'No se pudo actualizar el perfil';
  static const msgContrasenaIncorrecta = 'La contraseña actual es incorrecta';
  static const msgErrorContrasena = 'No se pudo cambiar la contraseña';

  /// Escucha en tiempo real el perfil del usuario actual.
  Stream<Usuario?> observarPerfilActual() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(null);

    return _db.collection('usuarios').doc(user.uid).snapshots().map((snap) {
      final data = snap.data();
      if (!snap.exists || data == null) return null;
      return Usuario.fromMap(user.uid, user.email ?? '', data);
    });
  }

  /// Obtiene los datos del usuario actual una sola vez.
  Future<Usuario?> obtenerPerfilActual() async {
    final user = _auth.currentUser;
    if (user == null) throw const UsuarioException(msgSesionExpirada);

    try {
      final snap = await _db.collection('usuarios').doc(user.uid).get();
      final data = snap.data();
      if (!snap.exists || data == null) return null;
      return Usuario.fromMap(user.uid, user.email ?? '', data);
    } on FirebaseException catch (e) {
      debugPrint('Firestore error: ${e.code}');
      throw const UsuarioException(msgSinConexion);
    }
  }

  /// Actualiza el nombre del usuario en Firestore y en Firebase Auth.
  Future<void> actualizarNombre(String nuevoNombre) async {
    final user = _auth.currentUser;
    if (user == null) throw const UsuarioException(msgSesionExpirada);

    final nombreLimpio = nuevoNombre.trim();
    try {
      await _db.collection('usuarios').doc(user.uid).update({
        'nombre': nombreLimpio,
      });
      await user.updateDisplayName(nombreLimpio);
    } on FirebaseException catch (e) {
      debugPrint('Firestore error al actualizar nombre: ${e.code}');
      throw const UsuarioException(msgErrorActualizar);
    }
  }

  /// Actualiza el color de identidad / avatar del usuario.
  Future<void> actualizarAvatarColor(String colorHex) async {
    final user = _auth.currentUser;
    if (user == null) throw const UsuarioException(msgSesionExpirada);

    try {
      await _db.collection('usuarios').doc(user.uid).update({
        'avatarColor': colorHex,
      });
    } on FirebaseException catch (e) {
      debugPrint('Firestore error al actualizar avatar: ${e.code}');
      throw const UsuarioException(msgErrorActualizar);
    }
  }

  /// Reautentica y cambia la contraseña del usuario.
  Future<void> cambiarContrasena({
    required String contrasenaActual,
    required String nuevaContrasena,
  }) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) {
      throw const UsuarioException(msgSesionExpirada);
    }

    try {
      final credencial = EmailAuthProvider.credential(
        email: user.email!,
        password: contrasenaActual,
      );
      await user.reauthenticateWithCredential(credencial);
      await user.updatePassword(nuevaContrasena);
    } on FirebaseAuthException catch (e) {
      debugPrint('Auth error cambio contraseña: ${e.code}');
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        throw const UsuarioException(msgContrasenaIncorrecta);
      }
      throw const UsuarioException(msgErrorContrasena);
    }
  }

  /// Cambia el rol de un integrante (Admin / Miembro).
  Future<void> cambiarRolIntegrante({
    required String integranteUid,
    required bool esAdmin,
  }) async {
    try {
      await _db.collection('usuarios').doc(integranteUid).update({
        'esAdministrador': esAdmin,
      });
    } on FirebaseException catch (e) {
      debugPrint('Firestore error al cambiar rol: ${e.code}');
      throw const UsuarioException(msgErrorActualizar);
    }
  }

  /// Expulsa o remueve a un integrante del hogar actual.
  Future<void> removerIntegrante({required String integranteUid}) async {
    try {
      await _db.collection('usuarios').doc(integranteUid).update({
        'hogarId': null,
        'esAdministrador': false,
      });
    } on FirebaseException catch (e) {
      debugPrint('Firestore error al remover integrante: ${e.code}');
      throw const UsuarioException(msgSinConexion);
    }
  }

  /// El usuario actual se sale voluntariamente de su hogar actual.
  Future<void> salirDelHogar() async {
    final user = _auth.currentUser;
    if (user == null) throw const UsuarioException(msgSesionExpirada);

    try {
      await _db.collection('usuarios').doc(user.uid).update({
        'hogarId': null,
        'esAdministrador': false,
      });
    } on FirebaseException catch (e) {
      debugPrint('Firestore error al salir del hogar: ${e.code}');
      throw const UsuarioException(msgSinConexion);
    }
  }

  /// Genera un nuevo código de invitación único para el hogar y lo actualiza.
  Future<String> regenerarCodigoHogar(String hogarId) async {
    try {
      final nuevoCodigo = await CodigoInvitacion.generarUnico((codigo) async {
        final query = await _db
            .collection('hogares')
            .where('codigoInvitacion', isEqualTo: codigo)
            .limit(1)
            .get();
        return query.docs.isNotEmpty;
      });

      if (nuevoCodigo == null) {
        throw const UsuarioException('No se pudo generar un código único');
      }

      await _db.collection('hogares').doc(hogarId).update({
        'codigoInvitacion': nuevoCodigo,
      });

      return nuevoCodigo;
    } on FirebaseException catch (e) {
      debugPrint('Firestore error al regenerar código: ${e.code}');
      throw const UsuarioException(msgSinConexion);
    }
  }
}
