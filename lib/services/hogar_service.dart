import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/hogar.dart';
import '../models/integrante.dart';
import '../utils/codigo_invitacion.dart';

/// Error ya traducido, listo para mostrarse al usuario.
class HogarException implements Exception {
  const HogarException(this.mensaje);
  final String mensaje;

  @override
  String toString() => mensaje;
}

enum _ResultadoUnion { unido, yaEsteHogar, yaOtroHogar, sinPerfil }

/// Operaciones sobre hogares en Firestore.
class HogarService {
  HogarService({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _authOverride = auth,
        _firestoreOverride = firestore;

  final FirebaseAuth? _authOverride;
  final FirebaseFirestore? _firestoreOverride;
  FirebaseAuth get _auth => _authOverride ?? FirebaseAuth.instance;
  FirebaseFirestore get _db => _firestoreOverride ?? FirebaseFirestore.instance;

  // Crear hogar
  static const msgNoSePudoCrear = 'No se pudo crear el hogar, intenta de nuevo';
  static const msgYaTieneHogar = 'Ya perteneces a un hogar';
  static const msgSesionExpirada = 'Tu sesión expiró, inicia sesión de nuevo';

  // Unirse a un hogar
  static const msgCodigoInvalido = 'Código inválido, verifica e intenta de nuevo';
  static const msgYaPerteneceEsteHogar = 'Ya perteneces a este hogar';
  static const msgSinConexion = 'No se pudo conectar, intenta de nuevo';
  static const msgNoSePudoUnir = 'No se pudo unir al hogar, intenta de nuevo';

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

  /// Une al usuario actual al hogar que tenga ese código de invitación, como
  /// integrante (no administrador). Devuelve el id del hogar.
  ///
  /// Si ya pertenece a ese hogar lanza [HogarException] sin escribir nada.
  Future<String> unirseAHogar({required String codigo}) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw const HogarException(msgSesionExpirada);

    final codigoNormalizado = codigo.trim().toUpperCase();

    try {
      // Query por campo (el código NO es el id del documento). Se fuerza
      // lectura del servidor: sin internet debe fallar, no responder "no existe"
      // con una caché vacía.
      final resultado = await _db
          .collection('hogares')
          .where('codigoInvitacion', isEqualTo: codigoNormalizado)
          .limit(1)
          .get(const GetOptions(source: Source.server));

      if (resultado.docs.isEmpty) throw const HogarException(msgCodigoInvalido);
      final hogarId = resultado.docs.first.id;

      final usuarioRef = _db.collection('usuarios').doc(uid);

      final estado = await _db.runTransaction<_ResultadoUnion>((tx) async {
        final usuario = await tx.get(usuarioRef);
        if (!usuario.exists) return _ResultadoUnion.sinPerfil;

        final actual = usuario.data()?['hogarId'] as String?;
        if (actual == hogarId) return _ResultadoUnion.yaEsteHogar;
        if (actual != null) return _ResultadoUnion.yaOtroHogar;

        tx.update(usuarioRef, {'hogarId': hogarId, 'esAdministrador': false});
        return _ResultadoUnion.unido;
      });

      switch (estado) {
        case _ResultadoUnion.unido:
          return hogarId;
        case _ResultadoUnion.yaEsteHogar:
          throw const HogarException(msgYaPerteneceEsteHogar);
        case _ResultadoUnion.yaOtroHogar:
          throw const HogarException(msgYaTieneHogar);
        case _ResultadoUnion.sinPerfil:
          throw const HogarException(msgNoSePudoUnir);
      }
    } on FirebaseException catch (e) {
      debugPrint('Firestore error: ${e.code} - ${e.message}');
      throw const HogarException(msgSinConexion);
    }
  }

  /// `hogarId` del usuario actual (`null` si todavía no tiene hogar).
  Future<String?> obtenerHogarIdActual() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw const HogarException(msgSesionExpirada);

    try {
      final doc = await _db.collection('usuarios').doc(uid).get();
      return doc.data()?['hogarId'] as String?;
    } on FirebaseException catch (e) {
      debugPrint('Firestore error: ${e.code} - ${e.message}');
      throw const HogarException(msgSinConexion);
    }
  }

  /// Documento del hogar en tiempo real (`null` si ya no existe).
  Stream<Hogar?> observarHogar(String hogarId) {
    return _db.collection('hogares').doc(hogarId).snapshots().map((snap) {
      final data = snap.data();
      if (!snap.exists || data == null) return null;
      return Hogar.fromMap(snap.id, data);
    });
  }

  /// Integrantes del hogar en tiempo real: administradores primero y luego
  /// por orden alfabético. Se ordena aquí para no requerir un índice
  /// compuesto en Firestore.
  Stream<List<Integrante>> observarIntegrantes(String hogarId) {
    return _db
        .collection('usuarios')
        .where('hogarId', isEqualTo: hogarId)
        .snapshots()
        .map((query) => Integrante.ordenar(
              query.docs.map((d) => Integrante.fromMap(d.id, d.data())),
            ));
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