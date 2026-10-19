import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../utils/codigo_invitacion.dart';

/// Error ya traducido, listo para mostrarse al usuario.
class HogarException implements Exception {
  const HogarException(this.mensaje);
  final String mensaje;

  @override
  String toString() => mensaje;
}

/// Operaciones sobre hogares en Firestore.
class HogarService {
  HogarService({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _authOverride = auth,
        _firestoreOverride = firestore;

  final FirebaseAuth? _authOverride;
  final FirebaseFirestore? _firestoreOverride;
  FirebaseAuth get _auth => _authOverride ?? FirebaseAuth.instance;
  FirebaseFirestore get _db => _firestoreOverride ?? FirebaseFirestore.instance;

  static const msgNoSePudoCrear = 'No se pudo crear el hogar, intenta de nuevo';
  static const msgYaTieneHogar = 'Ya perteneces a un hogar';
  static const msgSesionExpirada = 'Tu sesión expiró, inicia sesión de nuevo';

  /// Crea el hogar, genera su código único y vincula al usuario actual como
  /// administrador. Devuelve el id del hogar creado.
  ///
  /// La creación del hogar y la actualización de `usuarios/{uid}` ocurren en
  /// una sola transacción: si algo falla, no se guarda ninguna de las dos.
  Future<String> crearHogar({required String nombre}) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw const HogarException(msgSesionExpirada);

    try {
      final codigo = await CodigoInvitacion.generarUnico(_codigoExiste);
      if (codigo == null) throw const HogarException(msgNoSePudoCrear);

      final hogarRef = _db.collection('hogares').doc();
      final usuarioRef = _db.collection('usuarios').doc(uid);

      await _db.runTransaction((tx) async {
        final usuario = await tx.get(usuarioRef);
        if (!usuario.exists) throw const HogarException(msgNoSePudoCrear);
        if (usuario.data()?['hogarId'] != null) {
          throw const HogarException(msgYaTieneHogar);
        }

        tx.set(hogarRef, {
          'nombre': nombre.trim(),
          'codigoInvitacion': codigo,
          'creadoPor': uid,
        });
        tx.update(usuarioRef, {
          'hogarId': hogarRef.id,
          'esAdministrador': true,
        });
      });

      return hogarRef.id;
    } on FirebaseException catch (e) {
      debugPrint('Firestore error: ${e.code} - ${e.message}');
      throw const HogarException(msgNoSePudoCrear);
    }
  }

  Future<bool> _codigoExiste(String codigo) async {
    final resultado = await _db
        .collection('hogares')
        .where('codigoInvitacion', isEqualTo: codigo)
        .limit(1)
        .get();
    return resultado.docs.isNotEmpty;
  }
}