import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/quehacer.dart';

/// Error con mensaje traducido al español para mostrar en la interfaz.
class QuehaceresException implements Exception {
  const QuehaceresException(this.mensaje);
  final String mensaje;

  @override
  String toString() => mensaje;
}

/// Servicio para la gestión de quehaceres en Firestore.
class QuehaceresService {
  QuehaceresService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    String? usuarioActualId,
  })  : _firestoreOverride = firestore,
        _authOverride = auth,
        _usuarioActualIdOverride = usuarioActualId;

  final FirebaseFirestore? _firestoreOverride;
  final FirebaseAuth? _authOverride;
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
  static const msgErrorCargar = 'No se pudieron cargar los quehaceres';
  static const msgErrorCrear = 'No se pudo crear el quehacer';
  static const msgErrorActualizar = 'No se pudo actualizar el quehacer';
  static const msgErrorEliminar = 'No se pudo eliminar el quehacer';
  static const msgSesionExpirada = 'Tu sesión expiró, inicia sesión de nuevo';
  static const msgNoEsResponsable = 'Solo el responsable puede marcar este quehacer';
  static const msgSinPermiso = 'No tienes permiso para esta acción';
  static const msgResponsableInvalido = 'El responsable seleccionado no pertenece al hogar';

  /// Escucha en tiempo real los quehaceres asociados a un [hogarId].
  ///
  /// Se ordenan en memoria del cliente:
  /// 1. Pendientes primero (`hecho == false`).
  /// 2. Por `fechaLimite` más próxima (los que tienen fecha van antes que los que no tienen).
  /// 3. Por `titulo` alfabético.
  Stream<List<Quehacer>> observarQuehaceres(String hogarId) {
    return _db
        .collection('quehaceres')
        .where('hogarId', isEqualTo: hogarId)
        .snapshots()
        .map((snapshot) {
      final lista = snapshot.docs
          .map((doc) => Quehacer.fromMap(doc.id, doc.data()))
          .toList();

      lista.sort((a, b) {
        // 1. Pendientes antes que hechos
        if (a.hecho != b.hecho) {
          return a.hecho ? 1 : -1;
        }

        // 2. Orden por fecha límite (más próxima primero)
        if (a.fechaLimite != null && b.fechaLimite != null) {
          final compFecha = a.fechaLimite!.compareTo(b.fechaLimite!);
          if (compFecha != 0) return compFecha;
        } else if (a.fechaLimite != null && b.fechaLimite == null) {
          return -1;
        } else if (a.fechaLimite == null && b.fechaLimite != null) {
          return 1;
        }

        // 3. Orden por título
        return a.titulo.toLowerCase().compareTo(b.titulo.toLowerCase());
      });

      return lista;
    });
  }

  /// Crea un nuevo quehacer asignado a un integrante del hogar.
  Future<String> crearQuehacer({
    required String hogarId,
    required String titulo,
    required String asignadoA,
    DateTime? fechaLimite,
    bool esAdmin = true,
  }) async {
    final uid = usuarioActualId;
    if (uid == null) throw const QuehaceresException(msgSesionExpirada);

    final tituloLimpio = titulo.trim();
    if (tituloLimpio.isEmpty) {
      throw const QuehaceresException('El título no puede estar vacío');
    }

    if (!esAdmin) {
      throw const QuehaceresException('Solo el administrador puede crear quehaceres');
    }

    try {
      // Validar que el responsable pertenezca al mismo hogar
      final usuarioDoc = await _db.collection('usuarios').doc(asignadoA).get();
      if (!usuarioDoc.exists || usuarioDoc.data()?['hogarId'] != hogarId) {
        throw const QuehaceresException(msgResponsableInvalido);
      }

      final docRef = await _db.collection('quehaceres').add({
        'hogarId': hogarId,
        'titulo': tituloLimpio,
        'asignadoA': asignadoA,
        'hecho': false,
        'creadoPor': uid,
        'fechaLimite': fechaLimite != null ? Timestamp.fromDate(fechaLimite) : null,
      });

      return docRef.id;
    } on QuehaceresException {
      rethrow;
    } on FirebaseException catch (e) {
      debugPrint('Firestore error al crear quehacer: ${e.code}');
      throw const QuehaceresException(msgErrorCrear);
    } catch (_) {
      throw const QuehaceresException(msgSinConexion);
    }
  }

  /// Cambia el estado de hecho/pendiente de un quehacer.
  /// Solo el usuario responsable (`asignadoA == uid`) puede realizar esta acción.
  Future<void> marcarHecho({
    required String quehacerId,
    required String asignadoA,
    required bool nuevoEstado,
    String? uidActual,
  }) async {
    final uid = uidActual ?? usuarioActualId;
    if (uid == null) throw const QuehaceresException(msgSesionExpirada);

    if (uid != asignadoA) {
      throw const QuehaceresException(msgNoEsResponsable);
    }

    try {
      await _db.collection('quehaceres').doc(quehacerId).update({
        'hecho': nuevoEstado,
      });
    } on FirebaseException catch (e) {
      debugPrint('Firestore error al cambiar estado de quehacer: ${e.code}');
      throw const QuehaceresException(msgErrorActualizar);
    } catch (_) {
      throw const QuehaceresException(msgSinConexion);
    }
  }

  /// Actualiza los datos de un quehacer (título y/o fecha límite).
  /// Exclusivo para administradores.
  Future<void> actualizarQuehacer({
    required String quehacerId,
    required String titulo,
    DateTime? fechaLimite,
    bool limpiarFecha = false,
    bool esAdmin = true,
  }) async {
    if (!esAdmin) {
      throw const QuehaceresException(msgSinPermiso);
    }

    final tituloLimpio = titulo.trim();
    if (tituloLimpio.isEmpty) {
      throw const QuehaceresException('El título no puede estar vacío');
    }

    try {
      final Map<String, dynamic> datos = {
        'titulo': tituloLimpio,
      };

      if (limpiarFecha) {
        datos['fechaLimite'] = null;
      } else if (fechaLimite != null) {
        datos['fechaLimite'] = Timestamp.fromDate(fechaLimite);
      }

      await _db.collection('quehaceres').doc(quehacerId).update(datos);
    } on QuehaceresException {
      rethrow;
    } on FirebaseException catch (e) {
      debugPrint('Firestore error al actualizar quehacer: ${e.code}');
      throw const QuehaceresException(msgErrorActualizar);
    } catch (_) {
      throw const QuehaceresException(msgSinConexion);
    }
  }

  /// Reasigna un quehacer a otro integrante del hogar.
  /// Exclusivo para administradores.
  Future<void> reasignarQuehacer({
    required String quehacerId,
    required String nuevoAsignadoA,
    required String hogarId,
    bool esAdmin = true,
  }) async {
    if (!esAdmin) {
      throw const QuehaceresException(msgSinPermiso);
    }

    try {
      final usuarioDoc = await _db.collection('usuarios').doc(nuevoAsignadoA).get();
      if (!usuarioDoc.exists || usuarioDoc.data()?['hogarId'] != hogarId) {
        throw const QuehaceresException(msgResponsableInvalido);
      }

      await _db.collection('quehaceres').doc(quehacerId).update({
        'asignadoA': nuevoAsignadoA,
      });
    } on QuehaceresException {
      rethrow;
    } on FirebaseException catch (e) {
      debugPrint('Firestore error al reasignar quehacer: ${e.code}');
      throw const QuehaceresException(msgErrorActualizar);
    } catch (_) {
      throw const QuehaceresException(msgSinConexion);
    }
  }

  /// Elimina un quehacer de Firestore.
  /// Exclusivo para administradores.
  Future<void> eliminarQuehacer({
    required String quehacerId,
    bool esAdmin = true,
  }) async {
    if (!esAdmin) {
      throw const QuehaceresException(msgSinPermiso);
    }

    try {
      await _db.collection('quehaceres').doc(quehacerId).delete();
    } on FirebaseException catch (e) {
      debugPrint('Firestore error al eliminar quehacer: ${e.code}');
      throw const QuehaceresException(msgErrorEliminar);
    } catch (_) {
      throw const QuehaceresException(msgSinConexion);
    }
  }
}
