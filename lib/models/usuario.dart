/// Representación del usuario autenticado en la aplicación.
class Usuario {
  const Usuario({
    required this.uid,
    required this.nombre,
    required this.correo,
    required this.esAdministrador,
    this.hogarId,
    this.avatarColor,
  });

  final String uid;
  final String nombre;
  final String correo;
  final bool esAdministrador;
  final String? hogarId;
  final String? avatarColor;

  factory Usuario.fromMap(String uid, String correo, Map<String, dynamic> data) {
    return Usuario(
      uid: uid,
      nombre: (data['nombre'] as String?) ?? 'Sin nombre',
      correo: correo,
      esAdministrador: data['esAdministrador'] == true,
      hogarId: data['hogarId'] as String?,
      avatarColor: data['avatarColor'] as String?,
    );
  }

  Usuario copyWith({
    String? uid,
    String? nombre,
    String? correo,
    bool? esAdministrador,
    String? hogarId,
    String? avatarColor,
  }) {
    return Usuario(
      uid: uid ?? this.uid,
      nombre: nombre ?? this.nombre,
      correo: correo ?? this.correo,
      esAdministrador: esAdministrador ?? this.esAdministrador,
      hogarId: hogarId ?? this.hogarId,
      avatarColor: avatarColor ?? this.avatarColor,
    );
  }
}
