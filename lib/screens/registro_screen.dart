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
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Crea tu cuenta',
                    style: tema.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: tema.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Para empezar a organizar tu hogar',
                    style: tema.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    key: const Key('campo_nombre'),
                    controller: _nombreCtrl,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.name],
                    decoration: const InputDecoration(labelText: 'Nombre'),
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
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.newPassword],
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
                    decoration: const InputDecoration(
                        labelText: 'Confirmar contraseña'),
                    validator: (v) =>
                        Validators.confirmarContrasena(v, _contrasenaCtrl.text),
                    onChanged: (_) => _alCambiar(),
                    onFieldSubmitted: (_) => _crearCuenta(),
                  ),
                  const SizedBox(height: 24),
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
                    key: const Key('boton_crear_cuenta'),
                    onPressed:
                        (_formularioValido && !_cargando) ? _crearCuenta : null,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                    child: _cargando
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Crear cuenta'),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Text('¿Ya tienes cuenta? '),
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