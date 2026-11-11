import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Excepción en español para operaciones de notificaciones.
class NotificacionesException implements Exception {
  const NotificacionesException(this.mensaje);
  final String mensaje;

  @override
  String toString() => mensaje;
}

/// Adaptador para abstraer FirebaseMessaging y permitir pruebas sin Firebase real.
abstract class MessagingAdapter {
  Future<NotificationSettings> requestPermission();
  Future<String?> getToken({String? vapidKey});
  Future<void> deleteToken();
  Stream<String> get onTokenRefresh;
  Stream<RemoteMessage> get onMessage;
  Stream<RemoteMessage> get onMessageOpenedApp;
  Future<RemoteMessage?> getInitialMessage();
}

/// Implementación real que se apoya en FirebaseMessaging.instance.
class DefaultMessagingAdapter implements MessagingAdapter {
  DefaultMessagingAdapter([FirebaseMessaging? messaging])
      : _messaging = messaging ?? FirebaseMessaging.instance;

  final FirebaseMessaging _messaging;

  @override
  Future<NotificationSettings> requestPermission() {
    return _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
    );
  }

  @override
  Future<String?> getToken({String? vapidKey}) {
    return _messaging.getToken(vapidKey: vapidKey);
  }

  @override
  Future<void> deleteToken() {
    return _messaging.deleteToken();
  }

  @override
  Stream<String> get onTokenRefresh => FirebaseMessaging.instance.onTokenRefresh;

  @override
  Stream<RemoteMessage> get onMessage => FirebaseMessaging.onMessage;

  @override
  Stream<RemoteMessage> get onMessageOpenedApp => FirebaseMessaging.onMessageOpenedApp;

  @override
  Future<RemoteMessage?> getInitialMessage() => _messaging.getInitialMessage();
}

/// Callback para cuando se recibe un mensaje o se toca una notificación.
typedef MensajeNotificacionCallback = void Function(RemoteMessage mensaje);

/// Servicio inyectable para gestión de notificaciones push (FCM) y tokens.
class NotificacionesService {
  NotificacionesService({
    MessagingAdapter? messagingAdapter,
    FirebaseFirestore? firestore,
    this.onGuardarTokenFirestore,
    this.onBorrarTokenFirestore,
    this.onMensajeEnPrimerPlano,
    this.onToqueNotificacion,
  })  : _adapter = messagingAdapter,
        _firestoreOverride = firestore;

  final MessagingAdapter? _adapter;
  final FirebaseFirestore? _firestoreOverride;

  final Future<void> Function(String uid, String token)? onGuardarTokenFirestore;
  final Future<void> Function(String uid)? onBorrarTokenFirestore;

  MessagingAdapter get _messaging => _adapter ?? DefaultMessagingAdapter();
  FirebaseFirestore get _db => _firestoreOverride ?? FirebaseFirestore.instance;

  MensajeNotificacionCallback? onMensajeEnPrimerPlano;
  MensajeNotificacionCallback? onToqueNotificacion;

  StreamSubscription<String>? _tokenRefreshSub;
  StreamSubscription<RemoteMessage>? _onMessageSub;
  StreamSubscription<RemoteMessage>? _onMessageOpenedAppSub;

  String? _tokenActual;
  String? get tokenActual => _tokenActual;

  static const msgPermisoDenegado = 'Permiso de notificaciones denegado';
  static const msgErrorGuardarToken = 'No se pudo guardar el token de notificación';
  static const msgErrorLimpiarToken = 'No se pudo limpiar el token de notificación';

  /// Inicializa las notificaciones para el usuario autenticado:
  /// 1. Pide permisos (Android 13+ POST_NOTIFICATIONS, iOS, Web).
  /// 2. Si es autorizado, obtiene el token FCM.
  /// 3. Guarda el token en `usuarios/{uid}.fcmToken`.
  /// 4. Escucha renovaciones de token con `onTokenRefresh`.
  /// 5. Registra listeners de mensajes en primer plano y toques.
  Future<String?> inicializar(String uid) async {
    if (uid.trim().isEmpty) return null;

    try {
      final settings = await _messaging.requestPermission();
      final autorizado = settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;

      if (!autorizado) {
        debugPrint('Notificaciones: Permiso no autorizado (${settings.authorizationStatus})');
        return null;
      }

      // Clave VAPID para web desde entorno
      const vapidKeyEnv = String.fromEnvironment('FCM_VAPID_KEY', defaultValue: '');
      final vapidKey = vapidKeyEnv.isNotEmpty ? vapidKeyEnv : null;

      final token = await _messaging.getToken(vapidKey: vapidKey);
      if (token != null && token.isNotEmpty) {
        _tokenActual = token;
        await _guardarTokenEnFirestore(uid, token);
      }

      // Escuchar renovaciones de token
      await _tokenRefreshSub?.cancel();
      _tokenRefreshSub = _messaging.onTokenRefresh.listen((nuevoToken) async {
        if (nuevoToken.isNotEmpty) {
          _tokenActual = nuevoToken;
          try {
            await _guardarTokenEnFirestore(uid, nuevoToken);
          } catch (e) {
            debugPrint('Notificaciones: Error al actualizar token refrescado: $e');
          }
        }
      });

      // Escuchar mensajes en primer plano
      await _onMessageSub?.cancel();
      _onMessageSub = _messaging.onMessage.listen((mensaje) {
        debugPrint('Notificaciones: Mensaje recibido en primer plano: ${mensaje.messageId}');
        onMensajeEnPrimerPlano?.call(mensaje);
      });

      // Escuchar toques en notificación mientras la app está en segundo plano
      await _onMessageOpenedAppSub?.cancel();
      _onMessageOpenedAppSub = _messaging.onMessageOpenedApp.listen((mensaje) {
        debugPrint('Notificaciones: Toque en notificación desde segundo plano: ${mensaje.messageId}');
        onToqueNotificacion?.call(mensaje);
      });

      // Revisar si la app fue abierta desde estado terminado/cerrado por una notificación
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('Notificaciones: App abierta desde notificación cerrada: ${initialMessage.messageId}');
        onToqueNotificacion?.call(initialMessage);
      }

      return token;
    } catch (e) {
      debugPrint('Notificaciones: Error no fatal en inicializar: $e');
      // No debe romper la app
      return null;
    }
  }

  /// Borra el token FCM de Firestore y de FirebaseMessaging al cerrar sesión.
  Future<void> limpiarToken(String uid) async {
    // Cancelar suscripciones activas
    await _tokenRefreshSub?.cancel();
    _tokenRefreshSub = null;
    await _onMessageSub?.cancel();
    _onMessageSub = null;
    await _onMessageOpenedAppSub?.cancel();
    _onMessageOpenedAppSub = null;

    if (uid.trim().isNotEmpty) {
      if (onBorrarTokenFirestore != null) {
        try {
          await onBorrarTokenFirestore!(uid);
        } catch (e) {
          debugPrint('Notificaciones: Error al borrar token de Firestore (custom): $e');
        }
      } else {
        try {
          await _db.collection('usuarios').doc(uid).update({
            'fcmToken': FieldValue.delete(),
          });
        } catch (e) {
          debugPrint('Notificaciones: Error al borrar token de Firestore: $e');
        }
      }
    }

    try {
      await _messaging.deleteToken();
    } catch (e) {
      debugPrint('Notificaciones: Error al invocar deleteToken(): $e');
    }

    _tokenActual = null;
  }

  Future<void> _guardarTokenEnFirestore(String uid, String token) async {
    if (onGuardarTokenFirestore != null) {
      await onGuardarTokenFirestore!(uid, token);
      return;
    }

    try {
      await _db.collection('usuarios').doc(uid).set({
        'fcmToken': token,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Notificaciones: Error al guardar token en usuarios/$uid: $e');
    }
  }

  void dispose() {
    _tokenRefreshSub?.cancel();
    _onMessageSub?.cancel();
    _onMessageOpenedAppSub?.cancel();
  }
}
