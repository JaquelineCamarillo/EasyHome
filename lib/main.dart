import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'routes.dart';
import 'theme/app_theme.dart';
import 'screens/agregar_producto_screen.dart';
import 'screens/agregar_quehacer_screen.dart';
import 'screens/crear_unirse_hogar_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/editar_perfil_screen.dart';
import 'screens/login_screen.dart';
import 'screens/perfil_hogar_screen.dart';
import 'screens/registro_screen.dart';
import 'screens/unirse_hogar_screen.dart';

/// Handler de nivel superior para notificaciones en segundo plano (#21)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (_) {}
  debugPrint('Notificación push en segundo plano recibida: ${message.messageId}');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  debugPrint(
      '✅ Firebase conectado: ${Firebase.apps.length} app(s), proyecto: ${Firebase.apps.first.options.projectId}');

  final usuarioActual = FirebaseAuth.instance.currentUser;
  final rutaInicial =
      usuarioActual != null ? AppRoutes.dashboard : AppRoutes.registro;

  runApp(EasyHomeApp(initialRoute: rutaInicial));
}

class EasyHomeApp extends StatelessWidget {
  const EasyHomeApp({super.key, this.initialRoute = AppRoutes.registro});

  final String initialRoute;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EasyHome',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.tema,
      initialRoute: initialRoute,
      routes: {
        AppRoutes.registro: (_) => const RegistroScreen(),
        AppRoutes.login: (_) => const LoginScreen(),
        AppRoutes.hogar: (_) => const CrearUnirseHogarScreen(),
        AppRoutes.dashboard: (_) => const DashboardScreen(),
        AppRoutes.unirseHogar: (_) => const UnirseHogarScreen(),
        AppRoutes.perfilHogar: (_) => const PerfilHogarScreen(),
        AppRoutes.editarPerfil: (_) => const EditarPerfilScreen(),
        AppRoutes.agregarProducto: (_) => const AgregarProductoScreen(),
        AppRoutes.agregarQuehacer: (_) => const AgregarQuehacerScreen(),
      },
    );
  }
}
