import 'dart:async';

import 'package:easyhome/models/integrante.dart';
import 'package:easyhome/models/producto.dart';
import 'package:easyhome/models/quehacer.dart';
import 'package:easyhome/routes.dart';
import 'package:easyhome/screens/dashboard_screen.dart';
import 'package:easyhome/services/compras_service.dart';
import 'package:easyhome/services/hogar_service.dart';
import 'package:easyhome/services/notificaciones_service.dart';
import 'package:easyhome/services/quehaceres_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeNotificacionesTestService extends NotificacionesService {
  @override
  Future<String?> inicializar(String uid) async => 'fake_token';

  @override
  Future<void> limpiarToken(String uid) async {}
}


class FakeQuehaceresMarcarService extends QuehaceresService {
  final quehaceresCtrl = StreamController<List<Quehacer>>.broadcast();
  String? ultimoQuehacerId;
  String? ultimoAsignadoA;
  bool? ultimoNuevoEstado;
  String? ultimoUidActual;

  @override
  Stream<List<Quehacer>> observarQuehaceres(String hogarId) =>
      quehaceresCtrl.stream;

  @override
  Future<int> rotarSiCorresponde(String hogarId, {DateTime? ahora}) async => 0;

  @override
  Future<void> marcarHecho({
    required String quehacerId,
    required String asignadoA,
    required bool nuevoEstado,
    String? uidActual,
  }) async {
    final uid = uidActual ?? usuarioActualId;
    if (uid != asignadoA) {
      throw const QuehaceresException(QuehaceresService.msgNoEsResponsable);
    }
    ultimoQuehacerId = quehacerId;
    ultimoAsignadoA = asignadoA;
    ultimoNuevoEstado = nuevoEstado;
    ultimoUidActual = uidActual;
  }
}

class FakeHogarMarcarService extends HogarService {
  final integrantesCtrl = StreamController<List<Integrante>>.broadcast();

  @override
  Future<String?> obtenerHogarIdActual() async => 'hogar_123';

  @override
  Stream<List<Integrante>> observarIntegrantes(String hogarId) =>
      integrantesCtrl.stream;
}

class FakeComprasMarcarService extends ComprasService {
  final productosCtrl = StreamController<List<Producto>>.broadcast();

  @override
  Stream<List<Producto>> observarProductos(String hogarId) =>
      productosCtrl.stream;
}

final _integrantesPrueba = [
  const Integrante(uid: 'u_jaqueline', nombre: 'Jaqueline Camarillo', esAdministrador: true),
  const Integrante(uid: 'u_carlos', nombre: 'Carlos Ríos', esAdministrador: false),
];

final _qPendienteJaqueline = Quehacer(
  id: 'q1',
  hogarId: 'hogar_123',
  titulo: 'Pintar la cocina',
  asignadoA: 'u_jaqueline',
  hecho: false,
  creadoPor: 'u_jaqueline',
);

final _qPendienteCarlos = Quehacer(
  id: 'q2',
  hogarId: 'hogar_123',
  titulo: 'Reparar el lavabo',
  asignadoA: 'u_carlos',
  hecho: false,
  creadoPor: 'u_jaqueline',
);

final _qHechoJaqueline = Quehacer(
  id: 'q3',
  hogarId: 'hogar_123',
  titulo: 'Comprar bombillas',
  asignadoA: 'u_jaqueline',
  hecho: true,
  creadoPor: 'u_jaqueline',
);

Future<void> _montar(
  WidgetTester tester, {
  required FakeQuehaceresMarcarService fakeQuehaceres,
  required FakeHogarMarcarService fakeHogares,
  required FakeComprasMarcarService fakeCompras,
  required String usuarioActualId,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      routes: {
        AppRoutes.perfilHogar: (_) => const Scaffold(body: Text('Perfil')),
        AppRoutes.editarPerfil: (_) => const Scaffold(body: Text('Editar')),
      },
      home: DashboardScreen(
        hogarId: 'hogar_123',
        comprasService: fakeCompras,
        hogarService: fakeHogares,
        quehaceresService: fakeQuehaceres,
        notificacionesService: FakeNotificacionesTestService(),
        usuarioActualId: usuarioActualId,
        esAdministrador: usuarioActualId == 'u_jaqueline',
        vistaInicial: 1, // Quehaceres
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('Marcar Quehacer como Hecho Tests (#18)', () {
    late FakeQuehaceresMarcarService fakeQuehaceres;
    late FakeHogarMarcarService fakeHogares;
    late FakeComprasMarcarService fakeCompras;

    setUp(() {
      fakeQuehaceres = FakeQuehaceresMarcarService();
      fakeHogares = FakeHogarMarcarService();
      fakeCompras = FakeComprasMarcarService();
    });

    tearDown(() {
      fakeQuehaceres.quehaceresCtrl.close();
      fakeHogares.integrantesCtrl.close();
      fakeCompras.productosCtrl.close();
    });

    testWidgets('responsable puede marcar como hecho y desmarcar (toggle)',
        (tester) async {
      await _montar(
        tester,
        fakeQuehaceres: fakeQuehaceres,
        fakeHogares: fakeHogares,
        fakeCompras: fakeCompras,
        usuarioActualId: 'u_jaqueline',
      );

      fakeHogares.integrantesCtrl.add(_integrantesPrueba);
      fakeQuehaceres.quehaceresCtrl.add([_qPendienteJaqueline]);
      await tester.pumpAndSettle();

      final checkbox = find.byKey(const Key('checkbox_quehacer_q1'));
      expect(checkbox, findsOneWidget);

      // Tocar para marcar hecho
      await tester.tap(checkbox);
      await tester.pumpAndSettle();

      expect(fakeQuehaceres.ultimoQuehacerId, 'q1');
      expect(fakeQuehaceres.ultimoAsignadoA, 'u_jaqueline');
      expect(fakeQuehaceres.ultimoNuevoEstado, isTrue);
      expect(find.text('Quehacer completado'), findsOneWidget);

      // Simular que el stream emite el estado hecho
      fakeQuehaceres.quehaceresCtrl.add([_qHechoJaqueline.copyWith(id: 'q1')]);
      await tester.pumpAndSettle();

      // Desmarcar (toggle)
      await tester.tap(checkbox);
      await tester.pumpAndSettle();

      expect(fakeQuehaceres.ultimoNuevoEstado, isFalse);
      expect(find.text('Quehacer pendiente'), findsOneWidget);
    });

    testWidgets(
        'no responsable ve control deshabilitado y recibe mensaje informativo con nombre',
        (tester) async {
      await _montar(
        tester,
        fakeQuehaceres: fakeQuehaceres,
        fakeHogares: fakeHogares,
        fakeCompras: fakeCompras,
        usuarioActualId: 'u_jaqueline', // Jaqueline viendo tarea de Carlos
      );

      fakeHogares.integrantesCtrl.add(_integrantesPrueba);
      fakeQuehaceres.quehaceresCtrl.add([_qPendienteCarlos]);
      await tester.pumpAndSettle();

      // Cambiar a 'todos' para ver la tarea de Carlos
      await tester.tap(find.byKey(const Key('filtro_todos_quehaceres')));
      await tester.pumpAndSettle();

      final itemCarlos = find.byKey(const Key('item_quehacer_q2'));
      expect(itemCarlos, findsOneWidget);

      // Checkbox deshabilitado
      final checkboxWidget = tester.widget<Checkbox>(
        find.byKey(const Key('checkbox_quehacer_q2')),
      );
      expect(checkboxWidget.onChanged, isNull);

      // Tap en el tile de Carlos
      await tester.tap(itemCarlos);
      await tester.pumpAndSettle();

      expect(
        find.text('Solo Carlos Ríos puede marcar este quehacer'),
        findsOneWidget,
      );
      expect(fakeQuehaceres.ultimoQuehacerId, isNull);
    });

    test('servicio QuehaceresService rechaza intento de marcar con uid distinto',
        () async {
      final servicioReal = QuehaceresService(usuarioActualId: 'u_intruso');

      expect(
        () => servicioReal.marcarHecho(
          quehacerId: 'q1',
          asignadoA: 'u_jaqueline',
          nuevoEstado: true,
        ),
        throwsA(isA<QuehaceresException>().having(
          (e) => e.mensaje,
          'mensaje',
          QuehaceresService.msgNoEsResponsable,
        )),
      );
    });
  });
}
