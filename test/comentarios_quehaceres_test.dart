import 'dart:async';

import 'package:easyhome/models/comentario.dart';
import 'package:easyhome/models/quehacer.dart';
import 'package:easyhome/screens/detalle_quehacer_modal.dart';
import 'package:easyhome/services/quehaceres_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeQuehaceresComentariosService extends QuehaceresService {
  final Map<String, List<Comentario>> _comentariosPorQuehacer = {};
  final Map<String, StreamController<List<Comentario>>> _controllers = {};

  void seedComentarios(String quehacerId, List<Comentario> comentarios) {
    _comentariosPorQuehacer[quehacerId] = List.from(comentarios);
    _controllers[quehacerId]?.add(List.from(comentarios));
  }

  @override
  Stream<List<Comentario>> observarComentarios(String quehacerId) {
    final controller = _controllers.putIfAbsent(
      quehacerId,
      () => StreamController<List<Comentario>>.broadcast(),
    );
    final actual = _comentariosPorQuehacer[quehacerId] ?? [];
    scheduleMicrotask(() {
      if (!controller.isClosed) {
        controller.add(List.from(actual));
      }
    });
    return controller.stream;
  }

  @override
  Future<String> agregarComentario({
    required String quehacerId,
    required String texto,
    String? autorNombre,
  }) async {
    final textoLimpio = texto.trim();
    if (textoLimpio.isEmpty) {
      throw const QuehaceresException(QuehaceresService.msgComentarioVacio);
    }
    if (textoLimpio.length > 300) {
      throw const QuehaceresException(QuehaceresService.msgComentarioLargo);
    }

    final lista = _comentariosPorQuehacer.putIfAbsent(quehacerId, () => []);
    final id = 'comentario_${lista.length + 1}';
    final nuevo = Comentario(
      id: id,
      quehacerId: quehacerId,
      autorId: 'uid_test',
      autorNombre: autorNombre ?? 'Usuario Test',
      texto: textoLimpio,
      creadoEn: DateTime.now(),
    );
    lista.add(nuevo);

    _controllers[quehacerId]?.add(List.from(lista));
    return id;
  }
}

void main() {
  group('Requerimiento 1: Comentarios en los quehaceres', () {
    late FakeQuehaceresComentariosService fakeService;
    late Quehacer quehacerEjemplo;

    setUp(() {
      fakeService = FakeQuehaceresComentariosService();
      quehacerEjemplo = Quehacer(
        id: 'q_123',
        hogarId: 'hogar_1',
        titulo: 'Lavar los trastes',
        asignadoA: 'uid_test',
        hecho: false,
        creadoPor: 'uid_admin',
        recurrente: true,
      );
    });

    test('Modelo Comentario serializa y deserializa correctamente', () {
      final ahora = DateTime(2026, 11, 16, 14, 30);
      final json = {
        'autorId': 'user_abc',
        'autorNombre': 'Carlos Perez',
        'texto': 'Ya casi termino los platos',
        'creadoEn': ahora.toIso8601String(),
      };

      final comentario = Comentario.fromMap('c_1', 'q_123', json);
      expect(comentario.id, 'c_1');
      expect(comentario.quehacerId, 'q_123');
      expect(comentario.autorId, 'user_abc');
      expect(comentario.autorNombre, 'Carlos Perez');
      expect(comentario.texto, 'Ya casi termino los platos');
      expect(comentario.creadoEn, isNotNull);

      final toMap = comentario.toMap();
      expect(toMap['autorId'], 'user_abc');
      expect(toMap['autorNombre'], 'Carlos Perez');
      expect(toMap['texto'], 'Ya casi termino los platos');
    });

    test('Validación de longitud: texto de 1 a 300 caracteres', () async {
      // Vacío debe fallar
      expect(
        () => fakeService.agregarComentario(
          quehacerId: 'q_123',
          texto: '   ',
        ),
        throwsA(isA<QuehaceresException>().having(
          (e) => e.mensaje,
          'mensaje',
          QuehaceresService.msgComentarioVacio,
        )),
      );

      // Mayor a 300 debe fallar
      final textoMuyLargo = 'a' * 301;
      expect(
        () => fakeService.agregarComentario(
          quehacerId: 'q_123',
          texto: textoMuyLargo,
        ),
        throwsA(isA<QuehaceresException>().having(
          (e) => e.mensaje,
          'mensaje',
          QuehaceresService.msgComentarioLargo,
        )),
      );

      // Texto de 1 y 300 caracteres debe ser exitoso
      final id1 = await fakeService.agregarComentario(
        quehacerId: 'q_123',
        texto: 'x',
      );
      expect(id1, isNotEmpty);

      final id300 = await fakeService.agregarComentario(
        quehacerId: 'q_123',
        texto: 'a' * 300,
      );
      expect(id300, isNotEmpty);
    });

    testWidgets('Muestra estado vacío cuando no hay comentarios',
        (tester) async {
      fakeService.seedComentarios('q_123', []);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => DetalleQuehacerModal.mostrar(
                  context: ctx,
                  quehacer: quehacerEjemplo,
                  responsableNombre: 'Ana Lopez',
                  quehaceresService: fakeService,
                  usuarioActualNombre: 'Carlos',
                ),
                child: const Text('Abrir'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Abrir'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byKey(const Key('detalle_titulo_quehacer')), findsOneWidget);
      expect(find.text('Lavar los trastes'), findsOneWidget);
      expect(find.text('Ana Lopez'), findsOneWidget);
      expect(find.byKey(const Key('estado_vacio_comentarios')), findsOneWidget);
      expect(find.text('No hay comentarios aún'), findsOneWidget);
    });

    testWidgets(
        'Muestra comentarios en orden cronológico con autor y fecha/hora formateada',
        (tester) async {
      final c1 = Comentario(
        id: 'c_1',
        quehacerId: 'q_123',
        autorId: 'u_1',
        autorNombre: 'Ana Lopez',
        texto: 'Primer aviso: no hay jabón',
        creadoEn: DateTime(2026, 11, 16, 9, 30),
      );
      final c2 = Comentario(
        id: 'c_2',
        quehacerId: 'q_123',
        autorId: 'u_2',
        autorNombre: 'Carlos Ruiz',
        texto: 'Segundo aviso: ya compré jabón',
        creadoEn: DateTime(2026, 11, 16, 10, 15),
      );

      fakeService.seedComentarios('q_123', [c1, c2]);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => DetalleQuehacerModal.mostrar(
                  context: ctx,
                  quehacer: quehacerEjemplo,
                  responsableNombre: 'Ana Lopez',
                  quehaceresService: fakeService,
                  usuarioActualNombre: 'Carlos Ruiz',
                ),
                child: const Text('Abrir'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Abrir'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Verificar que ambos comentarios están en pantalla con autor y fecha/hora
      expect(find.byKey(const Key('item_comentario_c_1')), findsOneWidget);
      expect(find.byKey(const Key('item_comentario_c_2')), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('item_comentario_c_1')),
          matching: find.text('Ana Lopez'),
        ),
        findsOneWidget,
      );
      expect(find.text('Primer aviso: no hay jabón'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('item_comentario_c_2')),
          matching: find.text('Carlos Ruiz'),
        ),
        findsOneWidget,
      );
      expect(find.text('Segundo aviso: ya compré jabón'), findsOneWidget);
      expect(find.text('16/11/2026, 09:30'), findsOneWidget);
      expect(find.text('16/11/2026, 10:15'), findsOneWidget);

      // Verificar orden cronológico: c1 antes que c2 en el árbol visual
      final pos1 = tester.getTopLeft(find.byKey(const Key('item_comentario_c_1')));
      final pos2 = tester.getTopLeft(find.byKey(const Key('item_comentario_c_2')));
      expect(pos1.dy, lessThan(pos2.dy));
    });

    testWidgets('Cualquier integrante puede enviar un comentario válido',
        (tester) async {
      fakeService.seedComentarios('q_123', []);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => DetalleQuehacerModal.mostrar(
                  context: ctx,
                  quehacer: quehacerEjemplo,
                  responsableNombre: 'Ana Lopez',
                  quehaceresService: fakeService,
                  usuarioActualNombre: 'Luis Gómez',
                ),
                child: const Text('Abrir'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Abrir'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Intentar enviar vacío muestra error inline
      await tester.tap(find.byKey(const Key('boton_enviar_comentario')));
      await tester.pump();
      expect(find.text(QuehaceresService.msgComentarioVacio), findsOneWidget);

      // Escribir texto válido
      await tester.enterText(
        find.byKey(const Key('campo_comentario')),
        'Por favor recuerden secar la barra',
      );
      await tester.pump();

      // Enviar
      await tester.tap(find.byKey(const Key('boton_enviar_comentario')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Verificar que se agregó y el campo se limpió
      final agregados = fakeService._comentariosPorQuehacer['q_123'] ?? [];
      expect(agregados.length, 1);
      expect(agregados.first.texto, 'Por favor recuerden secar la barra');
      expect(agregados.first.autorNombre, 'Luis Gómez');

      // Comentario visible de inmediato en tiempo real
      expect(find.text('Por favor recuerden secar la barra'), findsOneWidget);
    });
  });
}
