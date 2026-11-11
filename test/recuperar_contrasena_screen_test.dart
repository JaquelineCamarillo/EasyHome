import 'dart:async';

import 'package:easyhome/routes.dart';
import 'package:easyhome/screens/login_screen.dart';
import 'package:easyhome/screens/recuperar_contrasena_screen.dart';
import 'package:easyhome/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeAuthRecuperar extends AuthService {
  int llamadas = 0;
  String? correoRecibido;
  AuthException? error;
  Completer<void>? espera;

  @override
  Future<void> recuperarContrasena(String correo) async {
    llamadas++;
    correoRecibido = correo;
    if (espera != null) return espera!.future;
    if (error != null) throw error!;
  }
}

Future<void> _montar(WidgetTester tester, FakeAuthRecuperar fake) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(MaterialApp(
    home: RecuperarContrasenaScreen(authService: fake),
    routes: {
      AppRoutes.login: (_) => const LoginScreen(),
    },
  ));
}

Finder get _boton => find.byKey(const Key('boton_enviar_recuperacion'));
bool _habilitado(WidgetTester tester) =>
    tester.widget<FilledButton>(_boton).onPressed != null;

void main() {
  testWidgets('botón deshabilitado con correo vacío o inválido', (tester) async {
    final fake = FakeAuthRecuperar();
    await _montar(tester, fake);

    expect(_habilitado(tester), isFalse);

    await tester.enterText(
        find.byKey(const Key('campo_correo_recuperar')), 'invalido');
    await tester.pump();
    expect(find.text('Correo inválido'), findsOneWidget);
    expect(_habilitado(tester), isFalse);
    expect(fake.llamadas, 0);
  });

  testWidgets('correo válido habilita botón y envía solicitud', (tester) async {
    final fake = FakeAuthRecuperar();
    await _montar(tester, fake);

    await tester.enterText(
        find.byKey(const Key('campo_correo_recuperar')), 'ana@correo.com');
    await tester.pump();

    expect(_habilitado(tester), isTrue);
    await tester.tap(_boton);
    await tester.pumpAndSettle();

    expect(fake.llamadas, 1);
    expect(fake.correoRecibido, 'ana@correo.com');
    expect(find.text(AuthService.msgRecuperacionEnviada), findsAtLeastNWidgets(1));
  });

  testWidgets('muestra error si el servicio lanza AuthException', (tester) async {
    final fake = FakeAuthRecuperar()
      ..error = const AuthException(AuthService.msgSinConexion);
    await _montar(tester, fake);

    await tester.enterText(
        find.byKey(const Key('campo_correo_recuperar')), 'ana@correo.com');
    await tester.pump();

    await tester.tap(_boton);
    await tester.pumpAndSettle();

    expect(find.text(AuthService.msgSinConexion), findsOneWidget);
  });

  testWidgets('muestra spinner mientras se envía la petición', (tester) async {
    final fake = FakeAuthRecuperar()..espera = Completer<void>();
    await _montar(tester, fake);

    await tester.enterText(
        find.byKey(const Key('campo_correo_recuperar')), 'ana@correo.com');
    await tester.pump();

    await tester.tap(_boton);
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(_habilitado(tester), isFalse);

    fake.espera!.complete();
    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('enlace volver navega a login', (tester) async {
    final fake = FakeAuthRecuperar();
    await _montar(tester, fake);

    await tester.tap(find.byKey(const Key('enlace_volver_login')));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
  });
}
