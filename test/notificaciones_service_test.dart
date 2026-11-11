import 'dart:async';
import 'package:easyhome/services/notificaciones_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeMessagingAdapter implements MessagingAdapter {
  AuthorizationStatus authorizationStatus = AuthorizationStatus.authorized;
  String? fakeToken = 'token_fcm_123';
  bool deleteTokenCalled = false;
  RemoteMessage? initialMessage;

  final tokenRefreshCtrl = StreamController<String>.broadcast();
  final messageCtrl = StreamController<RemoteMessage>.broadcast();
  final messageOpenedAppCtrl = StreamController<RemoteMessage>.broadcast();

  @override
  Future<NotificationSettings> requestPermission() async {
    return NotificationSettings(
      authorizationStatus: authorizationStatus,
      alert: AppleNotificationSetting.enabled,
      announcement: AppleNotificationSetting.disabled,
      badge: AppleNotificationSetting.enabled,
      carPlay: AppleNotificationSetting.disabled,
      criticalAlert: AppleNotificationSetting.disabled,
      sound: AppleNotificationSetting.enabled,
      lockScreen: AppleNotificationSetting.enabled,
      notificationCenter: AppleNotificationSetting.enabled,
      showPreviews: AppleShowPreviewSetting.always,
      timeSensitive: AppleNotificationSetting.disabled,
      providesAppNotificationSettings: AppleNotificationSetting.disabled,
    );
  }

  @override
  Future<String?> getToken({String? vapidKey}) async => fakeToken;

  @override
  Future<void> deleteToken() async {
    deleteTokenCalled = true;
    fakeToken = null;
  }

  @override
  Stream<String> get onTokenRefresh => tokenRefreshCtrl.stream;

  @override
  Stream<RemoteMessage> get onMessage => messageCtrl.stream;

  @override
  Stream<RemoteMessage> get onMessageOpenedApp => messageOpenedAppCtrl.stream;

  @override
  Future<RemoteMessage?> getInitialMessage() async => initialMessage;

  void dispose() {
    tokenRefreshCtrl.close();
    messageCtrl.close();
    messageOpenedAppCtrl.close();
  }
}

void main() {
  group('NotificacionesService Tests (#21)', () {
    late FakeMessagingAdapter fakeAdapter;
    String? tokenGuardadoEnFirestore;
    String? uidGuardado;
    bool tokenBorradoDeFirestore = false;

    setUp(() {
      fakeAdapter = FakeMessagingAdapter();
      tokenGuardadoEnFirestore = null;
      uidGuardado = null;
      tokenBorradoDeFirestore = false;
    });

    tearDown(() {
      fakeAdapter.dispose();
    });

    test('NotificacionesException almacena y devuelve mensaje en español', () {
      const ex = NotificacionesException('Error de prueba');
      expect(ex.mensaje, 'Error de prueba');
      expect(ex.toString(), 'Error de prueba');
    });

    test('inicializar con permiso concedido guarda token en Firestore y retorna token', () async {
      final service = NotificacionesService(
        messagingAdapter: fakeAdapter,
        onGuardarTokenFirestore: (uid, token) async {
          uidGuardado = uid;
          tokenGuardadoEnFirestore = token;
        },
      );

      final token = await service.inicializar('user_abc');

      expect(token, 'token_fcm_123');
      expect(service.tokenActual, 'token_fcm_123');
      expect(uidGuardado, 'user_abc');
      expect(tokenGuardadoEnFirestore, 'token_fcm_123');
    });

    test('inicializar con permiso denegado no guarda token ni lanza error', () async {
      fakeAdapter.authorizationStatus = AuthorizationStatus.denied;

      final service = NotificacionesService(
        messagingAdapter: fakeAdapter,
        onGuardarTokenFirestore: (uid, token) async {
          tokenGuardadoEnFirestore = token;
        },
      );

      final token = await service.inicializar('user_abc');

      expect(token, isNull);
      expect(service.tokenActual, isNull);
      expect(tokenGuardadoEnFirestore, isNull);
    });

    test('actualiza token en Firestore cuando se emite onTokenRefresh', () async {
      final service = NotificacionesService(
        messagingAdapter: fakeAdapter,
        onGuardarTokenFirestore: (uid, token) async {
          uidGuardado = uid;
          tokenGuardadoEnFirestore = token;
        },
      );

      await service.inicializar('user_abc');
      expect(tokenGuardadoEnFirestore, 'token_fcm_123');

      // Simular renovación de token
      fakeAdapter.tokenRefreshCtrl.add('token_renovado_456');
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(service.tokenActual, 'token_renovado_456');
      expect(tokenGuardadoEnFirestore, 'token_renovado_456');
    });

    test('limpiarToken borra token de Firestore, llama a deleteToken y cancela estado', () async {
      final service = NotificacionesService(
        messagingAdapter: fakeAdapter,
        onGuardarTokenFirestore: (uid, token) async {
          tokenGuardadoEnFirestore = token;
        },
        onBorrarTokenFirestore: (uid) async {
          tokenBorradoDeFirestore = true;
          tokenGuardadoEnFirestore = null;
        },
      );

      await service.inicializar('user_abc');
      expect(service.tokenActual, 'token_fcm_123');

      await service.limpiarToken('user_abc');

      expect(tokenBorradoDeFirestore, isTrue);
      expect(fakeAdapter.deleteTokenCalled, isTrue);
      expect(service.tokenActual, isNull);
    });

    test('mensajes en primer plano ejecutan callback onMensajeEnPrimerPlano', () async {
      RemoteMessage? mensajeRecibido;
      final service = NotificacionesService(
        messagingAdapter: fakeAdapter,
        onGuardarTokenFirestore: (uid, token) async {},
        onMensajeEnPrimerPlano: (msg) {
          mensajeRecibido = msg;
        },
      );

      await service.inicializar('user_abc');

      const msgTest = RemoteMessage(
        messageId: 'msg_001',
        data: {'seccion': 'compras', 'titulo': 'Producto nuevo'},
      );
      fakeAdapter.messageCtrl.add(msgTest);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(mensajeRecibido, isNotNull);
      expect(mensajeRecibido?.messageId, 'msg_001');
      expect(mensajeRecibido?.data['seccion'], 'compras');
    });

    test('toque en notificación en segundo plano ejecuta callback onToqueNotificacion', () async {
      RemoteMessage? mensajeTocado;
      final service = NotificacionesService(
        messagingAdapter: fakeAdapter,
        onGuardarTokenFirestore: (uid, token) async {},
        onToqueNotificacion: (msg) {
          mensajeTocado = msg;
        },
      );

      await service.inicializar('user_abc');

      const msgTest = RemoteMessage(
        messageId: 'msg_002',
        data: {'seccion': 'quehaceres'},
      );
      fakeAdapter.messageOpenedAppCtrl.add(msgTest);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(mensajeTocado, isNotNull);
      expect(mensajeTocado?.data['seccion'], 'quehaceres');
    });

    test('error de red o excepción interna es capturada sin romper la aplicación', () async {
      final fakeConError = _FakeAdapterConFallo();
      final service = NotificacionesService(
        messagingAdapter: fakeConError,
        onGuardarTokenFirestore: (uid, token) async {},
      );

      // No debe lanzar excepción
      final token = await service.inicializar('user_abc');
      expect(token, isNull);
    });
  });
}

class _FakeAdapterConFallo extends FakeMessagingAdapter {
  @override
  Future<NotificationSettings> requestPermission() async {
    throw Exception('Error de red al conectar con FCM');
  }
}
