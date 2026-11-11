import 'package:flutter/material.dart';

import '../routes.dart';
import '../services/auth_service.dart';
import '../utils/app_feedback.dart';
import '../utils/validators.dart';

/// Pantalla para solicitar recuperación de contraseña (#22).
/// Envía correo de restablecimiento y maneja respuesta uniforme (anti-enumeración).
class RecuperarContrasenaScreen extends StatefulWidget {
  const RecuperarContrasenaScreen({super.key, this.authService});

  final AuthService? authService;

  @override
  State<RecuperarContrasenaScreen> createState() =>
      _RecuperarContrasenaScreenState();
}

class _RecuperarContrasenaScreenState extends State<RecuperarContrasenaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _correoCtrl = TextEditingController();

  late final AuthService _auth = widget.authService ?? AuthService();

  bool _cargando = false;
  bool _enviado = false;

  bool get _formularioValido => Validators.correo(_correoCtrl.text) == null;

  @override
  void initState() {
    super.initState();
    _correoCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _correoCtrl.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _cargando = true);
    try {
      await _auth.recuperarContrasena(_correoCtrl.text);
      if (!mounted) return;
      setState(() {
        _enviado = true;
        _cargando = false;
      });
      AppFeedback.mostrarExito(context, AuthService.msgRecuperacionEnviada);
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _cargando = false);
      AppFeedback.mostrarError(context, e.mensaje);
    } catch (_) {
      if (!mounted) return;
      setState(() => _cargando = false);
      AppFeedback.mostrarError(context, AuthService.msgGenerico);
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
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.lock_reset_rounded,
                      size: 64,
                      color: Color(0xFF1E4D3E),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Recuperar contraseña',
                      textAlign: TextAlign.center,
                      style: tema.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E4D3E),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ingresa el correo asociado a tu cuenta y te enviaremos las instrucciones para restablecer tu contraseña.',
                      textAlign: TextAlign.center,
                      style: tema.textTheme.bodyMedium?.copyWith(
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 28),
                    TextFormField(
                      key: const Key('campo_correo_recuperar'),
                      controller: _correoCtrl,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.done,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      decoration: const InputDecoration(
                        labelText: 'Correo electrónico',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: Validators.correo,
                      onFieldSubmitted: (_) {
                        if (_formularioValido && !_cargando) _enviar();
                      },
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      key: const Key('boton_enviar_recuperacion'),
                      onPressed:
                          (!_formularioValido || _cargando) ? null : _enviar,
                      child: _cargando
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Enviar instrucciones'),
                    ),
                    if (_enviado) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFA5D6A7)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.check_circle_outline,
                                color: Color(0xFF1E4D3E)),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                AuthService.msgRecuperacionEnviada,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF1E4D3E),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    TextButton(
                      key: const Key('enlace_volver_login'),
                      onPressed: () {
                        if (Navigator.of(context).canPop()) {
                          Navigator.of(context).pop();
                        } else {
                          Navigator.of(context)
                              .pushReplacementNamed(AppRoutes.login);
                        }
                      },
                      child: const Text('Volver a iniciar sesión'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
