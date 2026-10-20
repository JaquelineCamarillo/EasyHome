import 'package:flutter/material.dart';

import '../routes.dart';
import '../services/auth_service.dart';
import '../utils/validators.dart';

/// Pantalla #4 — Inicio de sesión.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.authService});

  /// Inyectable para pruebas; por defecto usa Firebase real.
  final AuthService? authService;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _correoCtrl = TextEditingController();
  final _contrasenaCtrl = TextEditingController();

  late final AuthService _auth = widget.authService ?? AuthService();

  bool _ocultarContrasena = true;
  bool _cargando = false;
  String? _errorGeneral;

  bool get _formularioValido =>
      Validators.correo(_correoCtrl.text) == null &&
      Validators.contrasenaNoVacia(_contrasenaCtrl.text) == null;

  @override
  void dispose() {
    _correoCtrl.dispose();
    _contrasenaCtrl.dispose();
    super.dispose();
  }

  void _alCambiar() => setState(() => _errorGeneral = null);

  Future<void> _iniciarSesion() async {
    if (!_formularioValido || _cargando) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _cargando = true;
      _errorGeneral = null;
    });

    try {
      final hogarId = await _auth.iniciarSesion(
        correo: _correoCtrl.text,
        contrasena: _contrasenaCtrl.text,
      );
      if (!mounted) return;
      // Sin hogar => Crear/Unirse a un hogar; con hogar => dashboard.
      final destino = hogarId == null ? AppRoutes.hogar : AppRoutes.dashboard;
      Navigator.of(context).pushReplacementNamed(destino);
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorGeneral = e.mensaje;
        _cargando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(Icons.home_rounded,
                      size: 56, color: tema.colorScheme.primary),
                  const SizedBox(height: 8),
                  Text(
                    'EasyHome',
                    textAlign: TextAlign.center,
                    style: tema.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: tema.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Organiza tu hogar, comparte la carga.',
                    textAlign: TextAlign.center,
                    style: tema.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    key: const Key('campo_correo'),
                    controller: _correoCtrl,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                    decoration:
                        const InputDecoration(labelText: 'Correo electrónico'),
                    validator: Validators.correo,
                    onChanged: (_) => _alCambiar(),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const Key('campo_contrasena'),
                    controller: _contrasenaCtrl,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    obscureText: _ocultarContrasena,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.password],
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      suffixIcon: IconButton(
                        key: const Key('boton_mostrar_contrasena'),
                        tooltip: _ocultarContrasena
                            ? 'Mostrar contraseña'
                            : 'Ocultar contraseña',
                        icon: Icon(_ocultarContrasena
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined),
                        onPressed: () => setState(
                            () => _ocultarContrasena = !_ocultarContrasena),
                      ),
                    ),
                    validator: Validators.contrasenaNoVacia,
                    onChanged: (_) => _alCambiar(),
                    onFieldSubmitted: (_) => _iniciarSesion(),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    // Sin funcionalidad por ahora (deshabilitado a propósito).
                    child: const TextButton(
                      key: Key('enlace_olvido'),
                      onPressed: null,
                      child: Text('¿Olvidaste tu contraseña?'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_errorGeneral != null) ...[
                    Text(
                      _errorGeneral!,
                      key: const Key('error_general'),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: tema.colorScheme.error),
                    ),
                    const SizedBox(height: 12),
                  ],
                  FilledButton(
                    key: const Key('boton_iniciar_sesion'),
                    onPressed:
                        (_formularioValido && !_cargando) ? _iniciarSesion : null,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                    child: _cargando
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Iniciar sesión'),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Text('¿No tienes cuenta? '),
                      GestureDetector(
                        key: const Key('enlace_registro'),
                        onTap: () => Navigator.of(context)
                            .pushReplacementNamed(AppRoutes.registro),
                        child: Text(
                          'Regístrate',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: tema.colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}