import 'package:cloud_firestore/cloud_firestore.dart';

/// Documento de `productos/{productoId}`.
class Producto {
  const Producto({
    required this.id,
    required this.hogarId,
    required this.nombre,
    required this.cantidad,
    this.comprado = false,
    this.creadoPor,
    this.fechaCreacion,
  });

  final String id;
  final String hogarId;
  final String nombre;
  final String cantidad;
  final bool comprado;
  final String? creadoPor;
  final DateTime? fechaCreacion;

  factory Producto.fromMap(String id, Map<String, dynamic> data) {
    DateTime? fecha;
    final rawFecha = data['fechaCreacion'];
    if (rawFecha is Timestamp) {
      fecha = rawFecha.toDate();
    } else if (rawFecha is DateTime) {
      fecha = rawFecha;
    }

    return Producto(
      id: id,
      hogarId: (data['hogarId'] as String?) ?? '',
      nombre: (data['nombre'] as String?) ?? '',
      cantidad: (data['cantidad']?.toString()) ?? '',
      comprado: (data['comprado'] as bool?) ?? false,
      creadoPor: data['creadoPor'] as String?,
      fechaCreacion: fecha,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'hogarId': hogarId,
      'nombre': nombre,
      'cantidad': cantidad,
      'comprado': comprado,
      if (creadoPor != null) 'creadoPor': creadoPor,
      if (fechaCreacion != null)
        'fechaCreacion': Timestamp.fromDate(fechaCreacion!),
    };
  }

  Producto copyWith({
    String? id,
    String? hogarId,
    String? nombre,
    String? cantidad,
    bool? comprado,
    String? creadoPor,
    DateTime? fechaCreacion,
  }) {
    return Producto(
      id: id ?? this.id,
      hogarId: hogarId ?? this.hogarId,
      nombre: nombre ?? this.nombre,
      cantidad: cantidad ?? this.cantidad,
      comprado: comprado ?? this.comprado,
      creadoPor: creadoPor ?? this.creadoPor,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
    );
  }
}
