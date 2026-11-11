import 'package:easyhome/routes.dart';
import 'package:easyhome/screens/crear_unirse_hogar_screen.dart';
import 'package:easyhome/screens/login_screen.dart';
import 'package:easyhome/screens/registro_screen.dart';
import 'package:easyhome/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Servicio falso: no toca Firebase.
class FakeAuthService extends AuthService {
  int llamadas = 0;
  AuthException? error;

  @override
  Future<void> registrar({
    required String nombre,
    required String correo,
    required String contrasena,
  }) async {
    llamadas++;
    if (error != null) throw error!;
  }
}

Future<void> _montar(WidgetTester tester, FakeAuthService fake) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(MaterialApp(
    home: RegistroScreen(authService: fake),
    routes: {
      AppRoutes.login: (_) => const LoginScreen(),
      AppRoutes.hogar: (_) => const CrearUnirseHogarScreen(),
    },
  ));
}

Future<void> _llenar(WidgetTester tester,
    {String nombre = 'Ana Torres',
    String correo = 'ana@correo.com',
    String pass = '123456',
    String confirmar = '123456'}) async {
  await tester.enterText(find.byKey(const Key('campo_nombre')), nombre);
  await tester.enterText(find.byKey(const Key('campo_correo')), correo);
  await tester.enterText(find.byKey(const Key('campo_contrasena')), pass);
  await tester.enterText(find.widgetWithText(TextFormField, 'Confirmar contraseña'), confirmar);
  await tester.pump();
}

bool _botonHabilitado(WidgetTester tester) =>
    tester.widget<FilledButton>(find.byKey(const Key('boton_crear_cuenta'))).onPressed != null;

void main() {
  testWidgets('el botón está deshabilitado con campos vacíos', (tester) async {
    await _montar(tester, FakeAuthService());
    expect(_botonHabilitado(tester), isFalse);
  });

  testWidgets('correo inválido muestra error y no llama al servicio', (tester) async {
    final fake = FakeAuthService();
    await _montar(tester, fake);
    await _llenar(tester, correo: 'algo@');

    expect(find.text('Correo inválido'), findsOneWidget);
    expect(_botonHabilitado(tester), isFalse);
    expect(fake.llamadas, 0);
  });

  testWidgets('contraseña corta muestra error y no llama al servicio', (tester) async {
    final fake = FakeAuthService();
    await _montar(tester, fake);
    await _llenar(tester, pass: '123', confirmar: '123');

    expect(find.text('La contraseña debe tener al menos 6 caracteres'), findsOneWidget);
    expect(_botonHabilitado(tester), isFalse);
    expect(fake.llamadas, 0);
  });

  testWidgets('contraseñas distintas muestran error', (tester) async {
    final fake = FakeAuthService();
    await _montar(tester, fake);
    await _llenar(tester, confirmar: '654321');

    expect(find.text('Las contraseñas no coinciden'), findsOneWidget);
    expect(_botonHabilitado(tester), isFalse);
    expect(fake.llamadas, 0);
  });

  testWidgets('datos válidos llaman al servicio y navegan a Crear/Unirse hogar', (tester) async {
    final fake = FakeAuthService();
    await _montar(tester, fake);
    await _llenar(tester);

    expect(_botonHabilitado(tester), isTrue);
    await tester.tap(find.byKey(const Key('boton_crear_cuenta')));
    await tester.pumpAndSettle();

    expect(fake.llamadas, 1);
    expect(find.byType(CrearUnirseHogarScreen), findsOneWidget);
  });

  testWidgets('correo ya registrado muestra el mensaje traducido', (tester) async {
    final fake = FakeAuthService()
      ..error = const AuthException(AuthService.msgCorreoEnUso);
    await _montar(tester, fake);
    await _llenar(tester);

    await tester.tap(find.byKey(const Key('boton_crear_cuenta')));
    await tester.pumpAndSettle();

    expect(find.text('Este correo ya tiene una cuenta registrada'), findsOneWidget);
    expect(find.byType(RegistroScreen), findsOneWidget);
  });

  testWidgets('el enlace "Inicia sesión" navega al login', (tester) async {
    await _montar(tester, FakeAuthService());
    await tester.tap(find.byKey(const Key('enlace_login')));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
  });
}