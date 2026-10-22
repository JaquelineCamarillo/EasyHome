import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'routes.dart';
import 'screens/agregar_producto_screen.dart';
import 'screens/crear_unirse_hogar_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/editar_perfil_screen.dart';
import 'screens/login_screen.dart';
import 'screens/perfil_hogar_screen.dart';
import 'screens/registro_screen.dart';
import 'screens/unirse_hogar_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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
    const verdePrincipal = Color(0xFF234E3F);
    const cremaFondo = Color(0xFFF7F5EE);

    return MaterialApp(
      title: 'EasyHome',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: verdePrincipal,
          primary: verdePrincipal,
          surface: Colors.white,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: cremaFondo,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          scrolledUnderElevation: 0,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Color(0xFF1E2D27),
            fontSize: 19,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.3,
          ),
          iconTheme: IconThemeData(color: verdePrincipal),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFE8E4DA), width: 1),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          hintStyle: const TextStyle(color: Colors.black38, fontSize: 14),
          labelStyle: const TextStyle(color: Colors.black54, fontSize: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE3DFD5), width: 1.2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE3DFD5), width: 1.2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: verdePrincipal, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Colors.redAccent, width: 1.2),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Colors.redAccent, width: 2),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: verdePrincipal,
            foregroundColor: Colors.white,
            elevation: 1,
            shadowColor: verdePrincipal.withValues(alpha: 0.25),
            minimumSize: const Size.fromHeight(50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
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
      },
    );
  }
}
