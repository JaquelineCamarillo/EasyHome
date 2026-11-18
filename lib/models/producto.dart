import 'package:cloud_firestore/cloud_firestore.dart';

/// Documento de `productos/{productoId}`.
class Producto {
  const Producto({
    required this.id,
    required this.hogarId,
    required this.nombre,
    required this.cantidad,
    this.comprado = false,
    this.agregadoPor,
    this.fechaCreacion,
    this.costo,
  });

  final String id;
  final String hogarId;
  final String nombre;
  final int cantidad;
  final bool comprado;
  final String? agregadoPor;
  final DateTime? fechaCreacion;

  /// Costo opcional del producto (#Requerimiento 2 Retro).
  final double? costo;

  /// Compatibilidad hacia atrás si algún componente busca `creadoPor`.
  String? get creadoPor => agregadoPor;

  factory Producto.fromMap(String id, Map<String, dynamic> data) {
    DateTime? fecha;
    final rawFecha = data['fechaCreacion'];
    if (rawFecha is Timestamp) {
      fecha = rawFecha.toDate();
    } else if (rawFecha is DateTime) {
      fecha = rawFecha;
    }

    int cant = 1;
    final rawCant = data['cantidad'];
    if (rawCant is int) {
      cant = rawCant;
    } else if (rawCant is num) {
      cant = rawCant.toInt();
    } else if (rawCant is String) {
      cant = int.tryParse(rawCant) ?? 1;
    }

    double? c;
    final rawCosto = data['costo'];
    if (rawCosto is num) {
      c = rawCosto.toDouble();
    } else if (rawCosto is String) {
      c = double.tryParse(rawCosto);
    }

    return Producto(
      id: id,
      hogarId: (data['hogarId'] as String?) ?? '',
      nombre: (data['nombre'] as String?) ?? '',
      cantidad: cant,
      comprado: (data['comprado'] as bool?) ?? false,
      agregadoPor: (data['agregadoPor'] as String?) ?? (data['creadoPor'] as String?),
      fechaCreacion: fecha,
      costo: c,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'hogarId': hogarId,
      'nombre': nombre,
      'cantidad': cantidad,
      'comprado': comprado,
      if (agregadoPor != null) 'agregadoPor': agregadoPor,
      if (fechaCreacion != null)
        'fechaCreacion': Timestamp.fromDate(fechaCreacion!),
      if (costo != null) 'costo': costo,
    };
  }

  Producto copyWith({
    String? id,
    String? hogarId,
    String? nombre,
    int? cantidad,
    bool? comprado,
    String? agregadoPor,
    DateTime? fechaCreacion,
    double? costo,
    bool limpiarCosto = false,
  }) {
    return Producto(
      id: id ?? this.id,
      hogarId: hogarId ?? this.hogarId,
      nombre: nombre ?? this.nombre,
      cantidad: cantidad ?? this.cantidad,
      comprado: comprado ?? this.comprado,
      agregadoPor: agregadoPor ?? this.agregadoPor,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      costo: limpiarCosto ? null : (costo ?? this.costo),
    );
  }
}
