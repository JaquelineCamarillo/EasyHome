import 'package:flutter/material.dart';

import '../routes.dart';
import '../services/hogar_service.dart';
import '../utils/validators.dart';

/// Pantalla #5 — Crear un hogar nuevo (con acceso a #6, unirse con código).
class CrearUnirseHogarScreen extends StatefulWidget {
  const CrearUnirseHogarScreen({super.key, this.hogarService});

  /// Inyectable para pruebas; por defecto usa Firebase real.
  final HogarService? hogarService;

  @override
  State<CrearUnirseHogarScreen> createState() => _CrearUnirseHogarScreenState();
}

class _CrearUnirseHogarScreenState extends State<CrearUnirseHogarScreen> {
  final _nombreCtrl = TextEditingController();

  late final HogarService _hogares = widget.hogarService ?? HogarService();

  bool _cargando = false;
  String? _errorGeneral;

  bool get _formularioValido => Validators.nombreHogar(_nombreCtrl.text) == null;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    super.dispose();
  }

  Future<void> _crearHogar() async {
    if (!_formularioValido || _cargando) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _cargando = true;
      _errorGeneral = null;
    });

    try {
      await _hogares.crearHogar(nombre: _nombreCtrl.text);
      if (!mounted) return;
      // Ya es administrador de su hogar: directo al dashboard.
      Navigator.of(context).pushReplacementNamed(AppRoutes.dashboard);
    } on HogarException catch (e) {
      _mostrarError(e.mensaje);
    } catch (_) {
      _mostrarError(HogarService.msgNoSePudoCrear);
    }
  }

  void _mostrarError(String mensaje) {
    if (!mounted) return;
    setState(() {
      _errorGeneral = mensaje;
      _cargando = false;
    });
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
                        Icons.home_work_rounded,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Crea tu hogar',
                    textAlign: TextAlign.center,
                    style: tema.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: tema.colorScheme.primary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Ponle un nombre para empezar a organizar compras y quehaceres',
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
                          key: const Key('campo_nombre_hogar'),
                          controller: _nombreCtrl,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          maxLength: Validators.maxNombreHogar,
                          textCapitalization: TextCapitalization.sentences,
                          textInputAction: TextInputAction.done,
                          decoration: InputDecoration(
                            labelText: 'Nombre del hogar',
                            hintText: 'Ej. Casa de los Pérez, Depa 402...',
                            prefixIcon: Icon(
                              Icons.cottage_outlined,
                              color: tema.colorScheme.primary,
                            ),
                          ),
                          validator: Validators.nombreHogar,
                          onChanged: (_) => setState(() => _errorGeneral = null),
                          onFieldSubmitted: (_) => _crearHogar(),
                        ),
                        const SizedBox(height: 8),
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
                          key: const Key('boton_crear_hogar'),
                          onPressed: (_formularioValido && !_cargando)
                              ? _crearHogar
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
                              : const Text('Crear hogar'),
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
                        '¿Ya tienes un código? ',
                        style: TextStyle(color: Colors.black54),
                      ),
                      GestureDetector(
                        key: const Key('enlace_unirse'),
                        onTap: () => Navigator.of(context)
                            .pushNamed(AppRoutes.unirseHogar),
                        child: Text(
                          'Únete a un hogar',
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
