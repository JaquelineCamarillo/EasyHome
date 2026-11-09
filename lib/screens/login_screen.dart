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
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        color: tema.colorScheme.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: tema.colorScheme.primary.withValues(alpha: 0.3),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.home_rounded,
                        size: 42,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'EasyHome',
                    textAlign: TextAlign.center,
                    style: tema.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: tema.colorScheme.primary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Organiza tu hogar, comparte la carga.',
                    textAlign: TextAlign.center,
                    style: tema.textTheme.bodyMedium?.copyWith(
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE8E4DA)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x08000000),
                          blurRadius: 16,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Iniciar sesión',
                          style: tema.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1E2D27),
                          ),
                        ),
                        const SizedBox(height: 18),
                        TextFormField(
                          key: const Key('campo_correo'),
                          controller: _correoCtrl,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.email],
                          decoration: InputDecoration(
                            labelText: 'Correo electrónico',
                            prefixIcon: Icon(
                              Icons.email_outlined,
                              color: tema.colorScheme.primary,
                            ),
                          ),
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
                            prefixIcon: Icon(
                              Icons.lock_outline_rounded,
                              color: tema.colorScheme.primary,
                            ),
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
                          child: TextButton(
                            key: const Key('enlace_olvido'),
                            onPressed: null,
                            child: const Text('¿Olvidaste tu contraseña?'),
                          ),
                        ),
                        if (_errorGeneral != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: tema.colorScheme.error.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.error_outline_rounded,
                                    size: 18, color: tema.colorScheme.error),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _errorGeneral!,
                                    key: const Key('error_general'),
                                    style: TextStyle(
                                      color: tema.colorScheme.error,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        const SizedBox(height: 8),
                        FilledButton(
                          key: const Key('boton_iniciar_sesion'),
                          onPressed: (_formularioValido && !_cargando)
                              ? _iniciarSesion
                              : null,
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(50),
                          ),
                          child: _cargando
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Iniciar sesión'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Text(
                        '¿No tienes cuenta? ',
                        style: TextStyle(color: Colors.black54),
                      ),
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
