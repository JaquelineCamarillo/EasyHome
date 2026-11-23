import 'package:cloud_firestore/cloud_firestore.dart';

/// Niveles de prioridad de un quehacer o tarea.
class PrioridadQuehacer {
  static const String alta = 'alta';
  static const String media = 'media';
  static const String baja = 'baja';

  static const Map<String, String> etiquetas = {
    alta: 'Alta',
    media: 'Media',
    baja: 'Baja',
  };

  static int peso(String prioridad) {
    switch (prioridad) {
      case alta:
        return 3;
      case media:
        return 2;
      case baja:
        return 1;
      default:
        return 2;
    }
  }
}

/// Categorías o áreas aplicables a hogares y diferentes tipos de equipos.
class CategoriaQuehacer {
  static const String general = 'general';
  static const String limpieza = 'limpieza';
  static const String cocina = 'cocina';
  static const String mantenimiento = 'mantenimiento';
  static const String gestion = 'gestion';
  static const String compras = 'compras';

  static const Map<String, String> etiquetas = {
    general: 'General / Actividades',
    limpieza: 'Limpieza y Orden',
    cocina: 'Cocina / Comedor',
    mantenimiento: 'Mantenimiento / Soporte',
    gestion: 'Gestión / Proyecto',
    compras: 'Suministros / Compras',
  };

  static String etiquetaDe(String? cat) =>
      etiquetas[cat] ?? etiquetas[general]!;
}

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
    this.recurrente = false,
    this.descripcion,
    this.prioridad = PrioridadQuehacer.media,
    this.categoria = CategoriaQuehacer.general,
  });

  final String id;
  final String hogarId;
  final String titulo;
  final String asignadoA;
  final bool hecho;
  final String creadoPor;
  final DateTime? fechaLimite;
  final bool recurrente;
  final String? descripcion;
  final String prioridad;
  final String categoria;

  factory Quehacer.fromMap(String id, Map<String, dynamic> data) {
    DateTime? fecha;
    final rawFecha = data['fechaLimite'];
    if (rawFecha is Timestamp) {
      fecha = rawFecha.toDate();
    } else if (rawFecha is DateTime) {
      fecha = rawFecha;
    }

    final rawDesc = (data['descripcion'] as String?)?.trim();
    final desc = (rawDesc != null && rawDesc.isNotEmpty) ? rawDesc : null;

    final rawPrio = (data['prioridad'] as String?)?.trim();
    final prio = (rawPrio != null &&
            PrioridadQuehacer.etiquetas.containsKey(rawPrio))
        ? rawPrio
        : PrioridadQuehacer.media;

    final rawCat = (data['categoria'] as String?)?.trim();
    final cat = (rawCat != null &&
            CategoriaQuehacer.etiquetas.containsKey(rawCat))
        ? rawCat
        : CategoriaQuehacer.general;

    return Quehacer(
      id: id,
      hogarId: (data['hogarId'] as String?) ?? '',
      titulo: (data['titulo'] as String?) ?? '',
      asignadoA: (data['asignadoA'] as String?) ?? '',
      hecho: (data['hecho'] as bool?) ?? false,
      creadoPor: (data['creadoPor'] as String?) ?? '',
      fechaLimite: fecha,
      recurrente: (data['recurrente'] as bool?) ?? false,
      descripcion: desc,
      prioridad: prio,
      categoria: cat,
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
      'recurrente': recurrente,
      if (descripcion != null && descripcion!.trim().isNotEmpty)
        'descripcion': descripcion!.trim(),
      'prioridad': prioridad,
      'categoria': categoria,
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
    bool? recurrente,
    String? descripcion,
    bool limpiarDescripcion = false,
    String? prioridad,
    String? categoria,
  }) {
    return Quehacer(
      id: id ?? this.id,
      hogarId: hogarId ?? this.hogarId,
      titulo: titulo ?? this.titulo,
      asignadoA: asignadoA ?? this.asignadoA,
      hecho: hecho ?? this.hecho,
      creadoPor: creadoPor ?? this.creadoPor,
      fechaLimite: limpiarFechaLimite ? null : (fechaLimite ?? this.fechaLimite),
      recurrente: recurrente ?? this.recurrente,
      descripcion: limpiarDescripcion ? null : (descripcion ?? this.descripcion),
      prioridad: prioridad ?? this.prioridad,
      categoria: categoria ?? this.categoria,
    );
  }
}
