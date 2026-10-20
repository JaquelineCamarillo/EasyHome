import 'dart:async';

import 'package:easyhome/routes.dart';
import 'package:easyhome/screens/crear_unirse_hogar_screen.dart';
import 'package:easyhome/screens/dashboard_screen.dart';
import 'package:easyhome/screens/unirse_hogar_screen.dart';
import 'package:easyhome/services/hogar_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Servicio falso: no toca Firebase.
class FakeHogarService extends HogarService {
  int llamadas = 0;
  String? nombreRecibido;
  HogarException? error;
  Completer<String>? espera;

  @override
  Future<String> crearHogar({required String nombre}) async {
    llamadas++;
    nombreRecibido = nombre;
    if (espera != null) return espera!.future;
    if (error != null) throw error!;
    return 'hogar123';
  }
}

Future<void> _montar(WidgetTester tester, FakeHogarService fake) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(MaterialApp(
    home: CrearUnirseHogarScreen(hogarService: fake),
    routes: {
      AppRoutes.dashboard: (_) => const DashboardScreen(),
      AppRoutes.unirseHogar: (_) => const UnirseHogarScreen(),
    },
  ));
}

Finder get _boton => find.byKey(const Key('boton_crear_hogar'));
bool _habilitado(WidgetTester tester) =>
    tester.widget<FilledButton>(_boton).onPressed != null;

Future<void> _escribir(WidgetTester tester, String texto) async {
  await tester.enterText(find.byKey(const Key('campo_nombre_hogar')), texto);
  await tester.pump();
}

void main() {
  testWidgets('con el nombre vacío el botón está deshabilitado', (tester) async {
    await _montar(tester, FakeHogarService());
    expect(_habilitado(tester), isFalse);
  });

  testWidgets('solo espacios no permite crear el hogar', (tester) async {
    final fake = FakeHogarService();
    await _montar(tester, fake);
    await _escribir(tester, '     ');

    expect(_habilitado(tester), isFalse);
    expect(fake.llamadas, 0);
  });

  testWidgets('nombre válido crea el hogar y navega al dashboard', (tester) async {
    final fake = FakeHogarService();
    await _montar(tester, fake);
    await _escribir(tester, '  Casa de los Pérez ');

    expect(_habilitado(tester), isTrue);
    await tester.tap(_boton);
    await tester.pumpAndSettle();

    expect(fake.llamadas, 1);
    expect(fake.nombreRecibido, '  Casa de los Pérez '); // el servicio hace trim
    expect(find.byType(DashboardScreen), findsOneWidget);
  });

  testWidgets('si falla muestra el mensaje y se queda en la pantalla', (tester) async {
    final fake = FakeHogarService()
      ..error = const HogarException(HogarService.msgNoSePudoCrear);
    await _montar(tester, fake);
    await _escribir(tester, 'Mi casa');

    await tester.tap(_boton);
    await tester.pumpAndSettle();

    expect(find.text('No se pudo crear el hogar, intenta de nuevo'), findsOneWidget);
    expect(find.byType(CrearUnirseHogarScreen), findsOneWidget);
    expect(_habilitado(tester), isTrue); // puede reintentar
  });

  testWidgets('mientras procesa muestra spinner y bloquea el botón', (tester) async {
    final fake = FakeHogarService()..espera = Completer<String>();
    await _montar(tester, fake);
    await _escribir(tester, 'Mi casa');

    await tester.tap(_boton);
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(_habilitado(tester), isFalse);
    expect(fake.llamadas, 1);

    fake.espera!.complete('hogar123');
    await tester.pumpAndSettle();
  });

  testWidgets('el enlace "Únete a un hogar" navega a #6', (tester) async {
    await _montar(tester, FakeHogarService());
    await tester.tap(find.byKey(const Key('enlace_unirse')));
    await tester.pumpAndSettle();
    expect(find.byType(UnirseHogarScreen), findsOneWidget);
  });
}