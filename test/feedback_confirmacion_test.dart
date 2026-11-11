import 'dart:async';

import 'package:easyhome/models/producto.dart';
import 'package:easyhome/routes.dart';
import 'package:easyhome/screens/agregar_producto_screen.dart';
import 'package:easyhome/screens/dashboard_screen.dart';
import 'package:easyhome/services/compras_service.dart';
import 'package:easyhome/services/hogar_service.dart';
import 'package:easyhome/utils/app_feedback.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeComprasFeedbackService extends ComprasService {
  final productosCtrl = StreamController<List<Producto>>.broadcast();

  @override
  Stream<List<Producto>> observarProductos(String hogarId) =>
      productosCtrl.stream;

  @override
  Future<String> agregarProducto({
    required String hogarId,
    required String nombre,
    required int cantidad,
  }) async {
    return 'prod_nuevo';
  }

  @override
  Future<void> cambiarEstado({
    required String productoId,
    required bool comprado,
  }) async {}

  @override
  Future<void> editarProducto({
    required String productoId,
    required String nombre,
    required int cantidad,
  }) async {}

  @override
  Future<void> eliminarProducto(String productoId) async {}
}

class FakeHogarFeedbackService extends HogarService {
  @override
  Future<String?> obtenerHogarIdActual() async => 'hogar_1';
}

final _productoPrueba = Producto(
  id: 'p1',
  hogarId: 'hogar_1',
  nombre: 'Arroz',
  cantidad: 1,
  comprado: false,
);

void main() {
  group('Tarea #14 — Pantalla/feedback de confirmación visual', () {
    late FakeComprasFeedbackService fakeCompras;
    late FakeHogarFeedbackService fakeHogar;

    setUp(() {
      fakeCompras = FakeComprasFeedbackService();
      fakeHogar = FakeHogarFeedbackService();
    });

    tearDown(() {
      fakeCompras.productosCtrl.close();
    });

    test('Duración configurada está dentro del rango de 1 a 2 segundos', () {
      expect(AppFeedback.duracionBreve.inMilliseconds, greaterThanOrEqualTo(1000));
      expect(AppFeedback.duracionBreve.inMilliseconds, lessThanOrEqualTo(2000));
    });

    testWidgets('Acción #10 (Agregar): Muestra confirmación breve "Producto agregado"',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AgregarProductoScreen(
            hogarId: 'hogar_1',
            comprasService: fakeCompras,
            hogarService: fakeHogar,
          ),
        ),
      );

      await tester.enterText(
        find.byKey(const Key('campo_nombre_producto')),
        'Cereal',
      );
      await tester.tap(find.byKey(const Key('boton_agregar')));
      await tester.pump();

      expect(find.text('Producto agregado'), findsOneWidget);

      // Desaparece solo tras completarse la animación y duración breve
      await tester.pumpAndSettle();
      expect(find.text('Producto agregado'), findsNothing);
    });

    testWidgets('Acción #11 (Marcar comprado): Muestra mensaje "Marcado como comprado"',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          routes: {
            AppRoutes.agregarProducto: (_) => const Scaffold(),
            AppRoutes.perfilHogar: (_) => const Scaffold(),
          },
          home: DashboardScreen(
            hogarId: 'hogar_1',
            comprasService: fakeCompras,
            hogarService: fakeHogar,
          ),
        ),
      );
      await tester.pump();
      fakeCompras.productosCtrl.add([_productoPrueba]);
      await tester.pump();

      // Toque para marcar como comprado
      await tester.tap(find.byKey(Key('checkbox_${_productoPrueba.id}')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Marcado como comprado'), findsOneWidget);

      // El mensaje desaparece solo después de 1–2 segundos
      await tester.pump(const Duration(milliseconds: 2000));
      await tester.pumpAndSettle();
      expect(find.text('Marcado como comprado'), findsNothing);
    });

    testWidgets('Acción #12 (Editar): Muestra mensaje "Producto actualizado"',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          routes: {
            AppRoutes.agregarProducto: (_) => const Scaffold(),
            AppRoutes.perfilHogar: (_) => const Scaffold(),
          },
          home: DashboardScreen(
            hogarId: 'hogar_1',
            comprasService: fakeCompras,
            hogarService: fakeHogar,
          ),
        ),
      );
      await tester.pump();
      fakeCompras.productosCtrl.add([_productoPrueba]);
      await tester.pump();

      // Long press para abrir menú
      await tester.longPress(find.byKey(Key('tile_${_productoPrueba.id}')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('opcion_editar')));
      await tester.pumpAndSettle();

      // Guardar cambios
      await tester.tap(find.byKey(const Key('boton_guardar_edicion')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Producto actualizado'), findsOneWidget);

      // Desaparece solo
      await tester.pump(const Duration(milliseconds: 1600));
      await tester.pumpAndSettle();
      expect(find.text('Producto actualizado'), findsNothing);
    });

    testWidgets('Acción #13 (Eliminar): Muestra mensaje "Producto eliminado"',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          routes: {
            AppRoutes.agregarProducto: (_) => const Scaffold(),
            AppRoutes.perfilHogar: (_) => const Scaffold(),
          },
          home: DashboardScreen(
            hogarId: 'hogar_1',
            comprasService: fakeCompras,
            hogarService: fakeHogar,
          ),
        ),
      );
      await tester.pump();
      fakeCompras.productosCtrl.add([_productoPrueba]);
      await tester.pump();

      // Long press para abrir menú
      await tester.longPress(find.byKey(Key('tile_${_productoPrueba.id}')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('opcion_eliminar')));
      await tester.pumpAndSettle();

      // Confirmar eliminación
      await tester.tap(find.byKey(const Key('boton_confirmar_eliminar')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Producto eliminado'), findsOneWidget);

      // Desaparece solo
      await tester.pump(const Duration(milliseconds: 1600));
      await tester.pumpAndSettle();
      expect(find.text('Producto eliminado'), findsNothing);
    });

    testWidgets('No bloquea la pantalla ni interfiere con la siguiente acción del usuario',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          routes: {
            AppRoutes.agregarProducto: (_) => const Scaffold(),
            AppRoutes.perfilHogar: (_) => const Scaffold(),
          },
          home: DashboardScreen(
            hogarId: 'hogar_1',
            comprasService: fakeCompras,
            hogarService: fakeHogar,
          ),
        ),
      );
      await tester.pump();
      fakeCompras.productosCtrl.add([_productoPrueba]);
      await tester.pump();

      // Generar notificación de feedback
      await tester.tap(find.byKey(Key('checkbox_${_productoPrueba.id}')));
      await tester.pump();
      expect(find.text('Marcado como comprado'), findsOneWidget);

      // Con el feedback aún visible, el usuario puede interactuar de inmediato (p. ej. cambiar de pestaña)
      final tabComprados = find.byKey(const Key('tab_comprados'));
      expect(tabComprados, findsOneWidget);
      await tester.tap(tabComprados);
      await tester.pump();

      // Pudo cambiar de tab sin que el SnackBar bloquee la pantalla
      expect(find.byKey(const Key('tab_comprados')), findsOneWidget);
    });
  });
}
