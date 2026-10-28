import 'package:flutter/material.dart';

import '../routes.dart';
import '../services/auth_service.dart';
import '../utils/validators.dart';

/// Pantalla #3 — Registro de cuenta.
class RegistroScreen extends StatefulWidget {
  const RegistroScreen({super.key, this.authService});

  /// Inyectable para pruebas; por defecto usa Firebase real.
  final AuthService? authService;

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  final _nombreCtrl = TextEditingController();
  final _correoCtrl = TextEditingController();
  final _contrasenaCtrl = TextEditingController();
  final _confirmarCtrl = TextEditingController();
  final _confirmarKey = GlobalKey<FormFieldState<String>>();

  late final AuthService _auth = widget.authService ?? AuthService();

  bool _ocultarContrasena = true;
  bool _cargando = false;
  String? _errorGeneral;

  bool get _formularioValido =>
      Validators.nombre(_nombreCtrl.text) == null &&
      Validators.correo(_correoCtrl.text) == null &&
      Validators.contrasena(_contrasenaCtrl.text) == null &&
      Validators.confirmarContrasena(
              _confirmarCtrl.text, _contrasenaCtrl.text) ==
          null;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _correoCtrl.dispose();
    _contrasenaCtrl.dispose();
    _confirmarCtrl.dispose();
    super.dispose();
  }

  void _alCambiar() => setState(() => _errorGeneral = null);

  void _alCambiarContrasena() {
    _alCambiar();
    // Si ya escribió la confirmación, revalidarla contra la nueva contraseña.
    if (_confirmarCtrl.text.isNotEmpty) {
      _confirmarKey.currentState?.validate();
    }
  }

  Future<void> _crearCuenta() async {
    if (!_formularioValido || _cargando) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _cargando = true;
      _errorGeneral = null;
    });

    try {
      await _auth.registrar(
        nombre: _nombreCtrl.text,
        correo: _correoCtrl.text,
        contrasena: _contrasenaCtrl.text,
      );
      if (!mounted) return;
      // Usuario nuevo => todavía no tiene hogar, no va directo al dashboard.
      Navigator.of(context).pushReplacementNamed(AppRoutes.hogar);
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
                    'Organiza compras y tareas en familia',
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
                          'Crea tu cuenta',
                          style: tema.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1E2D27),
                          ),
                        ),
                        const SizedBox(height: 18),
                        TextFormField(
                          key: const Key('campo_nombre'),
                          controller: _nombreCtrl,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.name],
                          decoration: InputDecoration(
                            labelText: 'Nombre',
                            prefixIcon: Icon(
                              Icons.person_outline_rounded,
                              color: tema.colorScheme.primary,
                            ),
                          ),
                          validator: Validators.nombre,
                          onChanged: (_) => _alCambiar(),
                        ),
                        const SizedBox(height: 16),
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
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.newPassword],
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
                          validator: Validators.contrasena,
                          onChanged: (_) => _alCambiarContrasena(),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          key: _confirmarKey,
                          controller: _confirmarCtrl,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          obscureText: true,
                          textInputAction: TextInputAction.done,
                          decoration: InputDecoration(
                            labelText: 'Confirmar contraseña',
                            prefixIcon: Icon(
                              Icons.check_circle_outline_rounded,
                              color: tema.colorScheme.primary,
                            ),
                          ),
                          validator: (v) => Validators.confirmarContrasena(
                              v, _contrasenaCtrl.text),
                          onChanged: (_) => _alCambiar(),
                          onFieldSubmitted: (_) => _crearCuenta(),
                        ),
                        const SizedBox(height: 20),
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
                        FilledButton(
                          key: const Key('boton_crear_cuenta'),
                          onPressed: (_formularioValido && !_cargando)
                              ? _crearCuenta
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
                              : const Text('Crear cuenta'),
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
                        '¿Ya tienes cuenta? ',
                        style: TextStyle(color: Colors.black54),
                      ),
                      GestureDetector(
                        key: const Key('enlace_login'),
                        onTap: () => Navigator.of(context)
                            .pushReplacementNamed(AppRoutes.login),
                        child: Text(
                          'Inicia sesión',
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
