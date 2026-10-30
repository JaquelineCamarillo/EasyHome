import 'dart:async';

import 'package:easyhome/models/producto.dart';
import 'package:easyhome/routes.dart';
import 'package:easyhome/screens/dashboard_screen.dart';
import 'package:easyhome/services/compras_service.dart';
import 'package:easyhome/services/hogar_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeComprasService extends ComprasService {
  final productosCtrl = StreamController<List<Producto>>.broadcast();
  String? productoIdActualizado;
  bool? nuevoEstadoActualizado;
  String? productoIdEditado;
  String? nombreEditado;
  int? cantidadEditada;
  String? productoIdEliminado;

  @override
  Stream<List<Producto>> observarProductos(String hogarId) =>
      productosCtrl.stream;

  @override
  Future<void> cambiarEstado({
    required String productoId,
    required bool comprado,
  }) async {
    productoIdActualizado = productoId;
    nuevoEstadoActualizado = comprado;
  }

  @override
  Future<void> editarProducto({
    required String productoId,
    required String nombre,
    required int cantidad,
  }) async {
    productoIdEditado = productoId;
    nombreEditado = nombre;
    cantidadEditada = cantidad;
  }

  @override
  Future<void> eliminarProducto(String productoId) async {
    productoIdEliminado = productoId;
  }
}

class FakeHogarDashboardService extends HogarService {
  String? hogarIdActual = 'h1';

  @override
  Future<String?> obtenerHogarIdActual() async => hogarIdActual;
}

final _p1 = Producto(
  id: 'prod1',
  hogarId: 'h1',
  nombre: 'Manzanas',
  cantidad: 1,
  comprado: false,
  fechaCreacion: DateTime(2026, 10, 21, 10, 0),
);

final _p2 = Producto(
  id: 'prod2',
  hogarId: 'h1',
  nombre: 'Leche',
  cantidad: 2,
  comprado: true,
  fechaCreacion: DateTime(2026, 10, 21, 9, 0),
);

Future<void> _montar(
  WidgetTester tester, {
  required FakeComprasService fakeCompras,
  required FakeHogarDashboardService fakeHogares,
  String? hogarId = 'h1',
}) async {
  await tester.pumpWidget(
    MaterialApp(
      routes: {
        AppRoutes.perfilHogar: (_) => const Scaffold(body: Text('Pantalla Perfil')),
        AppRoutes.agregarProducto: (_) => const Scaffold(body: Text('Pantalla Agregar')),
      },
      home: DashboardScreen(
        hogarId: hogarId,
        comprasService: fakeCompras,
        hogarService: fakeHogares,
      ),
    ),
  );
}

void main() {
  late FakeComprasService fakeCompras;
  late FakeHogarDashboardService fakeHogares;

  setUp(() {
    fakeCompras = FakeComprasService();
    fakeHogares = FakeHogarDashboardService();
  });

  tearDown(() {
    fakeCompras.productosCtrl.close();
  });

  testWidgets('mientras carga muestra spinner', (tester) async {
    await _montar(tester, fakeCompras: fakeCompras, fakeHogares: fakeHogares);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('muestra estado vacío amigable cuando no hay productos', (tester) async {
    await _montar(tester, fakeCompras: fakeCompras, fakeHogares: fakeHogares);
    await tester.pump(); // inicializa stream

    fakeCompras.productosCtrl.add([]);
    await tester.pump();

    expect(find.byKey(const Key('mensaje_lista_vacia')), findsOneWidget);
    expect(find.text('Aún no hay productos en la lista'), findsOneWidget);
    expect(find.byKey(const Key('boton_agregar_producto')), findsOneWidget);
  });

  testWidgets('divide pendientes y comprados, mostrando nombre y cantidad', (tester) async {
    await _montar(tester, fakeCompras: fakeCompras, fakeHogares: fakeHogares);
    await tester.pump();

    fakeCompras.productosCtrl.add([_p1, _p2]);
    await tester.pump();

    // Tabs con contadores
    expect(find.text('Pendientes (1)'), findsOneWidget);
    expect(find.text('Comprados (1)'), findsOneWidget);

    // En tab pendientes: se muestra Manzanas y su cantidad
    expect(find.text('Manzanas'), findsOneWidget);
    expect(find.text('Cantidad: 1'), findsOneWidget);
    expect(find.text('Leche'), findsNothing);

    // Cambiar a la pestaña de comprados
    await tester.tap(find.byKey(const Key('tab_comprados')));
    await tester.pumpAndSettle();

    // En tab comprados: se muestra Leche, su cantidad y etiqueta de Comprado
    expect(find.text('Leche'), findsOneWidget);
    expect(find.text('Cantidad: 2'), findsOneWidget);
    expect(find.text('Comprado'), findsOneWidget);
  });

  testWidgets('actualiza en tiempo real cuando otro integrante modifica la lista', (tester) async {
    await _montar(tester, fakeCompras: fakeCompras, fakeHogares: fakeHogares);
    await tester.pump();

    fakeCompras.productosCtrl.add([_p1]);
    await tester.pump();

    expect(find.text('Manzanas'), findsOneWidget);
    expect(find.text('Pan'), findsNothing);

    // Simulamos que otro usuario agrega Pan
    final p3 = Producto(
      id: 'prod3',
      hogarId: 'h1',
      nombre: 'Pan integral',
      cantidad: 3,
      comprado: false,
      fechaCreacion: DateTime(2026, 10, 21, 11, 0),
    );
    fakeCompras.productosCtrl.add([p3, _p1]);
    await tester.pump();

    expect(find.text('Pan integral'), findsOneWidget);
    expect(find.text('Pendientes (2)'), findsOneWidget);
  });

  testWidgets('tocar el checkbox llama a cambiarEstado en el servicio', (tester) async {
    await _montar(tester, fakeCompras: fakeCompras, fakeHogares: fakeHogares);
    await tester.pump();

    fakeCompras.productosCtrl.add([_p1]);
    await tester.pump();

    final checkboxFinder = find.byKey(Key('checkbox_${_p1.id}'));
    expect(checkboxFinder, findsOneWidget);

    await tester.tap(checkboxFinder);
    await tester.pump();

    expect(fakeCompras.productoIdActualizado, 'prod1');
    expect(fakeCompras.nuevoEstadoActualizado, isTrue);
  });

  testWidgets('un toque sobre la tarjeta del producto actualiza comprado a true y no lo elimina (#11)', (tester) async {
    await _montar(tester, fakeCompras: fakeCompras, fakeHogares: fakeHogares);
    await tester.pump();

    fakeCompras.productosCtrl.add([_p1]);
    await tester.pump();

    // Tocar sobre la tarjeta completa (InkWell)
    await tester.tap(find.byKey(Key('tile_${_p1.id}')));
    await tester.pump();

    expect(fakeCompras.productoIdActualizado, 'prod1');
    expect(fakeCompras.nuevoEstadoActualizado, isTrue);

    // Cuando Firestore emite el producto actualizado con comprado=true
    final p1Comprado = _p1.copyWith(comprado: true);
    fakeCompras.productosCtrl.add([p1Comprado]);
    await tester.pump();

    // En pendientes ya no está
    expect(find.text('Manzanas'), findsNothing);
    expect(find.text('Pendientes (0)'), findsOneWidget);
    expect(find.text('Comprados (1)'), findsOneWidget);

    // En comprados sí está (no fue eliminado)
    await tester.tap(find.byKey(const Key('tab_comprados')));
    await tester.pumpAndSettle();
    expect(find.text('Manzanas'), findsOneWidget);
    expect(find.text('Comprado'), findsOneWidget);

    // Si se toca en la pestaña de comprados, se desmarca a false y regresa a pendientes
    await tester.tap(find.byKey(Key('tile_${_p1.id}')));
    await tester.pump();

    expect(fakeCompras.productoIdActualizado, 'prod1');
    expect(fakeCompras.nuevoEstadoActualizado, isFalse);
  });

  testWidgets('botón (+) navega al formulario de agregar producto', (tester) async {
    await _montar(tester, fakeCompras: fakeCompras, fakeHogares: fakeHogares);
    await tester.pump();

    fakeCompras.productosCtrl.add([]);
    await tester.pump();

    await tester.tap(find.byKey(const Key('boton_agregar_producto')));
    await tester.pumpAndSettle();

    expect(find.text('Pantalla Agregar'), findsOneWidget);
  });

  testWidgets('botón en AppBar navega al perfil del hogar', (tester) async {
    await _montar(tester, fakeCompras: fakeCompras, fakeHogares: fakeHogares);
    await tester.pump();

    fakeCompras.productosCtrl.add([]);
    await tester.pump();

    await tester.tap(find.byKey(const Key('boton_perfil_hogar')));
    await tester.pumpAndSettle();

    expect(find.text('Pantalla Perfil'), findsOneWidget);
  });

  testWidgets('mantener presionado abre menú de opciones (Editar y Eliminar)', (tester) async {
    await _montar(tester, fakeCompras: fakeCompras, fakeHogares: fakeHogares);
    await tester.pump();

    fakeCompras.productosCtrl.add([_p1]);
    await tester.pump();

    // Long press sobre la tarjeta
    await tester.longPress(find.byKey(Key('tile_${_p1.id}')));
    await tester.pumpAndSettle();

    // Menú de opciones visible
    expect(find.byKey(const Key('titulo_menu_opciones')), findsOneWidget);
    expect(find.byKey(const Key('opcion_editar')), findsOneWidget);
    expect(find.byKey(const Key('opcion_eliminar')), findsOneWidget);
    expect(find.text('Editar'), findsOneWidget);
    expect(find.text('Eliminar'), findsOneWidget);
  });

  testWidgets('formulario de edición carga valores actuales y valida campos', (tester) async {
    await _montar(tester, fakeCompras: fakeCompras, fakeHogares: fakeHogares);
    await tester.pump();

    fakeCompras.productosCtrl.add([_p1]);
    await tester.pump();

    // Abrir menú con long press
    await tester.longPress(find.byKey(Key('tile_${_p1.id}')));
    await tester.pumpAndSettle();

    // Tocar opción "Editar"
    await tester.tap(find.byKey(const Key('opcion_editar')));
    await tester.pumpAndSettle();

    // Formulario precargado con valores actuales
    expect(find.text('Editar producto'), findsOneWidget);
    final campoNombre = find.byKey(const Key('campo_editar_nombre_producto'));
    final campoCantidad = find.byKey(const Key('campo_editar_cantidad_producto'));

    expect(campoNombre, findsOneWidget);
    expect(campoCantidad, findsOneWidget);
    expect(tester.widget<TextFormField>(campoNombre).controller?.text, 'Manzanas');
    expect(tester.widget<TextFormField>(campoCantidad).controller?.text, '1');

    // Validación: nombre vacío no permite guardar
    await tester.enterText(campoNombre, '');
    await tester.tap(find.byKey(const Key('boton_guardar_edicion')));
    await tester.pump();

    expect(find.text('Ingresa el nombre del producto'), findsOneWidget);
    expect(fakeCompras.productoIdEditado, isNull);

    // Validación: cantidad inválida (0 o vacía) no permite guardar
    await tester.enterText(campoNombre, 'Manzanas Rojas');
    await tester.enterText(campoCantidad, '0');
    await tester.tap(find.byKey(const Key('boton_guardar_edicion')));
    await tester.pump();

    expect(find.text('La cantidad debe ser un número entero mayor a 0'), findsOneWidget);
    expect(fakeCompras.productoIdEditado, isNull);
  });

  testWidgets('guardar edición actualiza Firestore y se refleja en tiempo real', (tester) async {
    await _montar(tester, fakeCompras: fakeCompras, fakeHogares: fakeHogares);
    await tester.pump();

    fakeCompras.productosCtrl.add([_p1]);
    await tester.pump();

    // Abrir menú y editar
    await tester.longPress(find.byKey(Key('tile_${_p1.id}')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('opcion_editar')));
    await tester.pumpAndSettle();

    // Modificar nombre y usar stepper para incrementar cantidad
    await tester.enterText(find.byKey(const Key('campo_editar_nombre_producto')), 'Manzanas Verdes');
    await tester.tap(find.byKey(const Key('boton_incrementar_cantidad_edicion')));
    await tester.pump();

    // Guardar cambios
    await tester.tap(find.byKey(const Key('boton_guardar_edicion')));
    await tester.pumpAndSettle();

    // Verifica que se llamó al servicio con los datos editados
    expect(fakeCompras.productoIdEditado, 'prod1');
    expect(fakeCompras.nombreEditado, 'Manzanas Verdes');
    expect(fakeCompras.cantidadEditada, 2);

    // Simular actualización en tiempo real desde Firestore
    final p1Editado = _p1.copyWith(nombre: 'Manzanas Verdes', cantidad: 2);
    fakeCompras.productosCtrl.add([p1Editado]);
    await tester.pump();
    await tester.pump();

    // El dashboard muestra de inmediato los nuevos valores
    expect(find.text('Manzanas Verdes'), findsOneWidget);
    expect(find.text('Cantidad: 2'), findsOneWidget);
    expect(find.text('Manzanas'), findsNothing);
  });

  testWidgets('desde el menú de opciones, cancelar la confirmación no elimina nada (#13)', (tester) async {
    await _montar(tester, fakeCompras: fakeCompras, fakeHogares: fakeHogares);
    await tester.pump();

    fakeCompras.productosCtrl.add([_p1]);
    await tester.pump();

    // Mantener presionado para abrir el menú de opciones
    await tester.longPress(find.byKey(Key('tile_${_p1.id}')));
    await tester.pumpAndSettle();

    // Tocar opción "Eliminar"
    await tester.tap(find.byKey(const Key('opcion_eliminar')));
    await tester.pumpAndSettle();

    // Diálogo de confirmación visible
    expect(find.text('Eliminar producto'), findsOneWidget);
    expect(
      find.textContaining('¿Seguro que quieres eliminar este producto'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('boton_cancelar_eliminar')), findsOneWidget);
    expect(find.byKey(const Key('boton_confirmar_eliminar')), findsOneWidget);

    // Cancelar la eliminación
    await tester.tap(find.byKey(const Key('boton_cancelar_eliminar')));
    await tester.pumpAndSettle();

    // No se llamó al servicio y el producto sigue en pantalla
    expect(fakeCompras.productoIdEliminado, isNull);
    expect(find.text('Manzanas'), findsOneWidget);
  });

  testWidgets('desde el menú de opciones, confirmar elimina y desaparece en tiempo real (#13)', (tester) async {
    await _montar(tester, fakeCompras: fakeCompras, fakeHogares: fakeHogares);
    await tester.pump();

    fakeCompras.productosCtrl.add([_p1]);
    await tester.pump();

    // Mantener presionado para abrir el menú de opciones
    await tester.longPress(find.byKey(Key('tile_${_p1.id}')));
    await tester.pumpAndSettle();

    // Tocar opción "Eliminar"
    await tester.tap(find.byKey(const Key('opcion_eliminar')));
    await tester.pumpAndSettle();

    // Confirmar eliminación
    await tester.tap(find.byKey(const Key('boton_confirmar_eliminar')));
    await tester.pumpAndSettle();

    // Se llamó a eliminar en Firestore
    expect(fakeCompras.productoIdEliminado, 'prod1');

    // Firestore emite la lista vacía tras eliminarse
    fakeCompras.productosCtrl.add([]);
    await tester.pump();
    await tester.pump();

    // El producto desaparece de la lista y se muestra el estado vacío
    expect(find.text('Manzanas'), findsNothing);
    expect(find.byKey(const Key('mensaje_lista_vacia')), findsOneWidget);
  });
}
