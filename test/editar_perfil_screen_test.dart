import 'package:easyhome/models/usuario.dart';
import 'package:easyhome/screens/editar_perfil_screen.dart';
import 'package:easyhome/services/usuario_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeUsuarioService extends UsuarioService {
  String? nombreActualizado;
  String? avatarColorActualizado;
  String? passActualEnviada;
  String? passNuevaEnviada;
  bool salioDelHogar = false;

  @override
  Future<void> actualizarNombre(String nuevoNombre) async {
    nombreActualizado = nuevoNombre;
  }

  @override
  Future<void> actualizarAvatarColor(String colorHex) async {
    avatarColorActualizado = colorHex;
  }

  @override
  Future<void> cambiarContrasena({
    required String contrasenaActual,
    required String nuevaContrasena,
  }) async {
    passActualEnviada = contrasenaActual;
    passNuevaEnviada = nuevaContrasena;
  }

  @override
  Future<void> salirDelHogar() async {
    salioDelHogar = true;
  }
}

const _usuarioPrueba = Usuario(
  uid: 'u123',
  nombre: 'Carlos Mendoza',
  correo: 'carlos@example.com',
  esAdministrador: true,
  hogarId: 'hogar1',
  avatarColor: '0xFF1E4D3E',
);

Future<void> _montar(
  WidgetTester tester, {
  required FakeUsuarioService fakeService,
  Usuario? usuario = _usuarioPrueba,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      routes: {
        '/hogar': (_) => const Scaffold(body: Text('Pantalla Hogar')),
      },
      home: EditarPerfilScreen(
        usuarioService: fakeService,
        usuarioInicial: usuario,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('EditarPerfilScreen Tests', () {
    late FakeUsuarioService fake;

    setUp(() {
      fake = FakeUsuarioService();
    });

    testWidgets('Muestra los datos del perfil y badge de rol correctamente',
        (tester) async {
      await _montar(tester, fakeService: fake);

      expect(find.text('Mi Perfil'), findsOneWidget);
      expect(find.text('Carlos Mendoza'), findsOneWidget);
      expect(find.text('carlos@example.com'), findsOneWidget);
      expect(find.text('Administrador del hogar'), findsOneWidget);
      expect(find.text('El correo no se puede modificar'), findsOneWidget);
    });

    testWidgets('Validación de nombre vacío no permite guardar',
        (tester) async {
      await _montar(tester, fakeService: fake);

      final campoNombre = find.byKey(const Key('campo_editar_nombre'));
      await tester.enterText(campoNombre, '');
      await tester.tap(find.byKey(const Key('boton_guardar_nombre')));
      await tester.pump();

      expect(find.text('Ingresa tu nombre'), findsOneWidget);
      expect(fake.nombreActualizado, isNull);
    });

    testWidgets('Guardar nombre válido llama al servicio', (tester) async {
      await _montar(tester, fakeService: fake);

      final campoNombre = find.byKey(const Key('campo_editar_nombre'));
      await tester.enterText(campoNombre, 'Carlos Antonio');
      await tester.tap(find.byKey(const Key('boton_guardar_nombre')));
      await tester.pumpAndSettle();

      expect(fake.nombreActualizado, 'Carlos Antonio');
      expect(find.text('Nombre actualizado con éxito'), findsOneWidget);
    });

    testWidgets('Seleccionar color de paleta actualiza avatarColor',
        (tester) async {
      await _montar(tester, fakeService: fake);

      // Encontrar las opciones de la paleta InkWell
      final colores = find.byType(InkWell);
      expect(colores, findsWidgets);

      await tester.tap(colores.at(2)); // Clic en el tercer color
      await tester.pumpAndSettle();

      expect(fake.avatarColorActualizado, isNotNull);
      expect(find.text('Color de perfil guardado'), findsOneWidget);
    });

    testWidgets('Modal de cambio de contraseña valida y actualiza',
        (tester) async {
      await _montar(tester, fakeService: fake);

      final botonModal = find.byKey(const Key('boton_modal_cambiar_pass'));
      await tester.ensureVisible(botonModal);
      await tester.pumpAndSettle();

      await tester.tap(botonModal);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('boton_confirmar_pass')), findsOneWidget);

      // Intentar confirmar vacío
      await tester.tap(find.byKey(const Key('boton_confirmar_pass')));
      await tester.pump();

      expect(find.text('Ingresa tu contraseña'), findsOneWidget);

      // Ingresar contraseñas
      await tester.enterText(find.byKey(const Key('campo_pass_actual')), '123456');
      await tester.enterText(find.byKey(const Key('campo_pass_nueva')), 'nuevaSegura123');
      await tester.pump();

      await tester.tap(find.byKey(const Key('boton_confirmar_pass')));
      await tester.pumpAndSettle();

      expect(fake.passActualEnviada, '123456');
      expect(fake.passNuevaEnviada, 'nuevaSegura123');
      expect(find.text('Contraseña actualizada con éxito'), findsOneWidget);
    });

    testWidgets('Diálogo para salir del hogar confirma la acción',
        (tester) async {
      await _montar(tester, fakeService: fake);

      final botonSalir = find.byKey(const Key('boton_salir_hogar'));
      await tester.ensureVisible(botonSalir);
      await tester.pumpAndSettle();

      await tester.tap(botonSalir);
      await tester.pumpAndSettle();

      expect(find.text('Salir del hogar'), findsOneWidget);
      expect(
        find.textContaining('¿Estás seguro de que deseas desvincularte'),
        findsOneWidget,
      );

      // Confirmar
      await tester.tap(find.text('Sí, salir del hogar'));
      await tester.pumpAndSettle();

      expect(fake.salioDelHogar, isTrue);
    });
  });
}
