import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo para los comentarios de un quehacer (#Requerimiento 1 Retro).
/// Almacenado en `quehaceres/{quehacerId}/comentarios/{comentarioId}`.
class Comentario {
  const Comentario({
    required this.id,
    required this.quehacerId,
    required this.autorId,
    required this.autorNombre,
    required this.texto,
    required this.creadoEn,
  });

  final String id;
  final String quehacerId;
  final String autorId;
  final String autorNombre;
  final String texto;
  final DateTime creadoEn;

  factory Comentario.fromMap(String id, String quehacerId, Map<String, dynamic> data) {
    DateTime fecha;
    final rawFecha = data['creadoEn'];
    if (rawFecha is Timestamp) {
      fecha = rawFecha.toDate();
    } else if (rawFecha is DateTime) {
      fecha = rawFecha;
    } else {
      fecha = DateTime.now();
    }

    return Comentario(
      id: id,
      quehacerId: quehacerId,
      autorId: (data['autorId'] as String?) ?? '',
      autorNombre: (data['autorNombre'] as String?) ?? 'Integrante',
      texto: (data['texto'] as String?) ?? '',
      creadoEn: fecha,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'autorId': autorId,
      'autorNombre': autorNombre,
      'texto': texto,
      'creadoEn': Timestamp.fromDate(creadoEn),
    };
  }

  Comentario copyWith({
    String? id,
    String? quehacerId,
    String? autorId,
    String? autorNombre,
    String? texto,
    DateTime? creadoEn,
  }) {
    return Comentario(
      id: id ?? this.id,
      quehacerId: quehacerId ?? this.quehacerId,
      autorId: autorId ?? this.autorId,
      autorNombre: autorNombre ?? this.autorNombre,
      texto: texto ?? this.texto,
      creadoEn: creadoEn ?? this.creadoEn,
    );
  }
}
