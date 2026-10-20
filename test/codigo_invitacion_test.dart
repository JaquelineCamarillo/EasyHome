import 'dart:math';

import 'package:easyhome/utils/codigo_invitacion.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('el alfabeto no tiene caracteres confusos', () {
    for (final c in ['0', 'O', '1', 'I']) {
      expect(CodigoInvitacion.alfabeto.contains(c), isFalse, reason: c);
    }
  });

  test('genera 6 caracteres alfanuméricos en mayúscula del alfabeto', () {
    final random = Random(42);
    for (var i = 0; i < 500; i++) {
      final codigo = CodigoInvitacion.generar(random);
      expect(codigo.length, 6);
      expect(RegExp(r'^[A-HJ-NP-Z2-9]{6}$').hasMatch(codigo), isTrue,
          reason: codigo);
    }
  });

  test('generarUnico reintenta si el código ya existe', () async {
    final consultados = <String>[];
    final codigo = await CodigoInvitacion.generarUnico(
      (c) async {
        consultados.add(c);
        return consultados.length < 3; // los 2 primeros "ya existen"
      },
      random: Random(1),
    );

    expect(consultados.length, 3);
    expect(codigo, consultados.last);
  });

  test('generarUnico devuelve null si todos los intentos chocan', () async {
    var llamadas = 0;
    final codigo = await CodigoInvitacion.generarUnico(
      (_) async {
        llamadas++;
        return true;
      },
      maxIntentos: 4,
    );

    expect(codigo, isNull);
    expect(llamadas, 4);
  });
}