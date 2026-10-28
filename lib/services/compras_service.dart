import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/producto.dart';

/// Error ya traducido para mostrarse al usuario.
class ComprasException implements Exception {
  const ComprasException(this.mensaje);
  final String mensaje;

  @override
  String toString() => mensaje;
}

/// Acceso a Firestore para la lista de compras del hogar.
class ComprasService {
  ComprasService({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _authOverride = auth,
        _firestoreOverride = firestore;

  final FirebaseAuth? _authOverride;
  final FirebaseFirestore? _firestoreOverride;
  FirebaseAuth get _auth => _authOverride ?? FirebaseAuth.instance;
  FirebaseFirestore get _db => _firestoreOverride ?? FirebaseFirestore.instance;

  static const msgSinConexion = 'No se pudo conectar, intenta de nuevo';
  static const msgErrorCargar = 'No se pudieron cargar los productos';
  static const msgErrorActualizar = 'No se pudo actualizar el producto';
  static const msgErrorAgregar = 'No se pudo agregar el producto';

  /// Escucha en tiempo real los productos asociados a [hogarId].
  /// Se ordenan por `fechaCreacion` (más reciente primero).
  ///
  /// La ordenación se realiza en memoria para no depender de la creación manual
  /// de un índice compuesto en Firestore (`hogarId` + `fechaCreacion`).
  Stream<List<Producto>> observarProductos(String hogarId) {
    return _db
        .collection('productos')
        .where('hogarId', isEqualTo: hogarId)
        .snapshots()
        .map((snapshot) {
      final lista = snapshot.docs
          .map((doc) => Producto.fromMap(doc.id, doc.data()))
          .toList();

      // Ordenar por fechaCreacion (más reciente primero).
      lista.sort((a, b) {
        if (a.fechaCreacion == null && b.fechaCreacion == null) return 0;
        if (a.fechaCreacion == null) return 1;
        if (b.fechaCreacion == null) return -1;
        return b.fechaCreacion!.compareTo(a.fechaCreacion!);
      });

      return lista;
    });
  }

  /// Cambia el estado de un producto entre pendiente y comprado.
  Future<void> cambiarEstado({
    required String productoId,
    required bool comprado,
  }) async {
    try {
      await _db.collection('productos').doc(productoId).update({
        'comprado': comprado,
      });
    } on FirebaseException catch (e) {
      debugPrint('Firestore error al actualizar producto: ${e.code}');
      throw const ComprasException(msgErrorActualizar);
    }
  }

  /// Agrega un nuevo producto a la lista de compras del hogar.
  Future<String> agregarProducto({
    required String hogarId,
    required String nombre,
    required String cantidad,
  }) async {
    try {
      final docRef = await _db.collection('productos').add({
        'hogarId': hogarId,
        'nombre': nombre.trim(),
        'cantidad': cantidad.trim(),
        'comprado': false,
        'creadoPor': _auth.currentUser?.uid,
        'fechaCreacion': FieldValue.serverTimestamp(),
      });
      return docRef.id;
    } on FirebaseException catch (e) {
      debugPrint('Firestore error al agregar producto: ${e.code}');
      throw const ComprasException(msgErrorAgregar);
    }
  }

  /// Elimina un producto de la lista de compras.
  Future<void> eliminarProducto(String productoId) async {
    try {
      await _db.collection('productos').doc(productoId).delete();
    } on FirebaseException catch (e) {
      debugPrint('Firestore error al eliminar producto: ${e.code}');
      throw const ComprasException(msgSinConexion);
    }
  }
}
