import 'package:easyhome/models/producto.dart';
import 'package:easyhome/screens/agregar_producto_screen.dart';
import 'package:easyhome/services/compras_service.dart';
import 'package:easyhome/services/hogar_service.dart';
import 'package:easyhome/utils/validators.dart';
import 'package:easyhome/widgets/producto_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeCostoComprasService extends ComprasService {
  String? ultimoHogarId;
  String? ultimoNombre;
  int? ultimaCantidad;
  double? ultimoCosto;

  @override
  Future<String> agregarProducto({
    required String hogarId,
    required String nombre,
    required int cantidad,
    double? costo,
    String? descripcion,
  }) async {
    ultimoHogarId = hogarId;
    ultimoNombre = nombre;
    ultimaCantidad = cantidad;
    ultimoCosto = costo;
    return 'prod_123';
  }
}

class FakeCostoHogarService extends HogarService {
  @override
  Future<String?> obtenerHogarIdActual() async => 'hogar_costo_test';
}

void main() {
  group('Requerimiento 2: Costo en la lista de compras', () {
    late FakeCostoComprasService fakeCompras;
    late FakeCostoHogarService fakeHogares;

    setUp(() {
      fakeCompras = FakeCostoComprasService();
      fakeHogares = FakeCostoHogarService();
    });

    test('Modelo Producto serializa y deserializa costo opcional', () {
      final pSinCosto = Producto(
        id: 'p1',
        hogarId: 'h1',
        nombre: 'Leche',
        cantidad: 2,
        comprado: false,
      );
      expect(pSinCosto.costo, isNull);
      expect(pSinCosto.toMap()['costo'], isNull);

      final pConCosto = Producto(
        id: 'p2',
        hogarId: 'h1',
        nombre: 'Huevos',
        cantidad: 1,
        comprado: true,
        costo: 45.50,
      );
      expect(pConCosto.costo, 45.50);
      expect(pConCosto.toMap()['costo'], 45.50);

      final desdeMap = Producto.fromMap('p2', {
        'hogarId': 'h1',
        'nombre': 'Huevos',
        'cantidad': 1,
        'comprado': true,
        'costo': 45.50,
      });
      expect(desdeMap.costo, 45.50);
    });

    test('Validators.costoProducto valida opcional, >= 0 y máximo 2 decimales',
        () {
      // Opcional: nulo o vacío debe ser válido
      expect(Validators.costoProducto(null), isNull);
      expect(Validators.costoProducto(''), isNull);
      expect(Validators.costoProducto('   '), isNull);

      // Mayor o igual a 0 con hasta 2 decimales es válido
      expect(Validators.costoProducto('0'), isNull);
      expect(Validators.costoProducto('0.0'), isNull);
      expect(Validators.costoProducto('0.00'), isNull);
      expect(Validators.costoProducto('15'), isNull);
      expect(Validators.costoProducto('25.5'), isNull);
      expect(Validators.costoProducto('99.99'), isNull);

      // Negativos, texto o más de 2 decimales son inválidos
      expect(Validators.costoProducto('-1'), isNotNull);
      expect(Validators.costoProducto('-0.50'), isNotNull);
      expect(Validators.costoProducto('abc'), isNotNull);
      expect(Validators.costoProducto('12.345'), isNotNull);
    });

    testWidgets(
        'ProductoCard muestra badge de costo solo si está definido',
        (tester) async {
      final prodSinCosto = Producto(
        id: 'p_sin',
        hogarId: 'h1',
        nombre: 'Manzanas',
        cantidad: 3,
        comprado: false,
      );
      final prodConCosto = Producto(
        id: 'p_con',
        hogarId: 'h1',
        nombre: 'Queso',
        cantidad: 1,
        comprado: false,
        costo: 38.50,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                ProductoCard(
                  producto: prodSinCosto,
                  onToggle: () {},
                  onDelete: () {},
                  onLongPress: () {},
                ),
                ProductoCard(
                  producto: prodConCosto,
                  onToggle: () {},
                  onDelete: () {},
                  onLongPress: () {},
                ),
              ],
            ),
          ),
        ),
      );

      // El producto sin costo no tiene badge
      expect(find.byKey(const Key('badge_costo_p_sin')), findsNothing);

      // El producto con costo sí tiene badge con formato $38.50
      expect(find.byKey(const Key('badge_costo_p_con')), findsOneWidget);
      expect(find.text(r'$38.50'), findsOneWidget);
    });

    testWidgets(
        'ProgresoComprasBanner muestra el total de lo comprado correctamente',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                ProgresoComprasBanner(
                  comprados: 2,
                  total: 4,
                  totalCostoComprados: 75.25,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('total_costo_comprado')), findsOneWidget);
      expect(find.text(r'Total de lo comprado: $75.25'), findsOneWidget);
    });

    testWidgets(
        'AgregarProductoScreen permite guardar producto sin costo (opcional)',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AgregarProductoScreen(
            hogarId: 'hogar_123',
            comprasService: fakeCompras,
            hogarService: fakeHogares,
          ),
        ),
      );

      await tester.enterText(
        find.byKey(const Key('campo_nombre_producto')),
        'Arroz',
      );
      await tester.tap(find.byKey(const Key('boton_agregar')));
      await tester.pumpAndSettle();

      expect(fakeCompras.ultimoNombre, 'Arroz');
      expect(fakeCompras.ultimaCantidad, 1);
      expect(fakeCompras.ultimoCosto, isNull);
    });

    testWidgets(
        'AgregarProductoScreen guarda producto con costo cuando se proporciona',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AgregarProductoScreen(
            hogarId: 'hogar_123',
            comprasService: fakeCompras,
            hogarService: fakeHogares,
          ),
        ),
      );

      await tester.enterText(
        find.byKey(const Key('campo_nombre_producto')),
        'Aceite de Oliva',
      );
      await tester.enterText(
        find.byKey(const Key('campo_costo_producto')),
        '89.90',
      );
      await tester.tap(find.byKey(const Key('boton_agregar')));
      await tester.pumpAndSettle();

      expect(fakeCompras.ultimoNombre, 'Aceite de Oliva');
      expect(fakeCompras.ultimoCosto, 89.90);
    });
  });
}
