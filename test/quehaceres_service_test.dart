import 'package:easyhome/services/quehaceres_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('QuehaceresService logic', () {
    test('excepción traduce mensaje correctamente', () {
      const ex = QuehaceresException('Error de prueba');
      expect(ex.toString(), 'Error de prueba');
      expect(ex.mensaje, 'Error de prueba');
    });

    test('validación de responsable en marcarHecho rechaza usuario distinto', () async {
      final service = QuehaceresService(usuarioActualId: 'user1');

      expect(
        () => service.marcarHecho(
          quehacerId: 'q1',
          asignadoA: 'user2',
          nuevoEstado: true,
        ),
        throwsA(isA<QuehaceresException>().having(
          (e) => e.mensaje,
          'mensaje',
          QuehaceresService.msgNoEsResponsable,
        )),
      );
    });

    test('validación de admin en acciones administrativas', () async {
      final service = QuehaceresService(usuarioActualId: 'user1');

      expect(
        () => service.crearQuehacer(
          hogarId: 'h1',
          titulo: 'Lavar',
          asignadoA: 'user1',
          esAdmin: false,
        ),
        throwsA(isA<QuehaceresException>().having(
          (e) => e.mensaje,
          'mensaje',
          'Solo el administrador puede crear quehaceres',
        )),
      );

      expect(
        () => service.actualizarQuehacer(
          quehacerId: 'q1',
          titulo: 'Nuevo',
          esAdmin: false,
        ),
        throwsA(isA<QuehaceresException>().having(
          (e) => e.mensaje,
          'mensaje',
          QuehaceresService.msgSinPermiso,
        )),
      );

      expect(
        () => service.eliminarQuehacer(
          quehacerId: 'q1',
          esAdmin: false,
        ),
        throwsA(isA<QuehaceresException>().having(
          (e) => e.mensaje,
          'mensaje',
          QuehaceresService.msgSinPermiso,
        )),
      );
    });
  });
}
