import 'dart:async';

import 'package:easyhome/models/hogar.dart';
import 'package:easyhome/models/integrante.dart';
import 'package:easyhome/screens/perfil_hogar_screen.dart';
import 'package:easyhome/services/hogar_service.dart';
import 'package:easyhome/services/usuario_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class FakePerfilUsuarioService extends UsuarioService {
  FakePerfilUsuarioService({super.usuarioActualId});
}

/// Servicio falso: los streams los controla la prueba.
class FakePerfilService extends HogarService {
  final hogarCtrl = StreamController<Hogar?>.broadcast();
  final integrantesCtrl = StreamController<List<Integrante>>.broadcast();
  String? hogarIdActual = 'h1';
  String? hogarIdPedido;

  @override
  Future<String?> obtenerHogarIdActual() async => hogarIdActual;

  @override
  Stream<Hogar?> observarHogar(String hogarId) {
    hogarIdPedido = hogarId;
    return hogarCtrl.stream;
  }

  @override
  Stream<List<Integrante>> observarIntegrantes(String hogarId) =>
      integrantesCtrl.stream;
}

const _hogar = Hogar(id: 'h1', nombre: 'Depa de Ana', codigoInvitacion: 'A3F9K2');
const _ana = Integrante(uid: '1', nombre: 'Ana', esAdministrador: true);
const _luis = Integrante(uid: '2', nombre: 'Luis', esAdministrador: false);
const _marco = Integrante(uid: '3', nombre: 'Marco', esAdministrador: false);

Future<FakePerfilService> _montar(
  WidgetTester tester, {
  String? hogarId = 'h1',
  String? hogarIdActual = 'h1',
  UsuarioService? usuarioService,
}) async {
  final fake = FakePerfilService()..hogarIdActual = hogarIdActual;
  addTearDown(fake.hogarCtrl.close);
  addTearDown(fake.integrantesCtrl.close);

  await tester.pumpWidget(MaterialApp(
    home: PerfilHogarScreen(
      hogarId: hogarId,
      hogarService: fake,
      usuarioService: usuarioService,
    ),
  ));
  return fake;
}

/// Emite primero el hogar y, ya con la lista construida (que recién entonces
/// se suscribe a los integrantes), emite los integrantes.
Future<void> _emitir(
  WidgetTester tester,
  FakePerfilService fake, {
  List<Integrante>? integrantes,
}) async {
  fake.hogarCtrl.add(_hogar);
  await tester.pump();
  if (integrantes != null) {
    fake.integrantesCtrl.add(integrantes);
    await tester.pump();
  }
}

void main() {
  testWidgets('mientras carga muestra spinner, no una lista vacía', (tester) async {
    await _montar(tester);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Integrantes (0)'), findsNothing);
  });

  testWidgets('con el hogar cargado pero sin integrantes aún, spinner en la lista', (tester) async {
    final fake = await _montar(tester);
    await _emitir(tester, fake);

    expect(find.text('Depa de Ana'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('muestra nombre del hogar, integrantes y distingue al admin', (tester) async {
    final fake = await _montar(tester);
    await _emitir(tester, fake, integrantes: [_ana, _luis, _marco]);

    expect(find.text('Depa de Ana'), findsOneWidget);
    expect(find.text('Integrantes (3)'), findsOneWidget);
    expect(find.text('Ana'), findsOneWidget);
    expect(find.text('Luis'), findsOneWidget);
    expect(find.text('Marco'), findsOneWidget);
    // Solo el administrador lleva etiqueta.
    expect(find.byKey(const Key('etiqueta_admin')), findsOneWidget);
    expect(find.text('Admin'), findsOneWidget);
  });

  testWidgets('si solo está el creador, muestra solo a esa persona sin error', (tester) async {
    final fake = await _montar(tester);
    await _emitir(tester, fake, integrantes: [_ana]);

    expect(find.text('Integrantes (1)'), findsOneWidget);
    expect(find.text('Ana'), findsOneWidget);
    expect(find.textContaining('No se pudo'), findsNothing);
  });

  testWidgets('se actualiza en tiempo real cuando alguien se une', (tester) async {
    final fake = await _montar(tester);
    await _emitir(tester, fake, integrantes: [_ana]);
    expect(find.text('Luis'), findsNothing);

    fake.integrantesCtrl.add([_ana, _luis]);
    await tester.pump();

    expect(find.text('Luis'), findsOneWidget);
    expect(find.text('Integrantes (2)'), findsOneWidget);
  });

  testWidgets('el código es visible y al copiar va al portapapeles con confirmación', (tester) async {
    String? copiado;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copiado = (call.arguments as Map)['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null));

    final fake = await _montar(tester);
    await _emitir(tester, fake, integrantes: [_ana]);

    expect(find.text('A3F9K2'), findsOneWidget);

    await tester.tap(find.byKey(const Key('boton_copiar')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(copiado, 'A3F9K2');
    expect(find.text('Código copiado'), findsOneWidget);
  });

  testWidgets('si no recibe hogarId lo obtiene del usuario actual', (tester) async {
    final fake = await _montar(tester, hogarId: null, hogarIdActual: 'h99');
    await tester.pump(); // resuelve el Future de obtenerHogarIdActual
    await tester.pump();

    expect(fake.hogarIdPedido, 'h99');
  });

  testWidgets('usuario sin hogar muestra un aviso', (tester) async {
    final fake = FakePerfilService()..hogarIdActual = null;
    addTearDown(fake.hogarCtrl.close);
    addTearDown(fake.integrantesCtrl.close);

    await tester.pumpWidget(MaterialApp(home: PerfilHogarScreen(hogarService: fake)));
    await tester.pump();
    await tester.pump();

    expect(find.text('Todavía no perteneces a ningún hogar'), findsOneWidget);
  });

  testWidgets('admin puede ver el correo del integrante en la lista y en el modal', (tester) async {
    const carlos = Integrante(
      uid: 'c1',
      nombre: 'Carlos',
      esAdministrador: false,
      correo: 'carlos@easyhome.test',
    );
    final userSvc = FakePerfilUsuarioService(usuarioActualId: '1'); // Ana es admin

    final fake = await _montar(tester, usuarioService: userSvc);
    await _emitir(tester, fake, integrantes: [_ana, carlos]);

    // Como admin, ve el correo de Carlos directamente en la tarjeta
    expect(find.byKey(const Key('correo_integrante_c1')), findsOneWidget);
    expect(find.text('carlos@easyhome.test'), findsOneWidget);

    // Al tocar la tarjeta, se abre el modal de perfil detallado
    await tester.tap(find.byKey(const Key('tile_integrante_c1')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('detalle_nombre_c1')), findsOneWidget);
    expect(find.byKey(const Key('detalle_correo_c1')), findsOneWidget);
    expect(find.text('carlos@easyhome.test'), findsWidgets);
    expect(find.text('Integrante'), findsWidgets);
  });

  testWidgets('no-admin no ve el correo de otros integrantes (protección de privacidad)', (tester) async {
    const carlos = Integrante(
      uid: 'c1',
      nombre: 'Carlos',
      esAdministrador: false,
      correo: 'carlos@easyhome.test',
    );
    // Usuario actual es Luis ('2'), que no es admin
    final userSvc = FakePerfilUsuarioService(usuarioActualId: '2');

    final fake = await _montar(tester, usuarioService: userSvc);
    await _emitir(tester, fake, integrantes: [_ana, _luis, carlos]);

    // No ve el correo en la tarjeta
    expect(find.byKey(const Key('correo_integrante_c1')), findsNothing);

    // Al abrir el modal, el correo está oculto
    await tester.tap(find.byKey(const Key('tile_integrante_c1')));
    await tester.pumpAndSettle();

    expect(find.text('Visible solo para administradores'), findsOneWidget);
    expect(find.text('carlos@easyhome.test'), findsNothing);
  });
}