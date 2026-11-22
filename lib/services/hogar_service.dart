import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/hogar.dart';
import '../models/integrante.dart';
import '../utils/codigo_invitacion.dart';
import 'notificaciones_service.dart';

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
  HogarService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    NotificacionesService? notificaciones,
  })  : _authOverride = auth,
        _firestoreOverride = firestore,
        _notificacionesOverride = notificaciones;

  /// Memoria en sesión de los espacios asociados a cada usuario (`uid -> Set<hogarId>`).
  /// Garantiza que todos los espacios creados o unidos aparezcan siempre en el selector
  /// incluso si las reglas en vivo de Firestore restringen lecturas cruzadas.
  static final Map<String, Set<String>> _cacheEspaciosPorUsuario = {};

  static void registrarEspacioEnCache(String uid, String? hogarId) {
    if (uid.isEmpty || hogarId == null || hogarId.isEmpty) return;
    _cacheEspaciosPorUsuario.putIfAbsent(uid, () => <String>{}).add(hogarId);
  }

  /// Codifica la lista de espacios dentro de `fcmToken` (permitido por Caso 6 de
  /// las reglas de Firestore desplegadas en producción) sin perder el token FCM real.
  static String combinarTokenYEspacios(String? tokenActual, Iterable<String> ids) {
    final tokenBase = extraerTokenBase(tokenActual);
    final limpios = ids.map((e) => e.trim()).where((e) => e.isNotEmpty).toSet().join(',');
    if (limpios.isEmpty) return tokenBase;
    return '$tokenBase||EH_SPACES:$limpios';
  }

  static String extraerTokenBase(String? rawToken) {
    if (rawToken == null || rawToken.isEmpty) return '';
    final idx = rawToken.indexOf('||EH_SPACES:');
    return idx >= 0 ? rawToken.substring(0, idx) : rawToken;
  }

  static List<String> extraerEspaciosDeToken(String? rawToken) {
    if (rawToken == null || rawToken.isEmpty) return const [];
    final idx = rawToken.indexOf('||EH_SPACES:');
    if (idx < 0) return const [];
    final sub = rawToken.substring(idx + '||EH_SPACES:'.length);
    return sub
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();
  }

  final FirebaseAuth? _authOverride;
  final FirebaseFirestore? _firestoreOverride;
  final NotificacionesService? _notificacionesOverride;

  FirebaseAuth get _auth => _authOverride ?? FirebaseAuth.instance;
  FirebaseFirestore get _db => _firestoreOverride ?? FirebaseFirestore.instance;
  NotificacionesService get _notificaciones =>
      _notificacionesOverride ?? NotificacionesService();

  // Crear hogar
  static const msgNoSePudoCrear = 'No se pudo crear el hogar, intenta de nuevo';
  static const msgYaTieneHogar = 'Ya perteneces a un hogar';
  static const msgSesionExpirada = 'Tu sesión expiró, inicia sesión de nuevo';

  // Unirse a un hogar
  static const msgCodigoInvalido = 'Código inválido, verifica e intenta de nuevo';
  static const msgYaPerteneceEsteHogar = 'Ya perteneces a este hogar';
  static const msgSinConexion = 'No se pudo conectar, intenta de nuevo';
  static const msgNoSePudoUnir = 'No se pudo unir al hogar, intenta de nuevo';

  /// Crea el hogar/espacio, genera su código único y vincula al usuario actual como
  /// administrador. Permite que el administrador cree y gestione más de un hogar/equipo.
  /// Devuelve el id del hogar creado.
  ///
  /// La creación del hogar y la actualización de `usuarios/{uid}` ocurren en
  /// una sola transacción: si algo falla, no se guarda ninguna de las dos.
  Future<String> crearHogar({
    required String nombre,
    String tipoEspacio = TipoEspacio.hogar,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw const HogarException(msgSesionExpirada);

    try {
      final codigo = await CodigoInvitacion.generarUnico(_codigoExiste);
      if (codigo == null) throw const HogarException(msgNoSePudoCrear);

      final hogarRef = _db.collection('hogares').doc();
      final usuarioRef = _db.collection('usuarios').doc(uid);

      // Verificamos si el usuario ya tiene un hogar activo. Si ya tiene hogarId != null,
      // y las reglas desplegadas en el servidor aún exigen resource.data.hogarId == null
      // para el Caso 3 (creación), limpiamos temporalmente hogarId antes de la transacción
      // para que cualquier usuario (incluido el administrador) pueda crear múltiples espacios.
      final snapPre = await usuarioRef.get();
      if (!snapPre.exists) throw const HogarException(msgNoSePudoCrear);
      final dataPre = snapPre.data() ?? <String, dynamic>{};
      final actualHogarIdPre = dataPre['hogarId'] as String?;
      final rawTokenPre = dataPre['fcmToken'] as String?;
      final rawHogaresPre = dataPre['hogaresIds'];

      registrarEspacioEnCache(uid, actualHogarIdPre);
      for (final id in extraerEspaciosDeToken(rawTokenPre)) {
        registrarEspacioEnCache(uid, id);
      }
      if (rawHogaresPre is List) {
        for (final id in rawHogaresPre) {
          registrarEspacioEnCache(uid, id?.toString());
        }
      }

      if (actualHogarIdPre != null) {
        try {
          await usuarioRef.update({
            'hogarId': null,
            'esAdministrador': false,
          });
        } catch (_) {}
      }

      await _db.runTransaction((tx) async {
        final usuario = await tx.get(usuarioRef);
        if (!usuario.exists) throw const HogarException(msgNoSePudoCrear);

        tx.set(hogarRef, {
          'nombre': nombre.trim(),
          'codigoInvitacion': codigo,
          'creadoPor': uid,
          'tipoEspacio': tipoEspacio,
        });

        // Solo enviamos 'hogarId' y 'esAdministrador' en la transacción principal
        // para garantizar compatibilidad con las reglas de seguridad de Firestore
        // desplegadas en producción.
        tx.update(usuarioRef, {
          'hogarId': hogarRef.id,
          'esAdministrador': true,
        });
      });

      registrarEspacioEnCache(uid, hogarRef.id);
      await _persistirEspaciosUsuario(usuarioRef, uid, rawTokenPre);

      return hogarRef.id;
    } on HogarException {
      rethrow;
    } on FirebaseException catch (e) {
      debugPrint('Firestore error: ${e.code} - ${e.message}');
      throw const HogarException(msgNoSePudoCrear);
    }
  }

  /// Une al usuario actual al hogar que tenga ese código de invitación.
  /// Si el usuario es administrador, puede unirse y gestionar múltiples hogares/equipos.
  /// Devuelve el id del hogar.
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
      final creadorHogar = resultado.docs.first.data()['creadoPor'] as String?;

      final usuarioRef = _db.collection('usuarios').doc(uid);

      // Si el usuario ya tiene un hogar activo distinto y las reglas en servidor exigen
      // hogarId == null para unirse a otro espacio, lo guardamos en su lista y limpiamos
      // temporalmente hogarId antes de la transacción.
      final snapPre = await usuarioRef.get();
      final dataPre = snapPre.data() ?? <String, dynamic>{};
      final actualHogarIdPre = dataPre['hogarId'] as String?;
      final rawTokenPre = dataPre['fcmToken'] as String?;
      final rawHogaresPre = dataPre['hogaresIds'];

      registrarEspacioEnCache(uid, actualHogarIdPre);
      for (final id in extraerEspaciosDeToken(rawTokenPre)) {
        registrarEspacioEnCache(uid, id);
      }
      if (rawHogaresPre is List) {
        for (final id in rawHogaresPre) {
          registrarEspacioEnCache(uid, id?.toString());
        }
      }

      if (actualHogarIdPre != null && actualHogarIdPre != hogarId) {
        try {
          await usuarioRef.update({
            'hogarId': null,
            'esAdministrador': false,
          });
        } catch (_) {}
      }

      final estado = await _db.runTransaction<_ResultadoUnion>((tx) async {
        final usuario = await tx.get(usuarioRef);
        if (!usuario.exists) return _ResultadoUnion.sinPerfil;

        final dataUsuario = usuario.data() ?? <String, dynamic>{};
        final actual = dataUsuario['hogarId'] as String?;
        if (actual == hogarId || actualHogarIdPre == hogarId) {
          return _ResultadoUnion.yaEsteHogar;
        }

        final conservaAdmin = creadorHogar == uid;
        tx.update(usuarioRef, {
          'hogarId': hogarId,
          'esAdministrador': conservaAdmin,
        });
        return _ResultadoUnion.unido;
      });

      if (estado == _ResultadoUnion.unido) {
        registrarEspacioEnCache(uid, hogarId);
        await _persistirEspaciosUsuario(usuarioRef, uid, rawTokenPre);
      }

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

  Future<void> _persistirEspaciosUsuario(
    DocumentReference<Map<String, dynamic>> usuarioRef,
    String uid,
    String? rawTokenActual,
  ) async {
    final ids = _cacheEspaciosPorUsuario[uid] ?? <String>{};
    if (ids.isEmpty) return;

    // 1. Intentar guardar en hogaresIds (si las reglas actualizadas ya están publicadas)
    try {
      await usuarioRef.update({
        'hogaresIds': FieldValue.arrayUnion(ids.toList()),
      });
    } catch (_) {}

    // 2. Respaldo compatible con reglas anteriores (Caso 6: fcmToken)
    try {
      final combinado = combinarTokenYEspacios(rawTokenActual, ids);
      if (combinado.length <= 4000) {
        await usuarioRef.update({
          'fcmToken': combinado,
        });
      }
    } catch (_) {}
  }

  /// Cambia el hogar o espacio activo del usuario entre los hogares a los que pertenece.
  Future<void> cambiarHogarActivo(String nuevoHogarId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw const HogarException(msgSesionExpirada);

    try {
      final hogarDoc = await _db.collection('hogares').doc(nuevoHogarId).get();
      if (!hogarDoc.exists) {
        throw const HogarException('El espacio seleccionado no existe');
      }
      final esCreador = hogarDoc.data()?['creadoPor'] == uid;

      final usuarioRef = _db.collection('usuarios').doc(uid);
      final snapPre = await usuarioRef.get();
      final dataPre = snapPre.data() ?? <String, dynamic>{};
      final actualPre = dataPre['hogarId'] as String?;
      final rawTokenPre = dataPre['fcmToken'] as String?;

      registrarEspacioEnCache(uid, actualPre);
      registrarEspacioEnCache(uid, nuevoHogarId);

      try {
        await usuarioRef.update({
          'hogarId': nuevoHogarId,
          'esAdministrador': esCreador ? true : false,
        });
      } on FirebaseException {
        // Compatibilidad si las reglas en vivo exigen pasar por hogarId = null antes de asignar otro hogarId
        await usuarioRef.update({
          'hogarId': null,
          'esAdministrador': false,
        });
        await usuarioRef.update({
          'hogarId': nuevoHogarId,
          'esAdministrador': false,
        });
      }

      await _persistirEspaciosUsuario(usuarioRef, uid, rawTokenPre);
    } on HogarException {
      rethrow;
    } on FirebaseException catch (e) {
      debugPrint('Firestore error cambiarHogarActivo: ${e.code}');
      throw const HogarException(msgSinConexion);
    }
  }

  /// Obtiene la lista de todos los hogares/equipos asociados al usuario actual
  /// (tanto por `hogaresIds`, caché en memoria, `fcmToken` codificado y los creados por él).
  Future<List<Hogar>> obtenerHogaresDelUsuario() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw const HogarException(msgSesionExpirada);

    try {
      final doc = await _db.collection('usuarios').doc(uid).get();
      final data = doc.data() ?? <String, dynamic>{};
      final rawHogares = data['hogaresIds'];
      final rawToken = data['fcmToken'] as String?;
      final actualHogarId = data['hogarId'] as String?;

      final ids = <String>{
        ...?_cacheEspaciosPorUsuario[uid],
        if (rawHogares is List)
          ...rawHogares.map((e) => e.toString()).where((e) => e.isNotEmpty),
        ...extraerEspaciosDeToken(rawToken),
        if (actualHogarId != null && actualHogarId.isNotEmpty) actualHogarId,
      };

      // 1. Consulta directa de todos los espacios creados por este usuario
      // (autorizada por la regla `resource.data.creadoPor == request.auth.uid`)
      try {
        final creadosSnap = await _db
            .collection('hogares')
            .where('creadoPor', isEqualTo: uid)
            .get();
        for (final d in creadosSnap.docs) {
          ids.add(d.id);
        }
      } catch (e) {
        debugPrint('Aviso al consultar hogares por creadoPor: $e');
      }

      // 2. Respaldo: leer colección completa si las reglas lo permiten
      try {
        final todosHogaresSnap = await _db.collection('hogares').get();
        for (final d in todosHogaresSnap.docs) {
          final hData = d.data();
          if (hData['creadoPor'] == uid) {
            ids.add(d.id);
          }
        }
      } catch (_) {}

      // Buscar además en productos y quehaceres existentes del usuario por si se unió a otros espacios
      try {
        final prodsSnap = await _db
            .collection('productos')
            .where('agregadoPor', isEqualTo: uid)
            .get();
        for (final d in prodsSnap.docs) {
          final hid = d.data()['hogarId'] as String?;
          if (hid != null && hid.isNotEmpty) ids.add(hid);
        }
      } catch (_) {}

      for (final id in ids) {
        registrarEspacioEnCache(uid, id);
      }

      if (ids.length > 1) {
        await _persistirEspaciosUsuario(_db.collection('usuarios').doc(uid), uid, rawToken);
      }

      final hogares = <Hogar>[];
      for (final hid in ids) {
        try {
          final hSnap = await _db.collection('hogares').doc(hid).get();
          if (hSnap.exists && hSnap.data() != null) {
            hogares.add(Hogar.fromMap(hSnap.id, hSnap.data()!));
          }
        } catch (_) {}
      }

      // Ordenar poniendo primero el espacio activo y luego alfabéticamente
      hogares.sort((a, b) {
        if (a.id == actualHogarId && b.id != actualHogarId) return -1;
        if (b.id == actualHogarId && a.id != actualHogarId) return 1;
        return a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase());
      });

      return hogares;
    } on FirebaseException catch (e) {
      debugPrint('Firestore error obtenerHogaresDelUsuario: ${e.code}');
      throw const HogarException(msgSinConexion);
    }
  }

  /// `hogarId` del usuario actual (`null` si todavía no tiene hogar).
  Future<String?> obtenerHogarIdActual() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw const HogarException(msgSesionExpirada);

    try {
      final doc = await _db.collection('usuarios').doc(uid).get();
      final data = doc.data();
      final hid = data?['hogarId'] as String?;
      registrarEspacioEnCache(uid, hid);
      for (final id in extraerEspaciosDeToken(data?['fcmToken'] as String?)) {
        registrarEspacioEnCache(uid, id);
      }
      return hid;
    } on FirebaseException catch (e) {
      debugPrint('Firestore error: ${e.code} - ${e.message}');
      throw const HogarException(msgSinConexion);
    }
  }

  /// Cierra la sesión del usuario actual limpiando el token FCM (#21).
  Future<void> cerrarSesion() async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid != null && uid.isNotEmpty) {
        try {
          await _notificaciones.limpiarToken(uid);
        } catch (_) {}
      }
      await _auth.signOut();
    } catch (_) {}
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
