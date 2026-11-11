import 'dart:async';

import 'package:easyhome/routes.dart';
import 'package:easyhome/screens/crear_unirse_hogar_screen.dart';
import 'package:easyhome/screens/dashboard_screen.dart';
import 'package:easyhome/screens/unirse_hogar_screen.dart';
import 'package:easyhome/services/hogar_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Servicio falso: no toca Firebase.
class FakeHogarUnirse extends HogarService {
  int llamadas = 0;
  String? codigoRecibido;
  HogarException? error;
  Completer<String>? espera;

  @override
  Future<String> unirseAHogar({required String codigo}) async {
    llamadas++;
    codigoRecibido = codigo;
    if (espera != null) return espera!.future;
    if (error != null) throw error!;
    return 'hogar123';
  }
}

Future<void> _montar(WidgetTester tester, FakeHogarUnirse fake) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(MaterialApp(
    home: UnirseHogarScreen(hogarService: fake),
    routes: {
      AppRoutes.dashboard: (_) => const DashboardScreen(),
      AppRoutes.hogar: (_) => const CrearUnirseHogarScreen(),
    },
  ));
}

Finder get _boton => find.byKey(const Key('boton_unirse'));
bool _habilitado(WidgetTester tester) =>
    tester.widget<FilledButton>(_boton).onPressed != null;

Future<void> _escribir(WidgetTester tester, String texto) async {
  await tester.enterText(find.byKey(const Key('campo_codigo')), texto);
  await tester.pump();
}

void main() {
  testWidgets('con el código vacío el botón está deshabilitado', (tester) async {
    final fake = FakeHogarUnirse();
    await _montar(tester, fake);

    expect(_habilitado(tester), isFalse);
    expect(fake.llamadas, 0);
  });

  testWidgets('escribe en mayúsculas automáticamente', (tester) async {
    final fake = FakeHogarUnirse();
    await _montar(tester, fake);
    await _escribir(tester, 'a3f9k2');

    final campo = tester.widget<TextFormField>(find.byKey(const Key('campo_codigo')));
    expect(campo.controller!.text, 'A3F9K2');

    await tester.tap(_boton);
    await tester.pumpAndSettle();
    expect(fake.codigoRecibido, 'A3F9K2');
  });

  testWidgets('código válido navega al dashboard', (tester) async {
    final fake = FakeHogarUnirse();
    await _montar(tester, fake);
    await _escribir(tester, 'A3F9K2');

    expect(_habilitado(tester), isTrue);
    await tester.tap(_boton);
    await tester.pumpAndSettle();

    expect(fake.llamadas, 1);
    expect(find.byType(DashboardScreen), findsOneWidget);
  });

  testWidgets('código inexistente muestra el mensaje claro', (tester) async {
    final fake = FakeHogarUnirse()
      ..error = const HogarException(HogarService.msgCodigoInvalido);
    await _montar(tester, fake);
    await _escribir(tester, 'ZZZZZZ');

    await tester.tap(_boton);
    await tester.pumpAndSettle();

    expect(find.text('Código inválido, verifica e intenta de nuevo'), findsOneWidget);
    expect(find.byType(UnirseHogarScreen), findsOneWidget);
  });

  testWidgets('si ya pertenece al hogar muestra el aviso y no navega', (tester) async {
    final fake = FakeHogarUnirse()
      ..error = const HogarException(HogarService.msgYaPerteneceEsteHogar);
    await _montar(tester, fake);
    await _escribir(tester, 'A3F9K2');

    await tester.tap(_boton);
    await tester.pumpAndSettle();

    expect(find.text('Ya perteneces a este hogar'), findsOneWidget);
    expect(find.byType(DashboardScreen), findsNothing);
  });

  testWidgets('mientras procesa muestra spinner y bloquea el botón', (tester) async {
    final fake = FakeHogarUnirse()..espera = Completer<String>();
    await _montar(tester, fake);
    await _escribir(tester, 'A3F9K2');

    await tester.tap(_boton);
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(_habilitado(tester), isFalse);
    expect(fake.llamadas, 1);

    fake.espera!.complete('hogar123');
    await tester.pumpAndSettle();
  });

  testWidgets('el enlace "Crea tu hogar" navega a #5', (tester) async {
    await _montar(tester, FakeHogarUnirse());
    await tester.tap(find.byKey(const Key('enlace_crear_hogar')));
    await tester.pumpAndSettle();
    expect(find.byType(CrearUnirseHogarScreen), findsOneWidget);
  });
}