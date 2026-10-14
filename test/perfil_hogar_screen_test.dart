import 'dart:async';

import 'package:easyhome/models/hogar.dart';
import 'package:easyhome/models/integrante.dart';
import 'package:easyhome/screens/perfil_hogar_screen.dart';
import 'package:easyhome/services/hogar_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

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

Future<FakePerfilService> _montar(WidgetTester tester, {String? hogarId = 'h1'}) async {
  final fake = FakePerfilService();
  addTearDown(fake.hogarCtrl.close);
  addTearDown(fake.integrantesCtrl.close);

  await tester.pumpWidget(MaterialApp(
    home: PerfilHogarScreen(hogarId: hogarId, hogarService: fake),
  ));
  return fake;
}

void main() {
  testWidgets('mientras carga muestra spinner, no una lista vacía', (tester) async {
    await _montar(tester);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Integrantes (0)'), findsNothing);
  });

  testWidgets('con el hogar cargado pero sin integrantes aún, spinner en la lista', (tester) async {
    final fake = await _montar(tester);
    fake.hogarCtrl.add(_hogar);
    await tester.pump();

    expect(find.text('Depa de Ana'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('muestra nombre del hogar, integrantes y distingue al admin', (tester) async {
    final fake = await _montar(tester);
    fake.hogarCtrl.add(_hogar);
    fake.integrantesCtrl.add([_ana, _luis, _marco]);
    await tester.pump();

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
    fake.hogarCtrl.add(_hogar);
    fake.integrantesCtrl.add([_ana]);
    await tester.pump();

    expect(find.text('Integrantes (1)'), findsOneWidget);
    expect(find.text('Ana'), findsOneWidget);
    expect(find.textContaining('No se pudo'), findsNothing);
  });

  testWidgets('se actualiza en tiempo real cuando alguien se une', (tester) async {
    final fake = await _montar(tester);
    fake.hogarCtrl.add(_hogar);
    fake.integrantesCtrl.add([_ana]);
    await tester.pump();
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
    fake.hogarCtrl.add(_hogar);
    fake.integrantesCtrl.add([_ana]);
    await tester.pump();

    expect(find.text('A3F9K2'), findsOneWidget);

    await tester.tap(find.byKey(const Key('boton_copiar')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(copiado, 'A3F9K2');
    expect(find.text('Código copiado'), findsOneWidget);
  });

  testWidgets('si no recibe hogarId lo obtiene del usuario actual', (tester) async {
    final fake = await _montar(tester, hogarId: null);
    fake.hogarIdActual = 'h99';
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
}