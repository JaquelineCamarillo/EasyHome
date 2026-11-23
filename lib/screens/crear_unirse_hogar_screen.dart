import 'package:flutter/material.dart';

import '../models/hogar.dart';
import '../routes.dart';
import '../services/hogar_service.dart';
import '../theme/app_theme.dart';
import '../utils/validators.dart';
import '../widgets/logo.dart';

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
  String _tipoEspacio = TipoEspacio.hogar;

  late final HogarService _hogares = widget.hogarService ?? HogarService();

  bool _cargando = false;
  String? _errorGeneral;

  bool get _formularioValido => Validators.nombreHogar(_nombreCtrl.text) == null;

  bool get _pareceCodigoInvitacion {
    final t = _nombreCtrl.text.trim();
    return t.length == 6 && RegExp(r'^[A-HJ-NP-Z2-9a-hj-np-z]{6}$').hasMatch(t);
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    super.dispose();
  }

  Future<void> _unirseConCodigoDetectado() async {
    final cod = _nombreCtrl.text.trim().toUpperCase();
    FocusScope.of(context).unfocus();
    setState(() {
      _cargando = true;
      _errorGeneral = null;
    });

    try {
      await _hogares.unirseAHogar(codigo: cod);
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.dashboard,
        (_) => false,
      );
    } on HogarException catch (e) {
      _mostrarError(e.mensaje);
    } catch (_) {
      _mostrarError(HogarService.msgNoSePudoUnir);
    }
  }

  Future<void> _crearHogar() async {
    if (!_formularioValido || _cargando) return;

    if (_pareceCodigoInvitacion) {
      final cod = _nombreCtrl.text.trim().toUpperCase();
      final accion = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.help_outline_rounded, color: AppColors.bronceMocha),
              SizedBox(width: 8),
              Text('¿Unirte o Crear?',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          content: Text(
            'Ingresaste "$cod", que parece ser un código de invitación.\n\n'
            '• Si alguien te dio este código para unirte a su espacio, selecciona "Unirme con código".\n\n'
            '• Si este es el nombre de tu propio espacio nuevo, selecciona "Crear nuevo espacio".',
            style: const TextStyle(fontSize: 14),
          ),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.of(ctx).pop('crear'),
              child: const Text('Crear nuevo espacio'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: AppColors.bronceMocha),
              onPressed: () => Navigator.of(ctx).pop('unir'),
              child: const Text('Unirme con código'),
            ),
          ],
        ),
      );
      if (accion == null) return;
      if (accion == 'unir') {
        await _unirseConCodigoDetectado();
        return;
      }
    }

    if (!mounted) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _cargando = true;
      _errorGeneral = null;
    });

    try {
      await _hogares.crearHogar(
        nombre: _nombreCtrl.text,
        tipoEspacio: _tipoEspacio,
      );
      if (!mounted) return;
      // Ya es administrador de su espacio: directo al dashboard limpio.
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.dashboard,
        (_) => false,
      );
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
                  const Center(
                    child: EasyHomeLogo(size: 96),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Crear espacio',
                    textAlign: TextAlign.center,
                    style: tema.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: AppColors.verdeOliva,
                      letterSpacing: -0.6,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Ponle un nombre y elige el tipo de espacio o equipo para empezar a organizar compras y tareas',
                    textAlign: TextAlign.center,
                    style: tema.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textoSecundario,
                    ),
                  ),

                  // Tarjeta destacada de "¿Ya tienes un código?"
                  Container(
                    margin: const EdgeInsets.only(top: 24, bottom: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.verdeOliva.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: AppColors.verdeOliva.withValues(alpha: 0.35),
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.verdeOliva,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.key_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '¿Tienes un código?',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                  color: AppColors.textoPrincipal,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Únete a un espacio existente aquí',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textoSecundario,
                                ),
                              ),
                            ],
                          ),
                        ),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.verdeOliva,
                            side: const BorderSide(
                                color: AppColors.verdeOliva, width: 1.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                          ),
                          onPressed: () => Navigator.of(context)
                              .pushNamed(AppRoutes.unirseHogar),
                          child: const Text('Unirme'),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(26),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: AppColors.borde, width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.verdeOliva.withValues(alpha: 0.06),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
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
                            labelText: 'Nombre del espacio',
                            hintText: 'Ej. Casa de los Pérez, Depa 402, Equipo Alfa...',
                            prefixIcon: Icon(
                              Icons.cottage_outlined,
                              color: tema.colorScheme.primary,
                            ),
                          ),
                          validator: Validators.nombreHogar,
                          onChanged: (_) => setState(() => _errorGeneral = null),
                          onFieldSubmitted: (_) => _crearHogar(),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          key: const Key('dropdown_tipo_espacio'),
                          initialValue: _tipoEspacio,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: 'Tipo de espacio o equipo',
                            prefixIcon: Icon(
                              Icons.workspaces_outline,
                              color: tema.colorScheme.primary,
                            ),
                          ),
                          items: TipoEspacio.etiquetas.entries.map((e) {
                            return DropdownMenuItem<String>(
                              value: e.key,
                              child: Text(
                                e.value,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _tipoEspacio = val);
                            }
                          },
                        ),
                        if (_pareceCodigoInvitacion) ...[
                          Container(
                            key: const Key('aviso_parece_codigo'),
                            margin: const EdgeInsets.only(top: 10, bottom: 6),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color:
                                  AppColors.arenaTaupe.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: AppColors.bronceMocha
                                    .withValues(alpha: 0.4),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.info_outline_rounded,
                                        size: 18,
                                        color: AppColors.bronceMocha),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '¿"${_nombreCtrl.text.trim().toUpperCase()}" es un código de invitación?',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: AppColors.textoPrincipal,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Si deseas unirte a un espacio con este código, presiona el botón abajo para no crear un espacio duplicado.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textoSecundario,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                FilledButton.icon(
                                  key: const Key('boton_unirse_con_este_codigo'),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppColors.bronceMocha,
                                    foregroundColor: Colors.white,
                                    minimumSize: const Size.fromHeight(42),
                                  ),
                                  icon: const Icon(Icons.group_add_rounded,
                                      size: 18),
                                  label: const Text(
                                    'Unirme al espacio con este código',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  onPressed: _cargando
                                      ? null
                                      : _unirseConCodigoDetectado,
                                ),
                              ],
                            ),
                          ),
                        ],
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
                              : const Text('Crear espacio'),
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
                          'Únete a un espacio',
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
