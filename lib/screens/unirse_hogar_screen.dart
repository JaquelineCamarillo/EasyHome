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

  bool get _formularioValido =>
      _codigoCtrl.text.trim().length == CodigoInvitacion.longitud;

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
      // Unido con éxito: directo al dashboard.
      Navigator.of(context).pushReplacementNamed(AppRoutes.dashboard);
    } on HogarException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorGeneral = e.mensaje;
        _cargando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorGeneral = HogarService.msgNoSePudoUnir;
        _cargando = false;
      });
    }
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
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.group_add_rounded,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Únete a un hogar',
                    textAlign: TextAlign.center,
                    style: tema.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: tema.colorScheme.primary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Pídele el código de 6 caracteres a quien creó el hogar',
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
                        TextFormField(
                          key: const Key('campo_codigo'),
                          controller: _codigoCtrl,
                          textCapitalization: TextCapitalization.characters,
                          textInputAction: TextInputAction.done,
                          autocorrect: false,
                          enableSuggestions: false,
                          textAlign: TextAlign.center,
                          inputFormatters: [
                            FilteringTextInputFormatter.deny(RegExp(r'\s')),
                            const MayusculasFormatter(),
                            LengthLimitingTextInputFormatter(
                                CodigoInvitacion.longitud),
                          ],
                          decoration: InputDecoration(
                            labelText: 'Código de invitación',
                            hintText: 'A3F9K2',
                            prefixIcon: Icon(
                              Icons.key_rounded,
                              color: tema.colorScheme.primary,
                            ),
                          ),
                          style: const TextStyle(
                            letterSpacing: 6,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                          onChanged: (_) => setState(() => _errorGeneral = null),
                          onFieldSubmitted: (_) => _unirse(),
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
