import 'dart:async';

import 'package:easyhome/routes.dart';
import 'package:easyhome/screens/crear_unirse_hogar_screen.dart';
import 'package:easyhome/screens/dashboard_screen.dart';
import 'package:easyhome/screens/login_screen.dart';
import 'package:easyhome/screens/registro_screen.dart';
import 'package:easyhome/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Servicio falso: no toca Firebase.
class FakeAuthLogin extends AuthService {
  int llamadas = 0;
  String? hogarId;
  AuthException? error;
  Completer<String?>? espera;

  @override
  Future<String?> iniciarSesion({
    required String correo,
    required String contrasena,
  }) async {
    llamadas++;
    if (espera != null) return espera!.future;
    if (error != null) throw error!;
    return hogarId;
  }
}

Future<void> _montar(WidgetTester tester, FakeAuthLogin fake) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(MaterialApp(
    home: LoginScreen(authService: fake),
    routes: {
      AppRoutes.registro: (_) => const RegistroScreen(),
      AppRoutes.hogar: (_) => const CrearUnirseHogarScreen(),
      AppRoutes.dashboard: (_) => const DashboardScreen(),
    },
  ));
}

Future<void> _llenar(WidgetTester tester,
    {String correo = 'ana@correo.com', String pass = 'abc123'}) async {
  await tester.enterText(find.byKey(const Key('campo_correo')), correo);
  await tester.enterText(find.byKey(const Key('campo_contrasena')), pass);
  await tester.pump();
}

Finder get _boton => find.byKey(const Key('boton_iniciar_sesion'));
bool _habilitado(WidgetTester tester) =>
    tester.widget<FilledButton>(_boton).onPressed != null;

void main() {
  testWidgets('botón deshabilitado con campos vacíos', (tester) async {
    await _montar(tester, FakeAuthLogin());
    expect(_habilitado(tester), isFalse);
  });

  testWidgets('correo inválido muestra error y no llama al servicio', (tester) async {
    final fake = FakeAuthLogin();
    await _montar(tester, fake);
    await _llenar(tester, correo: 'algo@');

    expect(find.text('Correo inválido'), findsOneWidget);
    expect(_habilitado(tester), isFalse);
    expect(fake.llamadas, 0);
  });

  testWidgets('contraseña vacía muestra error y no llama al servicio', (tester) async {
    final fake = FakeAuthLogin();
    await _montar(tester, fake);
    await _llenar(tester, pass: 'x');
    await tester.enterText(find.byKey(const Key('campo_contrasena')), '');
    await tester.pump();

    expect(find.text('Ingresa tu contraseña'), findsOneWidget);
    expect(_habilitado(tester), isFalse);
    expect(fake.llamadas, 0);
  });

  testWidgets('credenciales incorrectas muestran el mensaje genérico', (tester) async {
    final fake = FakeAuthLogin()
      ..error = const AuthException(AuthService.msgCredencialesIncorrectas);
    await _montar(tester, fake);
    await _llenar(tester);

    await tester.tap(_boton);
    await tester.pumpAndSettle();

    expect(find.text('Correo o contraseña incorrectos'), findsOneWidget);
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('login sin hogar navega a Crear/Unirse a un hogar', (tester) async {
    final fake = FakeAuthLogin()..hogarId = null;
    await _montar(tester, fake);
    await _llenar(tester);

    await tester.tap(_boton);
    await tester.pumpAndSettle();

    expect(find.byType(CrearUnirseHogarScreen), findsOneWidget);
  });

  testWidgets('login con hogar navega al dashboard', (tester) async {
    final fake = FakeAuthLogin()..hogarId = 'hogar123';
    await _montar(tester, fake);
    await _llenar(tester);

    await tester.tap(_boton);
    await tester.pumpAndSettle();

    expect(find.byType(DashboardScreen), findsOneWidget);
  });

  testWidgets('mientras carga muestra spinner y bloquea el botón', (tester) async {
    final fake = FakeAuthLogin()..espera = Completer<String?>();
    await _montar(tester, fake);
    await _llenar(tester);

    await tester.tap(_boton);
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(_habilitado(tester), isFalse);
    expect(fake.llamadas, 1);

    fake.espera!.complete(null);
    await tester.pumpAndSettle();
  });

  testWidgets('"¿Olvidaste tu contraseña?" está deshabilitado', (tester) async {
    await _montar(tester, FakeAuthLogin());
    final boton = tester.widget<TextButton>(find.byKey(const Key('enlace_olvido')));
    expect(boton.onPressed, isNull);
  });

  testWidgets('el enlace "Regístrate" navega al registro', (tester) async {
    await _montar(tester, FakeAuthLogin());
    await tester.tap(find.byKey(const Key('enlace_registro')));
    await tester.pumpAndSettle();
    expect(find.byType(RegistroScreen), findsOneWidget);
  });
}