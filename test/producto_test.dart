import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easyhome/models/producto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Producto model', () {
    test('fromMap parsea correctamente todos los campos', () {
      final ahora = DateTime(2026, 10, 21, 12, 0);
      final data = {
        'hogarId': 'hogar123',
        'nombre': 'Leche entera',
        'cantidad': '2 litros',
        'comprado': true,
        'creadoPor': 'user456',
        'fechaCreacion': Timestamp.fromDate(ahora),
      };

      final producto = Producto.fromMap('prod1', data);

      expect(producto.id, 'prod1');
      expect(producto.hogarId, 'hogar123');
      expect(producto.nombre, 'Leche entera');
      expect(producto.cantidad, '2 litros');
      expect(producto.comprado, isTrue);
      expect(producto.creadoPor, 'user456');
      expect(producto.fechaCreacion, ahora);
    });

    test('fromMap maneja valores por defecto si faltan campos opcionales', () {
      final data = <String, dynamic>{};
      final producto = Producto.fromMap('prod2', data);

      expect(producto.id, 'prod2');
      expect(producto.hogarId, '');
      expect(producto.nombre, '');
      expect(producto.cantidad, '');
      expect(producto.comprado, isFalse);
      expect(producto.creadoPor, isNull);
      expect(producto.fechaCreacion, isNull);
    });

    test('toMap y copyWith funcionan como se espera', () {
      final ahora = DateTime(2026, 10, 21, 10, 0);
      final prod = Producto(
        id: 'p1',
        hogarId: 'h1',
        nombre: 'Huevos',
        cantidad: '1 docena',
        comprado: false,
        fechaCreacion: ahora,
      );

      final map = prod.toMap();
      expect(map['nombre'], 'Huevos');
      expect(map['cantidad'], '1 docena');
      expect(map['comprado'], isFalse);

      final modificado = prod.copyWith(comprado: true);
      expect(modificado.comprado, isTrue);
      expect(modificado.nombre, 'Huevos');
    });
  });
}
