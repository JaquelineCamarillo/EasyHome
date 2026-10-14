import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../routes.dart';
import '../services/hogar_service.dart';
import '../utils/codigo_invitacion.dart';
import '../utils/mayusculas_formatter.dart';

/// Pantalla #6 — Unirse a un hogar existente con código de invitación.
class UnirseHogarScreen extends StatefulWidget {
  const UnirseHogarScreen({super.key, this.hogarService});

  /// Inyectable para pruebas; por defecto usa Firebase real.
  final HogarService? hogarService;

  @override
  State<UnirseHogarScreen> createState() => _UnirseHogarScreenState();
}

class _UnirseHogarScreenState extends State<UnirseHogarScreen> {
  final _codigoCtrl = TextEditingController();

  late final HogarService _hogares = widget.hogarService ?? HogarService();

  bool _cargando = false;
  String? _errorGeneral;

  bool get _formularioValido => _codigoCtrl.text.trim().isNotEmpty;

  @override
  void dispose() {
    _codigoCtrl.dispose();
    super.dispose();
  }

  Future<void> _unirse() async {
    if (!_formularioValido || _cargando) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _cargando = true;
      _errorGeneral = null;
    });

    try {
      await _hogares.unirseAHogar(codigo: _codigoCtrl.text);
      if (!mounted) return;
      // Entra como integrante (no administrador): directo al dashboard.
      Navigator.of(context).pushReplacementNamed(AppRoutes.dashboard);
    } on HogarException catch (e) {
      _mostrarError(e.mensaje);
    } catch (_) {
      _mostrarError(HogarService.msgSinConexion);
    }
  }

  void _mostrarError(String mensaje) {
    if (!mounted) return;
    setState(() {
      _errorGeneral = mensaje;
      _cargando = false;
    });
  }

  void _irACrearHogar() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop(); // regresa a #5
    } else {
      navigator.pushReplacementNamed(AppRoutes.hogar);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(Icons.group_add_rounded,
                      size: 56, color: tema.colorScheme.primary),
                  const SizedBox(height: 8),
                  Text(
                    'Únete a un hogar',
                    textAlign: TextAlign.center,
                    style: tema.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: tema.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Pídele el código de invitación a quien creó el hogar',
                    textAlign: TextAlign.center,
                    style: tema.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    key: const Key('campo_codigo'),
                    controller: _codigoCtrl,
                    textCapitalization: TextCapitalization.characters,
                    textInputAction: TextInputAction.done,
                    autocorrect: false,
                    enableSuggestions: false,
                    inputFormatters: [
                      FilteringTextInputFormatter.deny(RegExp(r'\s')),
                      const MayusculasFormatter(),
                      LengthLimitingTextInputFormatter(
                          CodigoInvitacion.longitud),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Código de invitación',
                      hintText: 'A3F9K2',
                    ),
                    style: const TextStyle(letterSpacing: 4, fontSize: 18),
                    onChanged: (_) => setState(() => _errorGeneral = null),
                    onFieldSubmitted: (_) => _unirse(),
                  ),
                  const SizedBox(height: 16),
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
                    key: const Key('boton_unirse'),
                    onPressed: (_formularioValido && !_cargando) ? _unirse : null,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                    child: _cargando
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Unirse'),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('¿No tienes un código? '),
                      GestureDetector(
                        key: const Key('enlace_crear_hogar'),
                        onTap: _irACrearHogar,
                        child: Text(
                          'Crea tu hogar',
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