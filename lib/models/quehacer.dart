import 'package:cloud_firestore/cloud_firestore.dart';

/// Documento de `quehaceres/{quehacerId}`.
class Quehacer {
  const Quehacer({
    required this.id,
    required this.hogarId,
    required this.titulo,
    required this.asignadoA,
    this.hecho = false,
    required this.creadoPor,
    this.fechaLimite,
  });

  final String id;
  final String hogarId;
  final String titulo;
  final String asignadoA;
  final bool hecho;
  final String creadoPor;
  final DateTime? fechaLimite;

  factory Quehacer.fromMap(String id, Map<String, dynamic> data) {
    DateTime? fecha;
    final rawFecha = data['fechaLimite'];
    if (rawFecha is Timestamp) {
      fecha = rawFecha.toDate();
    } else if (rawFecha is DateTime) {
      fecha = rawFecha;
    }

    return Quehacer(
      id: id,
      hogarId: (data['hogarId'] as String?) ?? '',
      titulo: (data['titulo'] as String?) ?? '',
      asignadoA: (data['asignadoA'] as String?) ?? '',
      hecho: (data['hecho'] as bool?) ?? false,
      creadoPor: (data['creadoPor'] as String?) ?? '',
      fechaLimite: fecha,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'hogarId': hogarId,
      'titulo': titulo,
      'asignadoA': asignadoA,
      'hecho': hecho,
      'creadoPor': creadoPor,
      'fechaLimite': fechaLimite != null ? Timestamp.fromDate(fechaLimite!) : null,
    };
  }

  Quehacer copyWith({
    String? id,
    String? hogarId,
    String? titulo,
    String? asignadoA,
    bool? hecho,
    String? creadoPor,
    DateTime? fechaLimite,
    bool limpiarFechaLimite = false,
  }) {
    return Quehacer(
      id: id ?? this.id,
      hogarId: hogarId ?? this.hogarId,
      titulo: titulo ?? this.titulo,
      asignadoA: asignadoA ?? this.asignadoA,
      hecho: hecho ?? this.hecho,
      creadoPor: creadoPor ?? this.creadoPor,
      fechaLimite: limpiarFechaLimite ? null : (fechaLimite ?? this.fechaLimite),
    );
  }
}
