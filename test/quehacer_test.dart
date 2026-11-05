import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easyhome/models/quehacer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Quehacer model', () {
    test('fromMap parsea correctamente todos los campos', () {
      final fecha = DateTime(2026, 11, 10, 15, 30);
      final map = {
        'hogarId': 'hogar123',
        'titulo': 'Lavar los platos',
        'asignadoA': 'user1',
        'hecho': true,
        'creadoPor': 'admin1',
        'fechaLimite': Timestamp.fromDate(fecha),
      };

      final quehacer = Quehacer.fromMap('q1', map);

      expect(quehacer.id, 'q1');
      expect(quehacer.hogarId, 'hogar123');
      expect(quehacer.titulo, 'Lavar los platos');
      expect(quehacer.asignadoA, 'user1');
      expect(quehacer.hecho, true);
      expect(quehacer.creadoPor, 'admin1');
      expect(quehacer.fechaLimite, fecha);
    });

    test('fromMap maneja valores por defecto si faltan campos', () {
      final quehacer = Quehacer.fromMap('q2', {});

      expect(quehacer.id, 'q2');
      expect(quehacer.hogarId, '');
      expect(quehacer.titulo, '');
      expect(quehacer.asignadoA, '');
      expect(quehacer.hecho, false);
      expect(quehacer.creadoPor, '');
      expect(quehacer.fechaLimite, isNull);
    });

    test('toMap y copyWith funcionan como se espera', () {
      final fecha = DateTime(2026, 11, 20);
      final quehacer = Quehacer(
        id: 'q3',
        hogarId: 'h1',
        titulo: 'Barrer la sala',
        asignadoA: 'u2',
        hecho: false,
        creadoPor: 'admin1',
        fechaLimite: fecha,
      );

      final map = quehacer.toMap();
      expect(map['hogarId'], 'h1');
      expect(map['titulo'], 'Barrer la sala');
      expect(map['asignadoA'], 'u2');
      expect(map['hecho'], false);
      expect(map['creadoPor'], 'admin1');
      expect(map['fechaLimite'], isA<Timestamp>());

      final actualizado = quehacer.copyWith(hecho: true, titulo: 'Barrer todo');
      expect(actualizado.hecho, true);
      expect(actualizado.titulo, 'Barrer todo');
      expect(actualizado.asignadoA, 'u2');

      final sinFecha = actualizado.copyWith(limpiarFechaLimite: true);
      expect(sinFecha.fechaLimite, isNull);
    });
  });
}
