import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../routes.dart';
import '../services/hogar_service.dart';
import '../utils/codigo_invitacion.dart';
import '../utils/mayusculas_formatter.dart';

/// Pantalla #6 — Unirse a un hogar existente mediante su código de invitación.
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
  int _intentosFallidos = 0;
  DateTime? _bloqueadoHasta;

  bool get _estaBloqueado {
    if (_bloqueadoHasta == null) return false;
    return DateTime.now().isBefore(_bloqueadoHasta!);
  }

  bool get _formularioValido =>
      !_estaBloqueado &&
      _codigoCtrl.text.trim().length == CodigoInvitacion.longitud;

  @override
  void initState() {
    super.initState();
    _codigoCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _codigoCtrl.dispose();
    super.dispose();
  }

  Future<void> _unirse() async {
    if (_estaBloqueado) {
      setState(() {
        _errorGeneral = 'Demasiados intentos fallidos. Espera 60 segundos.';
      });
      return;
    }
    if (!_formularioValido || _cargando) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _cargando = true;
      _errorGeneral = null;
    });

    try {
      await _hogares.unirseAHogar(codigo: _codigoCtrl.text);
      if (!mounted) return;
      _intentosFallidos = 0;
      _bloqueadoHasta = null;
      // Unido con éxito: directo al dashboard.
      Navigator.of(context).pushReplacementNamed(AppRoutes.dashboard);
    } on HogarException catch (e) {
      if (!mounted) return;
      _registrarIntentoFallido(e.mensaje);
    } catch (_) {
      if (!mounted) return;
      _registrarIntentoFallido(HogarService.msgNoSePudoUnir);
    }
  }

  void _registrarIntentoFallido(String mensajeDefault) {
    _intentosFallidos++;
    if (_intentosFallidos >= 5) {
      _bloqueadoHasta = DateTime.now().add(const Duration(seconds: 60));
      _errorGeneral = 'Demasiados intentos fallidos. Espera 60 segundos.';
    } else {
      _errorGeneral = mensajeDefault;
    }
    setState(() {
      _cargando = false;
    });
  }

  void _irACrearHogar() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushReplacementNamed(AppRoutes.hogar);
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
                            blurRadius: 16,
                            offset: const verticalOffset(6),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.vpn_key_rounded,
                        color: Colors.white,
                        size: 38,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Unirse a un hogar',
                    textAlign: TextAlign.center,
                    style: tema.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: tema.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Pídele a quien administra el hogar que comparta contigo el código de invitación.',
                    textAlign: TextAlign.center,
                    style: tema.textTheme.bodyMedium?.copyWith(
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: tema.colorScheme.outlineVariant.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            key: const Key('campo_codigo'),
                            controller: _codigoCtrl,
                            textCapitalization: TextCapitalization.characters,
                            textInputAction: TextInputAction.done,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              letterSpacing: 8,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                            inputFormatters: [
                              MayusculasFormatter(),
                              LengthLimitingTextInputFormatter(
                                  CodigoInvitacion.longitud),
                            ],
                            decoration: const InputDecoration(
                              labelText: 'Código de invitación',
                              hintText: 'A3F9K2',
                              prefixIcon: Icon(Icons.key_rounded),
                              counterText: '',
                            ),
                            onFieldSubmitted: (_) => _unirse(),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'El código tiene ${CodigoInvitacion.longitud} caracteres (letras y números sin espacios).',
                            style: tema.textTheme.bodySmall?.copyWith(
                              color: Colors.black45,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
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
                            key: const Key('boton_unirse'),
                            onPressed: (_formularioValido && !_cargando) ? _unirse : null,
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
                                : const Text('Unirse al hogar'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Text(
                        '¿No tienes un código? ',
                        style: TextStyle(color: Colors.black54),
                      ),
                      GestureDetector(
                        key: const Key('enlace_crear_hogar'),
                        onTap: _irACrearHogar,
                        child: Text(
                          'Crea tu hogar',
                          style: TextStyle(
                            color: tema.colorScheme.primary,
                            fontWeight: FontWeight.bold,
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

class verticalOffset extends Offset {
  const verticalOffset(double dy) : super(0, dy);
}
