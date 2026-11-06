import 'dart:async';

import 'package:easyhome/models/integrante.dart';
import 'package:easyhome/models/producto.dart';
import 'package:easyhome/models/quehacer.dart';
import 'package:easyhome/routes.dart';
import 'package:easyhome/screens/dashboard_screen.dart';
import 'package:easyhome/services/compras_service.dart';
import 'package:easyhome/services/hogar_service.dart';
import 'package:easyhome/services/quehaceres_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeQuehaceresTestService extends QuehaceresService {
  final quehaceresCtrl = StreamController<List<Quehacer>>.broadcast();

  @override
  Stream<List<Quehacer>> observarQuehaceres(String hogarId) =>
      quehaceresCtrl.stream;

  @override
  Future<int> rotarSiCorresponde(String hogarId, {DateTime? ahora}) async => 0;
}

class FakeHogarQuehaceresTestService extends HogarService {
  final integrantesCtrl = StreamController<List<Integrante>>.broadcast();

  @override
  Future<String?> obtenerHogarIdActual() async => 'h1';

  @override
  Stream<List<Integrante>> observarIntegrantes(String hogarId) =>
      integrantesCtrl.stream;
}

class FakeComprasTestService extends ComprasService {
  final productosCtrl = StreamController<List<Producto>>.broadcast();

  @override
  Stream<List<Producto>> observarProductos(String hogarId) =>
      productosCtrl.stream;
}

final _integrantesPrueba = [
  const Integrante(
    uid: 'u1',
    nombre: 'Jaqueline',
    esAdministrador: true,
  ),
  const Integrante(
    uid: 'u2',
    nombre: 'Carlos',
    esAdministrador: false,
  ),
];

final _q1 = Quehacer(
  id: 'q1',
  hogarId: 'h1',
  titulo: 'Lavar los platos',
  asignadoA: 'u1',
  hecho: false,
  creadoPor: 'u1',
  fechaLimite: DateTime(2026, 11, 20),
  recurrente: true,
);

final _q2 = Quehacer(
  id: 'q2',
  hogarId: 'h1',
  titulo: 'Barrer la sala',
  asignadoA: 'u2',
  hecho: false,
  creadoPor: 'u1',
  recurrente: false,
);

final _q3 = Quehacer(
  id: 'q3',
  hogarId: 'h1',
  titulo: 'Sacar la basura',
  asignadoA: 'u1',
  hecho: true,
  creadoPor: 'u1',
  recurrente: false,
);

Future<void> _montar(
  WidgetTester tester, {
  required FakeQuehaceresTestService fakeQuehaceres,
  required FakeHogarQuehaceresTestService fakeHogares,
  required FakeComprasTestService fakeCompras,
  bool esAdmin = true,
  String usuarioActualId = 'u1',
}) async {
  await tester.pumpWidget(
    MaterialApp(
      routes: {
        AppRoutes.perfilHogar: (_) =>
            const Scaffold(body: Text('Pantalla Perfil Hogar')),
        AppRoutes.editarPerfil: (_) =>
            const Scaffold(body: Text('Pantalla Editar Perfil')),
        AppRoutes.agregarQuehacer: (_) =>
            const Scaffold(body: Text('Pantalla Agregar Quehacer')),
      },
      home: DashboardScreen(
        hogarId: 'h1',
        comprasService: fakeCompras,
        hogarService: fakeHogares,
        quehaceresService: fakeQuehaceres,
        usuarioActualId: usuarioActualId,
        esAdministrador: esAdmin,
        vistaInicial: 1, // Directo a Quehaceres
      ),
    ),
  );
}

void main() {
  group('Dashboard Quehaceres Tests (#16 y #20)', () {
    late FakeQuehaceresTestService fakeQuehaceres;
    late FakeHogarQuehaceresTestService fakeHogares;
    late FakeComprasTestService fakeCompras;

    setUp(() {
      fakeQuehaceres = FakeQuehaceresTestService();
      fakeHogares = FakeHogarQuehaceresTestService();
      fakeCompras = FakeComprasTestService();
    });

    tearDown(() {
      fakeQuehaceres.quehaceresCtrl.close();
      fakeHogares.integrantesCtrl.close();
      fakeCompras.productosCtrl.close();
    });

    testWidgets(
        'lista con 3 quehaceres de 2 usuarios muestra datos, responsables y estados',
        (tester) async {
      await _montar(
        tester,
        fakeQuehaceres: fakeQuehaceres,
        fakeHogares: fakeHogares,
        fakeCompras: fakeCompras,
      );

      fakeHogares.integrantesCtrl.add(_integrantesPrueba);
      fakeQuehaceres.quehaceresCtrl.add([_q1, _q2, _q3]);
      await tester.pumpAndSettle();

      // Cambiar a todos para ver los 3
      await tester.tap(find.byKey(const Key('filtro_todos_quehaceres')));
      await tester.pumpAndSettle();

      expect(find.text('Lavar los platos'), findsOneWidget);
      expect(find.text('Barrer la sala'), findsOneWidget);
      expect(find.text('Sacar la basura'), findsOneWidget);

      expect(find.text('Jaqueline'), findsNWidgets(2));
      expect(find.text('Carlos'), findsOneWidget);

      expect(find.text('Pendiente'), findsNWidgets(2));
      expect(find.text('Hecho'), findsOneWidget);
      expect(find.text('20/11/2026'), findsOneWidget);

      // Badge de rotación semanal (#20)
      expect(find.byKey(const Key('badge_recurrente_q1')), findsOneWidget);
      expect(find.text('Semanal'), findsOneWidget);
      expect(find.byKey(const Key('badge_recurrente_q2')), findsNothing);
    });

    testWidgets('filtro Mis quehaceres muestra solo los asignados al uid actual',
        (tester) async {
      await _montar(
        tester,
        fakeQuehaceres: fakeQuehaceres,
        fakeHogares: fakeHogares,
        fakeCompras: fakeCompras,
        usuarioActualId: 'u1',
      );

      fakeHogares.integrantesCtrl.add(_integrantesPrueba);
      fakeQuehaceres.quehaceresCtrl.add([_q1, _q2, _q3]);
      await tester.pumpAndSettle();

      // Inicia en 'mis' por defecto
      expect(find.text('Lavar los platos'), findsOneWidget);
      expect(find.text('Sacar la basura'), findsOneWidget);
      expect(find.text('Barrer la sala'), findsNothing);

      // Cambiar a 'todos'
      await tester.tap(find.byKey(const Key('filtro_todos_quehaceres')));
      await tester.pumpAndSettle();
      expect(find.text('Barrer la sala'), findsOneWidget);
    });

    testWidgets('FAB es visible para administrador y oculto para no administrador',
        (tester) async {
      // Admin
      await _montar(
        tester,
        fakeQuehaceres: fakeQuehaceres,
        fakeHogares: fakeHogares,
        fakeCompras: fakeCompras,
        esAdmin: true,
      );
      fakeHogares.integrantesCtrl.add(_integrantesPrueba);
      fakeQuehaceres.quehaceresCtrl.add([]);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('boton_agregar_quehacer')), findsOneWidget);

      // Tap navega
      await tester.tap(find.byKey(const Key('boton_agregar_quehacer')));
      await tester.pumpAndSettle();
      expect(find.text('Pantalla Agregar Quehacer'), findsOneWidget);

      // No admin
      await tester.pumpWidget(const SizedBox());
      await _montar(
        tester,
        fakeQuehaceres: fakeQuehaceres,
        fakeHogares: fakeHogares,
        fakeCompras: fakeCompras,
        esAdmin: false,
      );
      fakeHogares.integrantesCtrl.add(_integrantesPrueba);
      fakeQuehaceres.quehaceresCtrl.add([]);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('boton_agregar_quehacer')), findsNothing);
    });

    testWidgets('muestra estado vacío amable cuando no hay quehaceres',
        (tester) async {
      await _montar(
        tester,
        fakeQuehaceres: fakeQuehaceres,
        fakeHogares: fakeHogares,
        fakeCompras: fakeCompras,
      );

      fakeHogares.integrantesCtrl.add(_integrantesPrueba);
      fakeQuehaceres.quehaceresCtrl.add([]);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('estado_vacio_quehaceres')), findsOneWidget);
      expect(find.text('Aún no hay quehaceres'), findsOneWidget);
    });

    testWidgets('actualización en vivo al emitir nuevo evento en el stream',
        (tester) async {
      await _montar(
        tester,
        fakeQuehaceres: fakeQuehaceres,
        fakeHogares: fakeHogares,
        fakeCompras: fakeCompras,
      );

      fakeHogares.integrantesCtrl.add(_integrantesPrueba);
      fakeQuehaceres.quehaceresCtrl.add([_q1]);
      await tester.pumpAndSettle();

      expect(find.text('Lavar los platos'), findsOneWidget);
      expect(find.text('Sacar la basura'), findsNothing);

      // Agregar doc en vivo
      fakeQuehaceres.quehaceresCtrl.add([_q1, _q3]);
      await tester.pumpAndSettle();

      expect(find.text('Lavar los platos'), findsOneWidget);
      expect(find.text('Sacar la basura'), findsOneWidget);
    });
  });
}
