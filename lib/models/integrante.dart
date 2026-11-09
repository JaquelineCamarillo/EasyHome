/// Documento de `usuarios/{uid}` visto como integrante de un hogar.
class Integrante {
  const Integrante({
    required this.uid,
    required this.nombre,
    required this.esAdministrador,
    this.avatarColor,
  });

  final String uid;
  final String nombre;
  final bool esAdministrador;
  final String? avatarColor;

  factory Integrante.fromMap(String uid, Map<String, dynamic> data) {
    final nombre = ((data['nombre'] as String?) ?? '').trim();
    return Integrante(
      uid: uid,
      nombre: nombre.isEmpty ? 'Sin nombre' : nombre,
      esAdministrador: data['esAdministrador'] == true,
      avatarColor: data['avatarColor'] as String?,
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
