/// Documento de `hogares/{hogarId}`.
class Hogar {
  const Hogar({
    required this.id,
    required this.nombre,
    required this.codigoInvitacion,
  });

  final String id;
  final String nombre;
  final String codigoInvitacion;

  factory Hogar.fromMap(String id, Map<String, dynamic> data) {
    return Hogar(
      id: id,
      nombre: (data['nombre'] as String?) ?? '',
      codigoInvitacion: (data['codigoInvitacion'] as String?) ?? '',
    );
  }
}