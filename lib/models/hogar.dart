/// Tipos de espacio o equipo en los que se puede implementar la aplicación.
class TipoEspacio {
  static const String hogar = 'hogar';
  static const String roommates = 'roommates';
  static const String equipo = 'equipo';
  static const String oficina = 'oficina';
  static const String evento = 'evento';

  static const Map<String, String> etiquetas = {
    hogar: 'Familiar / Residencial',
    roommates: 'Roommates / Departamento',
    equipo: 'Equipo / Proyecto',
    oficina: 'Oficina / Trabajo',
    evento: 'Viaje / Evento',
  };

  static String etiquetaDe(String? tipo) =>
      etiquetas[tipo] ?? etiquetas[hogar]!;
}

/// Documento de `hogares/{hogarId}`.
class Hogar {
  const Hogar({
    required this.id,
    required this.nombre,
    required this.codigoInvitacion,
    this.creadoPor,
    this.tipoEspacio = TipoEspacio.hogar,
  });

  final String id;
  final String nombre;
  final String codigoInvitacion;
  final String? creadoPor;
  final String tipoEspacio;

  factory Hogar.fromMap(String id, Map<String, dynamic> data) {
    final rawTipo = (data['tipoEspacio'] as String?)?.trim();
    return Hogar(
      id: id,
      nombre: (data['nombre'] as String?) ?? '',
      codigoInvitacion: (data['codigoInvitacion'] as String?) ?? '',
      creadoPor: data['creadoPor'] as String?,
      tipoEspacio: (rawTipo != null && rawTipo.isNotEmpty)
          ? rawTipo
          : TipoEspacio.hogar,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'codigoInvitacion': codigoInvitacion,
      if (creadoPor != null) 'creadoPor': creadoPor,
      'tipoEspacio': tipoEspacio,
    };
  }
}