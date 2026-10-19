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

  group('contraseña', () {
    test('mínimo 6 caracteres', () {
      expect(Validators.contrasena('12345'),
          'La contraseña debe tener al menos 6 caracteres');
      expect(Validators.contrasena('123456'), isNull);
    });
  });

  group('confirmar contraseña', () {
    test('debe coincidir', () {
      expect(Validators.confirmarContrasena('abcdef', 'abcdef'), isNull);
      expect(Validators.confirmarContrasena('abcdeX', 'abcdef'),
          'Las contraseñas no coinciden');
    });
  });
}