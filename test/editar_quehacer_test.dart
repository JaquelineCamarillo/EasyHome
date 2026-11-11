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


class FakeQuehaceresEditarService extends QuehaceresService {
  final quehaceresCtrl = StreamController<List<Quehacer>>.broadcast();

  String? quehacerIdEditado;
  String? tituloEditado;
  DateTime? fechaLimiteEditada;
  bool? limpiarFechaEditada;
  bool? recurrenteEditado;

  String? quehacerIdReasignado;
  String? nuevoAsignadoAReasignado;

  String? quehacerIdEliminado;

  @override
  Stream<List<Quehacer>> observarQuehaceres(String hogarId) =>
      quehaceresCtrl.stream;

  @override
  Future<void> actualizarQuehacer({
    required String quehacerId,
    required String titulo,
    DateTime? fechaLimite,
    bool limpiarFecha = false,
    bool esAdmin = true,
    bool? recurrente,
  }) async {
    if (!esAdmin) {
      throw const QuehaceresException(QuehaceresService.msgSinPermiso);
    }
    quehacerIdEditado = quehacerId;
    tituloEditado = titulo;
    fechaLimiteEditada = fechaLimite;
    limpiarFechaEditada = limpiarFecha;
    recurrenteEditado = recurrente;
  }

  @override
  Future<int> rotarSiCorresponde(String hogarId, {DateTime? ahora}) async => 0;

  @override
  Future<void> reasignarQuehacer({
    required String quehacerId,
    required String nuevoAsignadoA,
    required String hogarId,
    bool esAdmin = true,
  }) async {
    if (!esAdmin) {
      throw const QuehaceresException(QuehaceresService.msgSinPermiso);
    }
    quehacerIdReasignado = quehacerId;
    nuevoAsignadoAReasignado = nuevoAsignadoA;
  }

  @override
  Future<void> eliminarQuehacer({
    required String quehacerId,
    bool esAdmin = true,
  }) async {
    if (!esAdmin) {
      throw const QuehaceresException(QuehaceresService.msgSinPermiso);
    }
    quehacerIdEliminado = quehacerId;
  }
}

class FakeHogarEditarService extends HogarService {
  final integrantesCtrl = StreamController<List<Integrante>>.broadcast();

  @override
  Future<String?> obtenerHogarIdActual() async => 'hogar_123';

  @override
  Stream<List<Integrante>> observarIntegrantes(String hogarId) =>
      integrantesCtrl.stream;
}

class FakeComprasEditarService extends ComprasService {
  final productosCtrl = StreamController<List<Producto>>.broadcast();

  @override
  Stream<List<Producto>> observarProductos(String hogarId) =>
      productosCtrl.stream;
}

final _integrantesPrueba = [
  const Integrante(uid: 'u_admin', nombre: 'Jaqueline Admin', esAdministrador: true),
  const Integrante(uid: 'u_miembro', nombre: 'Carlos Miembro', esAdministrador: false),
];

final _qPrueba = Quehacer(
  id: 'q1',
  hogarId: 'hogar_123',
  titulo: 'Limpiar el garage',
  asignadoA: 'u_admin',
  hecho: false,
  creadoPor: 'u_admin',
  fechaLimite: DateTime(2026, 12, 1),
  recurrente: false,
);

Future<void> _montar(
  WidgetTester tester, {
  required FakeQuehaceresEditarService fakeQuehaceres,
  required FakeHogarEditarService fakeHogares,
  required FakeComprasEditarService fakeCompras,
  bool esAdmin = true,
  String usuarioActualId = 'u_admin',
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
        esAdministrador: esAdmin,
        vistaInicial: 1, // Quehaceres
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('Editar, reasignar y eliminar Quehacer (#19 y #20)', () {
    late FakeQuehaceresEditarService fakeQuehaceres;
    late FakeHogarEditarService fakeHogares;
    late FakeComprasEditarService fakeCompras;

    setUp(() {
      fakeQuehaceres = FakeQuehaceresEditarService();
      fakeHogares = FakeHogarEditarService();
      fakeCompras = FakeComprasEditarService();
    });

    tearDown(() {
      fakeQuehaceres.quehaceresCtrl.close();
      fakeHogares.integrantesCtrl.close();
      fakeCompras.productosCtrl.close();
    });

    testWidgets('menú muestra 3 opciones para admin (Editar, Reasignar, Eliminar)',
        (tester) async {
      await _montar(
        tester,
        fakeQuehaceres: fakeQuehaceres,
        fakeHogares: fakeHogares,
        fakeCompras: fakeCompras,
        esAdmin: true,
      );

      fakeHogares.integrantesCtrl.add(_integrantesPrueba);
      fakeQuehaceres.quehaceresCtrl.add([_qPrueba]);
      await tester.pumpAndSettle();

      final botonOpciones = find.byKey(const Key('boton_opciones_quehacer_q1'));
      expect(botonOpciones, findsOneWidget);

      await tester.tap(botonOpciones);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('titulo_menu_opciones_quehacer')), findsOneWidget);
      expect(find.byKey(const Key('opcion_editar_quehacer')), findsOneWidget);
      expect(find.byKey(const Key('opcion_reasignar_quehacer')), findsOneWidget);
      expect(find.byKey(const Key('opcion_eliminar_quehacer')), findsOneWidget);
    });

    testWidgets('editar precarga título, fecha y switch recurrente, y guarda los cambios',
        (tester) async {
      await _montar(
        tester,
        fakeQuehaceres: fakeQuehaceres,
        fakeHogares: fakeHogares,
        fakeCompras: fakeCompras,
        esAdmin: true,
      );

      fakeHogares.integrantesCtrl.add(_integrantesPrueba);
      fakeQuehaceres.quehaceresCtrl.add([_qPrueba]);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('boton_opciones_quehacer_q1')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('opcion_editar_quehacer')));
      await tester.pumpAndSettle();

      // Precarga comprobada en el campo de edición y selector de fecha
      final campoTextFormField = tester.widget<TextFormField>(
        find.byKey(const Key('campo_editar_titulo_quehacer')),
      );
      expect(campoTextFormField.controller?.text, 'Limpiar el garage');
      expect(find.byKey(const Key('texto_fecha_edicion')), findsOneWidget);
      expect(
        tester.widget<Text>(find.byKey(const Key('texto_fecha_edicion'))).data,
        '01/12/2026',
      );

      // Modificar título y activar switch recurrente
      final campoTitulo = find.byKey(const Key('campo_editar_titulo_quehacer'));
      await tester.enterText(campoTitulo, 'Limpiar y ordenar garage');

      final switchRecurrente = find.byKey(const Key('switch_recurrente_edicion'));
      expect(switchRecurrente, findsOneWidget);
      await tester.tap(switchRecurrente);
      await tester.pumpAndSettle();

      // Guardar
      await tester.tap(find.byKey(const Key('boton_guardar_edicion_quehacer')));
      await tester.pumpAndSettle();

      expect(fakeQuehaceres.quehacerIdEditado, 'q1');
      expect(fakeQuehaceres.tituloEditado, 'Limpiar y ordenar garage');
      expect(fakeQuehaceres.recurrenteEditado, isTrue);
      expect(find.text('Quehacer actualizado'), findsOneWidget);
    });

    testWidgets('reasignar actualiza asignadoA al nuevo integrante',
        (tester) async {
      await _montar(
        tester,
        fakeQuehaceres: fakeQuehaceres,
        fakeHogares: fakeHogares,
        fakeCompras: fakeCompras,
        esAdmin: true,
      );

      fakeHogares.integrantesCtrl.add(_integrantesPrueba);
      fakeQuehaceres.quehaceresCtrl.add([_qPrueba]);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('boton_opciones_quehacer_q1')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('opcion_reasignar_quehacer')));
      await tester.pumpAndSettle();

      expect(find.text('Reasignar quehacer'), findsOneWidget);

      // Cambiar integrante
      await tester.tap(find.byKey(const Key('dropdown_reasignar_integrante')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Carlos Miembro').last);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('boton_confirmar_reasignar')));
      await tester.pumpAndSettle();

      expect(fakeQuehaceres.quehacerIdReasignado, 'q1');
      expect(fakeQuehaceres.nuevoAsignadoAReasignado, 'u_miembro');
      expect(find.text('Quehacer reasignado'), findsOneWidget);
    });

    testWidgets('eliminar pide confirmación; cancelar no borra y confirmar elimina',
        (tester) async {
      await _montar(
        tester,
        fakeQuehaceres: fakeQuehaceres,
        fakeHogares: fakeHogares,
        fakeCompras: fakeCompras,
        esAdmin: true,
      );

      fakeHogares.integrantesCtrl.add(_integrantesPrueba);
      fakeQuehaceres.quehaceresCtrl.add([_qPrueba]);
      await tester.pumpAndSettle();

      // Abrir menú y opción eliminar
      await tester.tap(find.byKey(const Key('boton_opciones_quehacer_q1')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('opcion_eliminar_quehacer')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('mensaje_confirmar_eliminar_quehacer')), findsOneWidget);

      // Cancelar
      await tester.tap(find.byKey(const Key('boton_cancelar_eliminar_quehacer')));
      await tester.pumpAndSettle();

      expect(fakeQuehaceres.quehacerIdEliminado, isNull);

      // Abrir de nuevo y confirmar
      await tester.tap(find.byKey(const Key('boton_opciones_quehacer_q1')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('opcion_eliminar_quehacer')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('boton_confirmar_eliminar_quehacer')));
      await tester.pumpAndSettle();

      expect(fakeQuehaceres.quehacerIdEliminado, 'q1');
      expect(find.text('Quehacer eliminado'), findsOneWidget);
    });

    testWidgets('no-admin no ve botón de opciones y long press muestra mensaje de permiso',
        (tester) async {
      await _montar(
        tester,
        fakeQuehaceres: fakeQuehaceres,
        fakeHogares: fakeHogares,
        fakeCompras: fakeCompras,
        esAdmin: false,
        usuarioActualId: 'u_miembro',
      );

      fakeHogares.integrantesCtrl.add(_integrantesPrueba);
      fakeQuehaceres.quehaceresCtrl.add([_qPrueba]);
      await tester.pumpAndSettle();

      // Cambiar a todos para ver la tarjeta
      await tester.tap(find.byKey(const Key('filtro_todos_quehaceres')));
      await tester.pumpAndSettle();

      // Botón ⋮ no visible para no-admin
      expect(find.byKey(const Key('boton_opciones_quehacer_q1')), findsNothing);

      // Intentar long press en la tarjeta
      await tester.longPress(find.byKey(const Key('item_quehacer_q1')));
      await tester.pumpAndSettle();

      expect(find.text(QuehaceresService.msgSinPermiso), findsOneWidget);
    });
  });
}
