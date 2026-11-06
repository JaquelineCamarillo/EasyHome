import 'package:flutter_test/flutter_test.dart';
import 'package:easyhome/utils/rotacion_semanal.dart';

void main() {
  group('RotacionSemanal - claveSemana', () {
    test('un lunes devuelve su propia fecha en formato YYYY-MM-DD', () {
      final lunes = DateTime(2026, 11, 2); // 2026-11-02 fue lunes
      expect(lunes.weekday, DateTime.monday);
      expect(RotacionSemanal.claveSemana(lunes), '2026-11-02');
    });

    test('un domingo devuelve el lunes de esa misma semana', () {
      final domingo = DateTime(2026, 11, 8); // 2026-11-08 domingo
      expect(domingo.weekday, DateTime.sunday);
      expect(RotacionSemanal.claveSemana(domingo), '2026-11-02');
    });

    test('un miércoles a mitad de semana devuelve el lunes correspondiente', () {
      final miercoles = DateTime(2026, 11, 4, 18, 30);
      expect(miercoles.weekday, DateTime.wednesday);
      expect(RotacionSemanal.claveSemana(miercoles), '2026-11-02');
    });

    test('cambio de año: domingo 3 de enero de 2027 da el lunes 28 de diciembre de 2026', () {
      final domingoFin = DateTime(2027, 1, 3);
      expect(domingoFin.weekday, DateTime.sunday);
      expect(RotacionSemanal.claveSemana(domingoFin), '2026-12-28');
    });

    test('cambio de año: lunes 4 de enero de 2027 da 2027-01-04', () {
      final lunesInicio = DateTime(2027, 1, 4);
      expect(lunesInicio.weekday, DateTime.monday);
      expect(RotacionSemanal.claveSemana(lunesInicio), '2027-01-04');
    });
  });

  group('RotacionSemanal - semanasEntre', () {
    test('misma clave da 0 semanas', () {
      expect(RotacionSemanal.semanasEntre('2026-11-02', '2026-11-02'), 0);
    });

    test('1 semana de diferencia da 1', () {
      expect(RotacionSemanal.semanasEntre('2026-11-02', '2026-11-09'), 1);
    });

    test('3 semanas de diferencia da 3', () {
      expect(RotacionSemanal.semanasEntre('2026-11-02', '2026-11-23'), 3);
    });

    test('clave actual anterior da 0', () {
      expect(RotacionSemanal.semanasEntre('2026-11-09', '2026-11-02'), 0);
    });

    test('clave inválida no lanza excepción y devuelve 0', () {
      expect(RotacionSemanal.semanasEntre('invalida', '2026-11-09'), 0);
    });
  });

  group('RotacionSemanal - reconciliarOrden', () {
    test('si ordenGuardado está vacío, genera orden determinista alfabético', () {
      final integrantes = ['uid_carlos', 'uid_ana', 'uid_beto'];
      final res = RotacionSemanal.reconciliarOrden([], integrantes);
      expect(res, ['uid_ana', 'uid_beto', 'uid_carlos']);
    });

    test('elimina integrante que salió del hogar conservando orden de los demás', () {
      final orden = ['uid_ana', 'uid_beto', 'uid_carlos'];
      final integrantesActuales = ['uid_ana', 'uid_carlos']; // beto se fue
      final res = RotacionSemanal.reconciliarOrden(orden, integrantesActuales);
      expect(res, ['uid_ana', 'uid_carlos']);
    });

    test('agrega integrante nuevo al final de la lista de rotación', () {
      final orden = ['uid_ana', 'uid_beto'];
      final integrantesActuales = ['uid_ana', 'uid_beto', 'uid_diana'];
      final res = RotacionSemanal.reconciliarOrden(orden, integrantesActuales);
      expect(res, ['uid_ana', 'uid_beto', 'uid_diana']);
    });
  });

  group('RotacionSemanal - siguienteResponsable (al menos 3 ciclos)', () {
    final orden = ['uid_ana', 'uid_beto', 'uid_carlos'];

    test('Ciclo 1: 1 semana desplaza cada tarea al siguiente integrante (sin saltar a nadie)', () {
      expect(
        RotacionSemanal.siguienteResponsable(orden: orden, actual: 'uid_ana', semanas: 1),
        'uid_beto',
      );
      expect(
        RotacionSemanal.siguienteResponsable(orden: orden, actual: 'uid_beto', semanas: 1),
        'uid_carlos',
      );
      expect(
        RotacionSemanal.siguienteResponsable(orden: orden, actual: 'uid_carlos', semanas: 1),
        'uid_ana',
      );
    });

    test('Ciclo 2: acumula otro desplazamiento de 1 semana', () {
      expect(
        RotacionSemanal.siguienteResponsable(orden: orden, actual: 'uid_beto', semanas: 1),
        'uid_carlos',
      );
      expect(
        RotacionSemanal.siguienteResponsable(orden: orden, actual: 'uid_carlos', semanas: 1),
        'uid_ana',
      );
      expect(
        RotacionSemanal.siguienteResponsable(orden: orden, actual: 'uid_ana', semanas: 1),
        'uid_beto',
      );
    });

    test('Ciclo 3: tercer ciclo completa la rotación circular completa y regresa al inicio', () {
      expect(
        RotacionSemanal.siguienteResponsable(orden: orden, actual: 'uid_carlos', semanas: 1),
        'uid_ana',
      );
      expect(
        RotacionSemanal.siguienteResponsable(orden: orden, actual: 'uid_ana', semanas: 1),
        'uid_beto',
      );
      expect(
        RotacionSemanal.siguienteResponsable(orden: orden, actual: 'uid_beto', semanas: 1),
        'uid_carlos',
      );
    });

    test('Semana inactiva: saltar 2 semanas avanza 2 posiciones modularmente', () {
      expect(
        RotacionSemanal.siguienteResponsable(orden: orden, actual: 'uid_ana', semanas: 2),
        'uid_carlos',
      );
      expect(
        RotacionSemanal.siguienteResponsable(orden: orden, actual: 'uid_beto', semanas: 2),
        'uid_ana',
      );
    });

    test('Si el responsable actual ya no está en la lista, toma el base y rota', () {
      expect(
        RotacionSemanal.siguienteResponsable(orden: orden, actual: 'uid_inexistente', semanas: 1),
        'uid_beto', // idx base 0 + 1 = 1 ('uid_beto')
      );
    });

    test('Hogar con un solo integrante se mantiene asignado a él', () {
      expect(
        RotacionSemanal.siguienteResponsable(orden: ['uid_solo'], actual: 'uid_solo', semanas: 1),
        'uid_solo',
      );
    });

    test('Orden vacío devuelve null sin lanzar excepción', () {
      expect(
        RotacionSemanal.siguienteResponsable(orden: [], actual: 'uid_ana', semanas: 1),
        isNull,
      );
    });
  });

  group('RotacionSemanal - Simulación de flujo por lotes (3 ciclos con 3 integrantes)', () {
    test('Simula 3 ciclos semanales completos, reseteo de hecho y persistencia de no recurrentes', () {
      final orden = ['uid_ana', 'uid_beto', 'uid_carlos'];

      // Estado inicial (Línea base: Semana 2026-11-02)
      var tareaRecurrente1 = {'id': 'q1', 'asignadoA': 'uid_ana', 'hecho': true, 'recurrente': true};
      var tareaRecurrente2 = {'id': 'q2', 'asignadoA': 'uid_beto', 'hecho': true, 'recurrente': true};
      var tareaNoRecurrente = {'id': 'q3', 'asignadoA': 'uid_ana', 'hecho': true, 'recurrente': false};

      void aplicarRotacion({required int semanas}) {
        if (tareaRecurrente1['recurrente'] == true) {
          tareaRecurrente1['asignadoA'] = RotacionSemanal.siguienteResponsable(
            orden: orden,
            actual: tareaRecurrente1['asignadoA'] as String?,
            semanas: semanas,
          )!;
          tareaRecurrente1['hecho'] = false;
        }

        if (tareaRecurrente2['recurrente'] == true) {
          tareaRecurrente2['asignadoA'] = RotacionSemanal.siguienteResponsable(
            orden: orden,
            actual: tareaRecurrente2['asignadoA'] as String?,
            semanas: semanas,
          )!;
          tareaRecurrente2['hecho'] = false;
        }
        // tareaNoRecurrente NO se modifica
      }

      // Ciclo 1 (Semana 2026-11-09, delta = 1)
      aplicarRotacion(semanas: 1);
      expect(tareaRecurrente1['asignadoA'], 'uid_beto');
      expect(tareaRecurrente1['hecho'], isFalse);
      expect(tareaRecurrente2['asignadoA'], 'uid_carlos');
      expect(tareaRecurrente2['hecho'], isFalse);
      // No recurrente permanece intacta
      expect(tareaNoRecurrente['asignadoA'], 'uid_ana');
      expect(tareaNoRecurrente['hecho'], isTrue);

      // Ana y Beto completan sus tareas durante la semana
      tareaRecurrente1['hecho'] = true;
      tareaRecurrente2['hecho'] = true;

      // Ciclo 2 (Semana 2026-11-16, delta = 1)
      aplicarRotacion(semanas: 1);
      expect(tareaRecurrente1['asignadoA'], 'uid_carlos');
      expect(tareaRecurrente1['hecho'], isFalse);
      expect(tareaRecurrente2['asignadoA'], 'uid_ana');
      expect(tareaRecurrente2['hecho'], isFalse);
      expect(tareaNoRecurrente['asignadoA'], 'uid_ana');
      expect(tareaNoRecurrente['hecho'], isTrue);

      // Ciclo 3 (Semana 2026-11-23, delta = 1)
      aplicarRotacion(semanas: 1);
      expect(tareaRecurrente1['asignadoA'], 'uid_ana');
      expect(tareaRecurrente1['hecho'], isFalse);
      expect(tareaRecurrente2['asignadoA'], 'uid_beto');
      expect(tareaRecurrente2['hecho'], isFalse);
      expect(tareaNoRecurrente['asignadoA'], 'uid_ana');
      expect(tareaNoRecurrente['hecho'], isTrue);

      // Se verificó la rotación circular completa: Ana -> Beto -> Carlos -> Ana sin saltos
    });
  });
}
