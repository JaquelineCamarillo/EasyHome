/// Representación del usuario autenticado en la aplicación.
class Usuario {
  const Usuario({
    required this.uid,
    required this.nombre,
    required this.correo,
    required this.esAdministrador,
    this.hogarId,
    this.hogaresIds = const [],
    this.avatarColor,
  });

  final String uid;
  final String nombre;
  final String correo;
  final bool esAdministrador;
  final String? hogarId;
  final List<String> hogaresIds;
  final String? avatarColor;

  /// Lista consolidada de hogares a los que pertenece (incluye `hogarId` activo).
  List<String> get todosLosHogares {
    final set = <String>{...hogaresIds};
    if (hogarId != null && hogarId!.isNotEmpty) {
      set.add(hogarId!);
    }
    return set.toList();
  }

  factory Usuario.fromMap(String uid, String correo, Map<String, dynamic> data) {
    final rawHogares = data['hogaresIds'];
    final List<String> listaHogares = rawHogares is List
        ? rawHogares.map((e) => e.toString()).where((e) => e.isNotEmpty).toList()
        : <String>[];
    final hid = data['hogarId'] as String?;
    if (hid != null && hid.isNotEmpty && !listaHogares.contains(hid)) {
      listaHogares.add(hid);
    }

    return Usuario(
      uid: uid,
      nombre: (data['nombre'] as String?) ?? 'Sin nombre',
      correo: correo,
      esAdministrador: data['esAdministrador'] == true,
      hogarId: hid,
      hogaresIds: listaHogares,
      avatarColor: data['avatarColor'] as String?,
    );
  }

  Usuario copyWith({
    String? uid,
    String? nombre,
    String? correo,
    bool? esAdministrador,
    String? hogarId,
    List<String>? hogaresIds,
    String? avatarColor,
  }) {
    return Usuario(
      uid: uid ?? this.uid,
      nombre: nombre ?? this.nombre,
      correo: correo ?? this.correo,
      esAdministrador: esAdministrador ?? this.esAdministrador,
      hogarId: hogarId ?? this.hogarId,
      hogaresIds: hogaresIds ?? this.hogaresIds,
      avatarColor: avatarColor ?? this.avatarColor,
    );
  }
}
