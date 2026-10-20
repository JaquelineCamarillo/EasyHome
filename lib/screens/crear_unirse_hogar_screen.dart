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
                    'Crea tu hogar',
                    textAlign: TextAlign.center,
                    style: tema.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: tema.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Ponle nombre para empezar a organizar compras y quehaceres',
                    textAlign: TextAlign.center,
                    style: tema.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    key: const Key('campo_nombre_hogar'),
                    controller: _nombreCtrl,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    maxLength: Validators.maxNombreHogar,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(
                      labelText: 'Nombre del hogar',
                      hintText: 'Casa de los Pérez',
                    ),
                    validator: Validators.nombreHogar,
                    onChanged: (_) => setState(() => _errorGeneral = null),
                    onFieldSubmitted: (_) => _crearHogar(),
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
                    key: const Key('boton_crear_hogar'),
                    onPressed:
                        (_formularioValido && !_cargando) ? _crearHogar : null,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                    child: _cargando
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Crear hogar'),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Text('¿Ya tienes un código? '),
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