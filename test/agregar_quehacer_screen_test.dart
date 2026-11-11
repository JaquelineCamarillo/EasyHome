import 'package:easyhome/models/integrante.dart';
import 'package:easyhome/screens/agregar_quehacer_screen.dart';
import 'package:easyhome/services/hogar_service.dart';
import 'package:easyhome/services/quehaceres_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeQuehaceresServiceAgregar extends QuehaceresService {
  String? ultimoHogarId;
  String? ultimoTitulo;
  String? ultimoAsignadoA;
  DateTime? ultimaFechaLimite;
  bool? ultimoEsAdmin;
  bool? ultimoRecurrente;
  bool simularResponsableDeOtroHogar = false;

  @override
  Future<String> crearQuehacer({
    required String hogarId,
    required String titulo,
    required String asignadoA,
    DateTime? fechaLimite,
    bool esAdmin = true,
    bool recurrente = false,
  }) async {
    if (!esAdmin) {
      throw const QuehaceresException('Solo el administrador puede crear quehaceres');
    }
    if (simularResponsableDeOtroHogar || asignadoA == 'usuario_otro_hogar') {
      throw const QuehaceresException(QuehaceresService.msgResponsableInvalido);
    }

    ultimoHogarId = hogarId;
    ultimoTitulo = titulo;
    ultimoAsignadoA = asignadoA;
    ultimaFechaLimite = fechaLimite;
    ultimoEsAdmin = esAdmin;
    ultimoRecurrente = recurrente;
    return 'q_nuevo_123';
  }
}

class FakeHogarServiceAgregar extends HogarService {
  @override
  Future<String?> obtenerHogarIdActual() async => 'hogar_123';
}

final _integrantesPrueba = [
  const Integrante(uid: 'u_admin', nombre: 'Jaqueline Admin', esAdministrador: true),
  const Integrante(uid: 'u_miembro', nombre: 'Carlos Miembro', esAdministrador: false),
];

Future<void> _montar(
  WidgetTester tester, {
  required FakeQuehaceresServiceAgregar fakeQuehaceres,
  required FakeHogarServiceAgregar fakeHogares,
  bool esAdmin = true,
  List<Integrante>? integrantes,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: AgregarQuehacerScreen(
        hogarId: 'hogar_123',
        quehaceresService: fakeQuehaceres,
        hogarService: fakeHogares,
        esAdministrador: esAdmin,
        integrantesIniciales: integrantes ?? _integrantesPrueba,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('AgregarQuehacerScreen Tests (#17 y #20)', () {
    late FakeQuehaceresServiceAgregar fakeQuehaceres;
    late FakeHogarServiceAgregar fakeHogares;

    setUp(() {
      fakeQuehaceres = FakeQuehaceresServiceAgregar();
      fakeHogares = FakeHogarServiceAgregar();
    });

    testWidgets('usuario no administrador ve mensaje de restricción exacto y no el formulario',
        (tester) async {
      await _montar(
        tester,
        fakeQuehaceres: fakeQuehaceres,
        fakeHogares: fakeHogares,
        esAdmin: false,
      );

      expect(find.text('Solo el administrador puede crear quehaceres'), findsOneWidget);
      expect(find.byKey(const Key('mensaje_no_admin')), findsOneWidget);
      expect(find.byKey(const Key('campo_titulo_quehacer')), findsNothing);
      expect(find.byKey(const Key('boton_crear_quehacer')), findsNothing);
    });

    testWidgets('validación: título vacío o solo espacios muestra error y no envía',
        (tester) async {
      await _montar(
        tester,
        fakeQuehaceres: fakeQuehaceres,
        fakeHogares: fakeHogares,
        esAdmin: true,
      );

      final campoTitulo = find.byKey(const Key('campo_titulo_quehacer'));
      final botonCrear = find.byKey(const Key('boton_crear_quehacer'));

      // Vacío
      await tester.enterText(campoTitulo, '');
      await tester.tap(botonCrear);
      await tester.pumpAndSettle();

      expect(find.text('Ingresa el título del quehacer'), findsOneWidget);
      expect(fakeQuehaceres.ultimoTitulo, isNull);

      // Solo espacios
      await tester.enterText(campoTitulo, '     ');
      await tester.tap(botonCrear);
      await tester.pumpAndSettle();

      expect(find.text('Ingresa el título del quehacer'), findsOneWidget);
      expect(fakeQuehaceres.ultimoTitulo, isNull);
    });

    testWidgets('creación exitosa con fecha opcional nula llama al servicio correctamente',
        (tester) async {
      await _montar(
        tester,
        fakeQuehaceres: fakeQuehaceres,
        fakeHogares: fakeHogares,
        esAdmin: true,
      );

      final campoTitulo = find.byKey(const Key('campo_titulo_quehacer'));
      final botonCrear = find.byKey(const Key('boton_crear_quehacer'));

      await tester.enterText(campoTitulo, '  Lavar las ventanas del frente  ');
      await tester.tap(botonCrear);
      await tester.pumpAndSettle();

      expect(fakeQuehaceres.ultimoTitulo, 'Lavar las ventanas del frente');
      expect(fakeQuehaceres.ultimoHogarId, 'hogar_123');
      expect(fakeQuehaceres.ultimoAsignadoA, 'u_admin');
      expect(fakeQuehaceres.ultimaFechaLimite, isNull);
      expect(fakeQuehaceres.ultimoEsAdmin, isTrue);
      expect(fakeQuehaceres.ultimoRecurrente, isFalse);
    });

    testWidgets('switch recurrente (#20) activa repetición semanal y lo envía al servicio',
        (tester) async {
      await _montar(
        tester,
        fakeQuehaceres: fakeQuehaceres,
        fakeHogares: fakeHogares,
        esAdmin: true,
      );

      final campoTitulo = find.byKey(const Key('campo_titulo_quehacer'));
      final switchRecurrente = find.byKey(const Key('switch_recurrente'));
      final botonCrear = find.byKey(const Key('boton_crear_quehacer'));

      expect(switchRecurrente, findsOneWidget);

      await tester.enterText(campoTitulo, 'Lavar platos');
      await tester.tap(switchRecurrente);
      await tester.pumpAndSettle();

      await tester.tap(botonCrear);
      await tester.pumpAndSettle();

      expect(fakeQuehaceres.ultimoTitulo, 'Lavar platos');
      expect(fakeQuehaceres.ultimoRecurrente, isTrue);
    });

    testWidgets('selector de fecha permite elegir y quitar fecha opcional',
        (tester) async {
      await _montar(
        tester,
        fakeQuehaceres: fakeQuehaceres,
        fakeHogares: fakeHogares,
        esAdmin: true,
      );

      expect(find.text('Fecha límite opcional'), findsOneWidget);
      expect(find.byKey(const Key('boton_quitar_fecha')), findsNothing);

      // Abrir selector de fecha
      await tester.tap(find.byKey(const Key('boton_seleccionar_fecha')));
      await tester.pumpAndSettle();

      // Confirmar en datepicker (por defecto 'OK')
      final botonOk = find.text('OK');
      if (botonOk.evaluate().isNotEmpty) {
        await tester.tap(botonOk);
      } else {
        await tester.tap(find.text('Aceptar'));
      }
      await tester.pumpAndSettle();

      // Debe mostrarse la fecha y el botón para quitar
      expect(find.byKey(const Key('boton_quitar_fecha')), findsOneWidget);
      expect(find.text('Fecha límite opcional'), findsNothing);

      // Quitar fecha
      await tester.tap(find.byKey(const Key('boton_quitar_fecha')));
      await tester.pumpAndSettle();

      expect(find.text('Fecha límite opcional'), findsOneWidget);
      expect(find.byKey(const Key('boton_quitar_fecha')), findsNothing);
    });

    testWidgets('responsable de otro hogar es rechazado y muestra mensaje informativo',
        (tester) async {
      final integrantesConExtrano = [
        const Integrante(uid: 'usuario_otro_hogar', nombre: 'Extraño', esAdministrador: false),
      ];

      await _montar(
        tester,
        fakeQuehaceres: fakeQuehaceres,
        fakeHogares: fakeHogares,
        esAdmin: true,
        integrantes: integrantesConExtrano,
      );

      final campoTitulo = find.byKey(const Key('campo_titulo_quehacer'));
      final botonCrear = find.byKey(const Key('boton_crear_quehacer'));

      await tester.enterText(campoTitulo, 'Pasear al perro');
      await tester.tap(botonCrear);
      await tester.pumpAndSettle();

      expect(find.text(QuehaceresService.msgResponsableInvalido), findsOneWidget);
    });
  });
}
