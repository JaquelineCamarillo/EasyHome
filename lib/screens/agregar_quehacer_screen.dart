import 'package:flutter/material.dart';

import '../models/integrante.dart';
import '../services/hogar_service.dart';
import '../services/quehaceres_service.dart';
import '../services/usuario_service.dart';
import '../utils/app_feedback.dart';
import '../utils/validators.dart';

/// Pantalla #17 y #20 — Formulario para crear un nuevo quehacer en el hogar.
class AgregarQuehacerScreen extends StatefulWidget {
  const AgregarQuehacerScreen({
    super.key,
    this.hogarId,
    this.quehaceresService,
    this.hogarService,
    this.usuarioService,
    this.usuarioActualId,
    this.esAdministrador,
    this.integrantesIniciales,
  });

  final String? hogarId;
  final QuehaceresService? quehaceresService;
  final HogarService? hogarService;
  final UsuarioService? usuarioService;
  final String? usuarioActualId;
  final bool? esAdministrador;
  final List<Integrante>? integrantesIniciales;

  @override
  State<AgregarQuehacerScreen> createState() => _AgregarQuehacerScreenState();
}

class _AgregarQuehacerScreenState extends State<AgregarQuehacerScreen> {
  late final QuehaceresService _quehaceres =
      widget.quehaceresService ?? QuehaceresService();
  late final HogarService _hogares =
      widget.hogarService ?? HogarService();
  late final UsuarioService _usuarios =
      widget.usuarioService ?? UsuarioService();

  final _formKey = GlobalKey<FormState>();
  final _tituloCtrl = TextEditingController();

  String? _responsableSeleccionado;
  DateTime? _fechaSeleccionada;
  bool _recurrente = false;
  String? _hogarId;
  bool _esAdmin = false;
  bool _cargandoInicial = true;
  bool _guardando = false;
  List<Integrante> _integrantes = [];

  @override
  void initState() {
    super.initState();
    _iniciar();
  }

  @override
  void dispose() {
    _tituloCtrl.dispose();
    super.dispose();
  }

  Future<void> _iniciar() async {
    try {
      final hid = widget.hogarId ?? await _hogares.obtenerHogarIdActual();
      final uid = widget.usuarioActualId ?? _usuarios.usuarioActualId;

      if (widget.integrantesIniciales != null) {
        _integrantes = widget.integrantesIniciales!;
      }

      if (widget.esAdministrador != null) {
        _esAdmin = widget.esAdministrador!;
      } else if (uid != null) {
        final perfil = await _usuarios.obtenerPerfilActual();
        _esAdmin = perfil?.esAdministrador ?? false;
      }

      _hogarId = hid;

      if (_integrantes.isNotEmpty && _responsableSeleccionado == null) {
        _responsableSeleccionado = _integrantes.first.uid;
      }

      if (mounted) {
        setState(() {
          _cargandoInicial = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _cargandoInicial = false;
        });
      }
    }
  }

  Future<void> _seleccionarFecha() async {
    final ahora = DateTime.now();
    final seleccionada = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada ?? ahora,
      firstDate: DateTime(ahora.year - 1),
      lastDate: DateTime(ahora.year + 5),
    );

    if (seleccionada != null && mounted) {
      setState(() {
        _fechaSeleccionada = seleccionada;
      });
    }
  }

  Future<void> _guardar() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_hogarId == null || _hogarId!.isEmpty) {
      AppFeedback.mostrarError(context, 'No se pudo identificar el hogar');
      return;
    }

    if (_responsableSeleccionado == null) {
      AppFeedback.mostrarError(context, 'Selecciona un integrante responsable');
      return;
    }

    setState(() => _guardando = true);

    try {
      await _quehaceres.crearQuehacer(
        hogarId: _hogarId!,
        titulo: _tituloCtrl.text.trim(),
        asignadoA: _responsableSeleccionado!,
        fechaLimite: _fechaSeleccionada,
        esAdmin: _esAdmin,
        recurrente: _recurrente,
      );

      if (!mounted) return;
      AppFeedback.mostrarExito(context, 'Quehacer creado');
      Navigator.of(context).pop(true);
    } on QuehaceresException catch (e) {
      if (!mounted) return;
      setState(() => _guardando = false);
      AppFeedback.mostrarError(context, e.mensaje);
    } catch (_) {
      if (!mounted) return;
      setState(() => _guardando = false);
      AppFeedback.mostrarError(context, QuehaceresService.msgSinConexion);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cargandoInicial) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Regla de negocio estricta: Solo admin puede crear quehaceres
    if (!_esAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Agregar quehacer')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Solo el administrador puede crear quehaceres',
              key: Key('mensaje_no_admin'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
        ),
      );
    }

    // Si no se pasaron integrantes fijos, escuchar el stream
    Widget contenidoFormulario(List<Integrante> integrantes) {
      if (_responsableSeleccionado == null && integrantes.isNotEmpty) {
        _responsableSeleccionado = integrantes.first.uid;
      }

      return SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                key: const Key('campo_titulo_quehacer'),
                controller: _tituloCtrl,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Título del quehacer',
                  hintText: 'Ej. Limpiar el refrigerador',
                  prefixIcon: Icon(Icons.task_alt_rounded),
                ),
                validator: Validators.tituloQuehacer,
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                key: const Key('dropdown_integrantes_quehacer'),
                value: _responsableSeleccionado,
                decoration: const InputDecoration(
                  labelText: 'Asignar a',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
                items: integrantes.map((i) {
                  return DropdownMenuItem<String>(
                    value: i.uid,
                    child: Text(i.nombre),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _responsableSeleccionado = val;
                  });
                },
                validator: (val) => val == null || val.isEmpty
                    ? 'Selecciona un integrante'
                    : null,
              ),
              const SizedBox(height: 20),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE3DFD5), width: 1.2),
                ),
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.calendar_month_rounded,
                            color: Color(0xFF234E3F)),
                        const SizedBox(width: 10),
                        Text(
                          _fechaSeleccionada == null
                              ? 'Fecha límite opcional'
                              : '${_fechaSeleccionada!.day.toString().padLeft(2, '0')}/${_fechaSeleccionada!.month.toString().padLeft(2, '0')}/${_fechaSeleccionada!.year}',
                          key: const Key('texto_fecha_limite'),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: _fechaSeleccionada != null
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: _fechaSeleccionada != null
                                ? Colors.black87
                                : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                    Wrap(
                      spacing: 8,
                      children: [
                        if (_fechaSeleccionada != null)
                          IconButton(
                            key: const Key('boton_quitar_fecha'),
                            tooltip: 'Quitar fecha',
                            icon: const Icon(Icons.close_rounded,
                                size: 20, color: Colors.redAccent),
                            onPressed: () {
                              setState(() {
                                _fechaSeleccionada = null;
                              });
                            },
                          ),
                        FilledButton.tonal(
                          key: const Key('boton_seleccionar_fecha'),
                          onPressed: _seleccionarFecha,
                          child: Text(_fechaSeleccionada == null
                              ? 'Elegir fecha'
                              : 'Cambiar'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Material(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: Color(0xFFE3DFD5), width: 1.2),
                ),
                child: SwitchListTile(
                  key: const Key('switch_recurrente'),
                  title: const Text(
                    'Repetir cada semana (rota entre integrantes)',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                    'Al iniciar la semana se reasigna automáticamente al siguiente integrante',
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  value: _recurrente,
                  activeColor: const Color(0xFF234E3F),
                  onChanged: (val) {
                    setState(() {
                      _recurrente = val;
                    });
                  },
                ),
              ),
              const SizedBox(height: 32),
              FilledButton(
                key: const Key('boton_crear_quehacer'),
                onPressed: _guardando ? null : _guardar,
                child: _guardando
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Crear quehacer',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Agregar quehacer'),
      ),
      body: _integrantes.isNotEmpty || _hogarId == null
          ? contenidoFormulario(_integrantes)
          : StreamBuilder<List<Integrante>>(
              stream: _hogares.observarIntegrantes(_hogarId!),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Text('Error al cargar integrantes'),
                  );
                }
                if (!snapshot.hasData &&
                    snapshot.connectionState != ConnectionState.active) {
                  return const Center(child: CircularProgressIndicator());
                }

                final lista = snapshot.data ?? [];
                return contenidoFormulario(lista);
              },
            ),
    );
  }
}
