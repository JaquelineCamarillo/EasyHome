import 'package:easyhome/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('correo', () {
    test('acepta formato válido', () {
      expect(Validators.correo('algo@algo.com'), isNull);
      expect(Validators.correo('  ana.torres+x@correo.com.mx '), isNull);
    });
    test('rechaza formatos inválidos', () {
      for (final c in ['', 'algo', 'algo@', '@algo.com', 'algo@algo', 'a b@c.com']) {
        expect(Validators.correo(c), 'Correo inválido', reason: c);
      }
    });
  });

  group('contraseña (registro)', () {
    test('mínimo 6 caracteres', () {
      expect(Validators.contrasena('12345'),
          'La contraseña debe tener al menos 6 caracteres');
      expect(Validators.contrasena('123456'), isNull);
    });
  });

  group('contraseña (login)', () {
    test('solo exige que no esté vacía', () {
      expect(Validators.contrasenaNoVacia(''), 'Ingresa tu contraseña');
      expect(Validators.contrasenaNoVacia(null), 'Ingresa tu contraseña');
      expect(Validators.contrasenaNoVacia('a'), isNull);
    });
  });

  group('confirmar contraseña', () {
    test('debe coincidir', () {
      expect(Validators.confirmarContrasena('abcdef', 'abcdef'), isNull);
      expect(Validators.confirmarContrasena('abcdeX', 'abcdef'),
          'Las contraseñas no coinciden');
    });
  });

  group('nombre del hogar', () {
    test('no acepta vacío ni solo espacios', () {
      expect(Validators.nombreHogar(''), 'Ingresa el nombre del hogar');
      expect(Validators.nombreHogar('    '), 'Ingresa el nombre del hogar');
      expect(Validators.nombreHogar(null), 'Ingresa el nombre del hogar');
    });
    test('máximo 30 caracteres', () {
      expect(Validators.nombreHogar('a' * 30), isNull);
      expect(Validators.nombreHogar('a' * 31), 'Máximo 30 caracteres');
    });
    test('acepta un nombre normal', () {
      expect(Validators.nombreHogar('Casa de los Pérez'), isNull);
    });
  });
}