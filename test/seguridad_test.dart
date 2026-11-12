import 'package:easyhome/services/auth_service.dart';
import 'package:easyhome/utils/codigo_invitacion.dart';
import 'package:easyhome/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Seguridad: Sanitización y validación de entradas (OWASP Input Validation)', () {
    test('sanitizar() elimina caracteres de control y nulos pero preserva texto válido', () {
      const entradaMaliciosa = 'Hogar Feliz\u0000\u0007\u001F  ';
      final resultado = Validators.sanitizar(entradaMaliciosa);
      expect(resultado, 'Hogar Feliz');
      expect(resultado.contains('\u0000'), isFalse);
    });

    test('rechaza nombres de usuario con longitud excesiva (>60 caracteres) para evitar DoS/UI break', () {
      final nombreLargo = 'A' * 61;
      expect(Validators.nombre(nombreLargo), 'Máximo 60 caracteres');
      expect(Validators.nombre('A' * 60), isNull);
    });

    test('rechaza títulos de quehaceres con longitud excesiva (>120 caracteres)', () {
      final quehacerGigante = 'Limpiar cocina ' * 10; // >120 caracteres
      expect(Validators.tituloQuehacer(quehacerGigante), 'Máximo 120 caracteres');
      expect(Validators.tituloQuehacer('Lavar ventanas'), isNull);
    });

    test('rechaza cantidades de productos negativas, cero, strings malformados o mayores a 99,999', () {
      expect(Validators.cantidadProducto('-5'), 'La cantidad debe ser un número entero mayor a 0');
      expect(Validators.cantidadProducto('0'), 'La cantidad debe ser un número entero mayor a 0');
      expect(Validators.cantidadProducto('3.14'), 'La cantidad debe ser un número entero mayor a 0');
      expect(Validators.cantidadProducto('diez'), 'La cantidad debe ser un número entero mayor a 0');
      expect(Validators.cantidadProducto('100000'), 'La cantidad no puede superar 99,999');
      expect(Validators.cantidadProducto('1'), isNull);
      expect(Validators.cantidadProducto('50'), isNull);
    });

    test('rechaza correos electrónicos con formato inválido o longitud desproporcionada', () {
      expect(Validators.correo('usuario@'), 'Correo inválido');
      expect(Validators.correo('usuario.com'), 'Correo inválido');
      expect(Validators.correo('<script>@test.com'), 'Correo inválido');
      expect(Validators.correo('${'a' * 115}@ejemplo.com'), 'Correo demasiado largo');
      expect(Validators.correo('usuario.seguro@dominio.com'), isNull);
    });
  });

  group('Seguridad: Fortaleza y políticas de contraseñas', () {
    test('exige mínimo 6 caracteres para registro (estándar mínimo Firebase Auth)', () {
      expect(Validators.contrasena('12345'), 'La contraseña debe tener al menos 6 caracteres');
      expect(Validators.contrasena('123456'), isNull);
    });

    test('evaluador de entropía de contraseña califica correctamente la complejidad', () {
      expect(Validators.nivelSeguridadContrasena(''), 0.0);
      // Solo 6 caracteres simples
      final scoreBasico = Validators.nivelSeguridadContrasena('abcdef');
      // Con mayúscula, número y longitud >= 8
      final scoreRobusto = Validators.nivelSeguridadContrasena('Abcdef1234');

      expect(scoreRobusto, greaterThan(scoreBasico));
      expect(scoreRobusto, greaterThanOrEqualTo(0.8));
    });

    test('confirmación de contraseñas evita discordancias', () {
      expect(Validators.confirmarContrasena('pass123', 'pass1234'), 'Las contraseñas no coinciden');
      expect(Validators.confirmarContrasena('pass123', 'pass123'), isNull);
    });
  });

  group('Seguridad: Prevención de enumeración de cuentas (Anti-Account Enumeration)', () {
    test('AuthService maneja mensajes de error homogéneos para no revelar existencia de correos', () {
      // Tanto credencial errónea como usuario no encontrado reciben el mismo mensaje genérico:
      expect(AuthService.msgCredencialesIncorrectas, 'Correo o contraseña incorrectos');
      expect(AuthService.msgDemasiadosIntentos, 'Demasiados intentos, espera un momento');
      expect(AuthService.msgRecuperacionEnviada, contains('Si el correo está registrado'));
    });
  });

  group('Seguridad: Criptografía y aleatoriedad en Códigos de Invitación', () {
    test('códigos tienen 6 caracteres alfanuméricos usando alfabeto seguro sin ambigüedad', () {
      final codigo = CodigoInvitacion.generar();
      expect(codigo.length, 6);
      expect(codigo.contains('0'), isFalse, reason: 'No debe contener cero');
      expect(codigo.contains('O'), isFalse, reason: 'No debe contener letra O');
      expect(codigo.contains('1'), isFalse, reason: 'No debe contener uno');
      expect(codigo.contains('I'), isFalse, reason: 'No debe contener letra I');
    });

    test('espacio de búsqueda de códigos supera 1,000,000,000 de combinaciones (previene fuerza bruta)', () {
      // Alfabeto de 32 caracteres elevado a la 6 = 32^6 = 1,073,741,824
      final totalCombinaciones = CodigoInvitacion.alfabeto.length *
          CodigoInvitacion.alfabeto.length *
          CodigoInvitacion.alfabeto.length *
          CodigoInvitacion.alfabeto.length *
          CodigoInvitacion.alfabeto.length *
          CodigoInvitacion.alfabeto.length;

      expect(totalCombinaciones, equals(1073741824));
    });
  });
}
