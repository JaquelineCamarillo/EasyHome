import 'package:easyhome/models/hogar.dart';
import 'package:easyhome/models/integrante.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Integrante.fromMap lee los campos y tolera datos faltantes', () {
    final a = Integrante.fromMap('u1', {'nombre': 'Ana', 'esAdministrador': true});
    expect(a.uid, 'u1');
    expect(a.nombre, 'Ana');
    expect(a.esAdministrador, isTrue);

    final b = Integrante.fromMap('u2', {});
    expect(b.nombre, 'Sin nombre');
    expect(b.esAdministrador, isFalse);
  });

  test('ordenar pone a los administradores primero y luego alfabético', () {
    final lista = Integrante.ordenar([
      const Integrante(uid: '1', nombre: 'sofía', esAdministrador: false),
      const Integrante(uid: '2', nombre: 'Marco', esAdministrador: false),
      const Integrante(uid: '3', nombre: 'Zoe', esAdministrador: true),
      const Integrante(uid: '4', nombre: 'Ana', esAdministrador: false),
    ]);

    expect(lista.map((i) => i.nombre).toList(), ['Zoe', 'Ana', 'Marco', 'sofía']);
  });

  test('Hogar.fromMap lee nombre y código', () {
    final h = Hogar.fromMap('h1', {'nombre': 'Depa de Ana', 'codigoInvitacion': 'A3F9K2'});
    expect(h.id, 'h1');
    expect(h.nombre, 'Depa de Ana');
    expect(h.codigoInvitacion, 'A3F9K2');
  });
}