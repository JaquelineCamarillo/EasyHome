import 'package:easyhome/screens/agregar_producto_screen.dart';
import 'package:easyhome/services/compras_service.dart';
import 'package:easyhome/services/hogar_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeAgregarComprasService extends ComprasService {
  String? hogarIdRecibido;
  String? nombreRecibido;
  int? cantidadRecibida;

  @override
  Future<String> agregarProducto({
    required String hogarId,
    required String nombre,
    required int cantidad,
  }) async {
    hogarIdRecibido = hogarId;
    nombreRecibido = nombre;
    cantidadRecibida = cantidad;
    return 'nuevo-id-123';
  }
}

class FakeAgregarHogarService extends HogarService {
  String? hogarIdActual = 'hogar-defecto-99';

  @override
  Future<String?> obtenerHogarIdActual() async => hogarIdActual;
}

Future<void> _montar(
  WidgetTester tester, {
  required FakeAgregarComprasService fakeCompras,
  required FakeAgregarHogarService fakeHogares,
  String? hogarId = 'hogar-1',
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: AgregarProductoScreen(
        hogarId: hogarId,
        comprasService: fakeCompras,
        hogarService: fakeHogares,
      ),
    ),
  );
}

void main() {
  late FakeAgregarComprasService fakeCompras;
  late FakeAgregarHogarService fakeHogares;

  setUp(() {
    fakeCompras = FakeAgregarComprasService();
    fakeHogares = FakeAgregarHogarService();
  });

  testWidgets('la cantidad inicia con valor por defecto 1', (tester) async {
    await _montar(tester, fakeCompras: fakeCompras, fakeHogares: fakeHogares);

    final formField = tester.widget<TextFormField>(
        find.byKey(const Key('campo_cantidad_producto')));
    expect(formField.controller?.text, '1');
  });

  testWidgets('nombre vacío no permite guardar', (tester) async {
    await _montar(tester, fakeCompras: fakeCompras, fakeHogares: fakeHogares);

    // Intentar guardar con nombre vacío
    await tester.tap(find.byKey(const Key('boton_agregar')));
    await tester.pump();

    expect(find.text('Ingresa el nombre del producto'), findsOneWidget);
    expect(fakeCompras.hogarIdRecibido, isNull);
  });

  testWidgets('cantidad inválida (0 o vacía) no permite guardar', (tester) async {
    await _montar(tester, fakeCompras: fakeCompras, fakeHogares: fakeHogares);

    await tester.enterText(
        find.byKey(const Key('campo_nombre_producto')), 'Manzanas');

    // Cantidad 0
    await tester.enterText(
        find.byKey(const Key('campo_cantidad_producto')), '0');
    await tester.pump();

    await tester.tap(find.byKey(const Key('boton_agregar')));
    await tester.pump();

    expect(
        find.text('La cantidad debe ser un número entero mayor a 0'),
        findsOneWidget);
    expect(fakeCompras.hogarIdRecibido, isNull);

    // Cantidad vacía
    await tester.enterText(
        find.byKey(const Key('campo_cantidad_producto')), '');
    await tester.pump();

    await tester.tap(find.byKey(const Key('boton_agregar')));
    await tester.pump();

    expect(find.text('Ingresa la cantidad'), findsOneWidget);
    expect(fakeCompras.hogarIdRecibido, isNull);
  });

  testWidgets('botones de incremento y decremento ajustan la cantidad', (tester) async {
    await _montar(tester, fakeCompras: fakeCompras, fakeHogares: fakeHogares);

    final formField = tester.widget<TextFormField>(
        find.byKey(const Key('campo_cantidad_producto')));
    expect(formField.controller?.text, '1');

    await tester.tap(find.byKey(const Key('boton_incrementar_cantidad')));
    await tester.pump();
    expect(formField.controller?.text, '2');

    await tester.tap(find.byKey(const Key('boton_decrementar_cantidad')));
    await tester.pump();
    expect(formField.controller?.text, '1');

    // No debe bajar de 1
    await tester.tap(find.byKey(const Key('boton_decrementar_cantidad')));
    await tester.pump();
    expect(formField.controller?.text, '1');
  });

  testWidgets('datos válidos guardan el producto correctamente con entero', (tester) async {
    await _montar(tester, fakeCompras: fakeCompras, fakeHogares: fakeHogares);

    await tester.enterText(
        find.byKey(const Key('campo_nombre_producto')), 'Café en grano');
    await tester.enterText(
        find.byKey(const Key('campo_cantidad_producto')), '3');
    await tester.pump();

    await tester.tap(find.byKey(const Key('boton_agregar')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(fakeCompras.hogarIdRecibido, 'hogar-1');
    expect(fakeCompras.nombreRecibido, 'Café en grano');
    expect(fakeCompras.cantidadRecibida, 3);
  });
}
