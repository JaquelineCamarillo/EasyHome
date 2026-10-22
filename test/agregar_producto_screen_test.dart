import 'package:easyhome/screens/agregar_producto_screen.dart';
import 'package:easyhome/services/compras_service.dart';
import 'package:easyhome/services/hogar_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeAgregarComprasService extends ComprasService {
  String? hogarIdRecibido;
  String? nombreRecibido;
  String? cantidadRecibida;

  @override
  Future<String> agregarProducto({
    required String hogarId,
    required String nombre,
    required String cantidad,
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

  testWidgets('con campos vacíos muestra validación y no llama al servicio', (tester) async {
    await _montar(tester, fakeCompras: fakeCompras, fakeHogares: fakeHogares);

    await tester.tap(find.byKey(const Key('boton_guardar_producto')));
    await tester.pump();

    expect(find.text('Ingresa el nombre del producto'), findsOneWidget);
    expect(find.text('Ingresa la cantidad'), findsOneWidget);
    expect(fakeCompras.hogarIdRecibido, isNull);
  });

  testWidgets('tocar un chip de sugerencia rellena el campo de cantidad', (tester) async {
    await _montar(tester, fakeCompras: fakeCompras, fakeHogares: fakeHogares);

    await tester.tap(find.text('1 kg'));
    await tester.pump();

    expect(find.text('1 kg'), findsNWidgets(2)); // En el chip y en el input
  });

  testWidgets('datos válidos guardan el producto correctamente', (tester) async {
    await _montar(tester, fakeCompras: fakeCompras, fakeHogares: fakeHogares);

    await tester.enterText(
        find.byKey(const Key('campo_nombre_producto')), 'Café en grano');
    await tester.enterText(
        find.byKey(const Key('campo_cantidad_producto')), '500 gr');
    await tester.pump();

    await tester.tap(find.byKey(const Key('boton_guardar_producto')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(fakeCompras.hogarIdRecibido, 'hogar-1');
    expect(fakeCompras.nombreRecibido, 'Café en grano');
    expect(fakeCompras.cantidadRecibida, '500 gr');
  });
}
