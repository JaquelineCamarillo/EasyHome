import 'package:easyhome/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('sanitizarTexto', () {
    test('recorta espacios en blanco', () {
      expect(Validators.sanitizarTexto('   hola mundo   '), 'hola mundo');
      expect(Validators.sanitizarTexto(null), '');
    });
  });

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

  group('contraseña (registro y política fuerte #22)', () {
    test('mínimo 8 caracteres', () {
      expect(Validators.contrasena('12345'),
          'La contraseña debe tener al menos 8 caracteres');
      expect(Validators.contrasena('Abc1234'),
          'La contraseña debe tener al menos 8 caracteres');
    });

    test('requiere al menos una letra', () {
      expect(Validators.contrasena('12345678'),
          'La contraseña debe incluir al menos una letra');
    });

    test('requiere al menos un número', () {
      expect(Validators.contrasena('abcdefgh'),
          'La contraseña debe incluir al menos un número');
    });

    test('acepta contraseña válida con 8+ caracteres, letra y número', () {
      expect(Validators.contrasena('Abcdefg1'), isNull);
      expect(Validators.contrasena('pass12345'), isNull);
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
      expect(Validators.confirmarContrasena('abcdef12', 'abcdef12'), isNull);
      expect(Validators.confirmarContrasena('abcdeX12', 'abcdef12'),
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

  group('titulo del quehacer (#17)', () {
    test('no acepta vacío ni solo espacios', () {
      expect(Validators.tituloQuehacer(''), 'Ingresa el título del quehacer');
      expect(Validators.tituloQuehacer('    '), 'Ingresa el título del quehacer');
      expect(Validators.tituloQuehacer(null), 'Ingresa el título del quehacer');
      expect(Validators.titulo(''), 'Ingresa el título del quehacer');
    });
    test('acepta título válido', () {
      expect(Validators.tituloQuehacer('Lavar los platos'), isNull);
      expect(Validators.titulo('Tirar la basura'), isNull);
    });
  });
}
