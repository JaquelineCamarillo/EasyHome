import 'dart:math';

/// Generación de códigos de invitación cortos y legibles (ej. `A3F9K2`).
class CodigoInvitacion {
  /// Sin caracteres confusos: no hay `0`/`O` ni `1`/`I`.
  static const String alfabeto = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  static const int longitud = 6;

  static String generar([Random? random]) {
    final r = random ?? Random.secure();
    return List.generate(
      longitud,
      (_) => alfabeto[r.nextInt(alfabeto.length)],
    ).join();
  }

  /// Genera códigos hasta encontrar uno que [existe] diga que está libre.
  /// Devuelve `null` si tras [maxIntentos] todos estaban ocupados.
  static Future<String?> generarUnico(
    Future<bool> Function(String codigo) existe, {
    Random? random,
    int maxIntentos = 10,
  }) async {
    for (var i = 0; i < maxIntentos; i++) {
      final codigo = generar(random);
      if (!await existe(codigo)) return codigo;
    }
    return null;
  }
}