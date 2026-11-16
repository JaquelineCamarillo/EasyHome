/// Documento de `usuarios/{uid}` visto como integrante de un hogar.
class Integrante {
  const Integrante({
    required this.uid,
    required this.nombre,
    required this.esAdministrador,
    this.avatarColor,
    this.correo,
  });

  final String uid;
  final String nombre;
  final bool esAdministrador;
  final String? avatarColor;
  final String? correo;

  factory Integrante.fromMap(String uid, Map<String, dynamic> data) {
    final nombre = ((data['nombre'] as String?) ?? '').trim();
    return Integrante(
      uid: uid,
      nombre: nombre.isEmpty ? 'Sin nombre' : nombre,
      esAdministrador: data['esAdministrador'] == true,
      avatarColor: data['avatarColor'] as String?,
      correo: (data['correo'] as String?)?.trim(),
    );
  }

  /// Administradores primero; dentro de cada grupo, orden alfabético.
  static List<Integrante> ordenar(Iterable<Integrante> integrantes) {
    final lista = integrantes.toList();
    lista.sort((a, b) {
      if (a.esAdministrador != b.esAdministrador) {
        return a.esAdministrador ? -1 : 1;
      }
      return a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase());
    });
    return lista;
  }
}
