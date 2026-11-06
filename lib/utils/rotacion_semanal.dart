/// Utilidades de lógica pura para la rotación semanal automática de quehaceres (#20).
class RotacionSemanal {
  RotacionSemanal._();

  /// Devuelve la clave de semana en formato YYYY-MM-DD correspondiente
  /// al lunes de la semana de la fecha dada (según tiempo local).
  static String claveSemana(DateTime fecha) {
    final soloFecha = DateTime(fecha.year, fecha.month, fecha.day);
    final diasHastaLunes = fecha.weekday - DateTime.monday; // 1 a 7, lunes = 1
    final lunes = soloFecha.subtract(Duration(days: diasHastaLunes));

    final a = lunes.year.toString().padLeft(4, '0');
    final m = lunes.month.toString().padLeft(2, '0');
    final d = lunes.day.toString().padLeft(2, '0');
    return '$a-$m-$d';
  }

  /// Calcula la cantidad de semanas completas transcurridas entre dos claves YYYY-MM-DD.
  /// Si la clave actual es anterior o igual a la previa, devuelve 0.
  static int semanasEntre(String claveAnterior, String claveActual) {
    try {
      final fAnt = DateTime.parse(claveAnterior);
      final fAct = DateTime.parse(claveActual);
      final diffDias = fAct.difference(fAnt).inDays;
      if (diffDias <= 0) return 0;
      final semanas = (diffDias / 7).round();
      return semanas > 0 ? semanas : 0;
    } catch (_) {
      return 0;
    }
  }

  /// Reconcilia la lista de orden de rotación almacenada con la lista actual
  /// de integrantes del hogar:
  /// - Elimina uids de integrantes que ya no pertenecen al hogar.
  /// - Agrega al final los uids de nuevos integrantes que se unieron.
  /// - Si la lista almacenada está vacía, ordena los integrantes alfabéticamente
  ///   para garantizar un orden inicial determinista.
  static List<String> reconciliarOrden(
    List<String> ordenGuardado,
    List<String> integrantesUids,
  ) {
    final setIntegrantes = integrantesUids.toSet();

    if (ordenGuardado.isEmpty) {
      final inicial = List<String>.from(integrantesUids)..sort();
      return inicial;
    }

    // Conservar orden de los que siguen perteneciendo
    final resultado = <String>[];
    for (final uid in ordenGuardado) {
      if (setIntegrantes.contains(uid) && !resultado.contains(uid)) {
        resultado.add(uid);
      }
    }

    // Agregar nuevos integrantes al final
    for (final uid in integrantesUids) {
      if (!resultado.contains(uid)) {
        resultado.add(uid);
      }
    }

    return resultado;
  }

  /// Calcula el nuevo responsable para una tarea recurrente desplazando
  /// [semanas] posiciones cíclicamente a partir de [actual].
  static String? siguienteResponsable({
    required List<String> orden,
    required String? actual,
    required int semanas,
  }) {
    if (orden.isEmpty) return null;
    if (orden.length == 1) return orden.first;

    final saltos = semanas <= 0 ? 1 : semanas;
    final idxActual = actual != null ? orden.indexOf(actual) : -1;

    final baseIdx = idxActual >= 0 ? idxActual : 0;
    final nuevoIdx = (baseIdx + saltos) % orden.length;
    return orden[nuevoIdx];
  }
}
