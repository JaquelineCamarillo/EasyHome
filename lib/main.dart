import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'routes.dart';
import 'screens/crear_unirse_hogar_screen.dart';
import 'screens/login_screen.dart';
import 'screens/registro_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/unirse_hogar_screen.dart';
import 'screens/perfil_hogar_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint(
      '✅ Firebase conectado: ${Firebase.apps.length} app(s), proyecto: ${Firebase.apps.first.options.projectId}');
  runApp(const EasyHomeApp());
}

class EasyHomeApp extends StatelessWidget {
  const EasyHomeApp({super.key});

  @override
  Widget build(BuildContext context) {
    const verde = Color(0xFF2F5446);
    const crema = Color(0xFFEEE8DA);

    return MaterialApp(
      title: 'EasyHome',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: verde, primary: verde),
        scaffoldBackgroundColor: crema,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      // TODO: cuando exista el login, decidir aquí según FirebaseAuth.currentUser.
      initialRoute: AppRoutes.registro,
      routes: {
        AppRoutes.registro: (_) => const RegistroScreen(),
        AppRoutes.login: (_) => const LoginScreen(),
        AppRoutes.hogar: (_) => const CrearUnirseHogarScreen(),
        AppRoutes.dashboard: (_) => const DashboardScreen(),
        AppRoutes.unirseHogar: (_) => const UnirseHogarScreen(),
        AppRoutes.perfilHogar: (_) => const PerfilHogarScreen(),
      },
    );
  }
}