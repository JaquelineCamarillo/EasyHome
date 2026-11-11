import 'package:flutter/material.dart';

import '../models/integrante.dart';
import '../models/producto.dart';
import '../models/quehacer.dart';
import '../routes.dart';
import '../services/compras_service.dart';
import '../services/hogar_service.dart';
import '../services/quehaceres_service.dart';
import '../services/usuario_service.dart';
import '../utils/app_feedback.dart';
import '../utils/validators.dart';

/// Pantalla principal — Dashboard de compras y quehaceres en tiempo real.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    this.hogarId,
    this.comprasService,
    this.hogarService,
    this.quehaceresService,
    this.usuarioService,
    this.usuarioActualId,
    this.esAdministrador,
    this.vistaInicial = 0,
  });

  /// Si no se especifica, se consulta del usuario actual.
  final String? hogarId;

  /// Inyectable para pruebas; por defecto usa Firebase real.
  final ComprasService? comprasService;
  final HogarService? hogarService;
  final QuehaceresService? quehaceresService;
  final UsuarioService? usuarioService;
  final String? usuarioActualId;
  final bool? esAdministrador;
  final int vistaInicial;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final ComprasService _compras =
      widget.comprasService ?? ComprasService();
  late final HogarService _hogares =
      widget.hogarService ?? HogarService();
  late final QuehaceresService _quehaceres =
      widget.quehaceresService ?? QuehaceresService();
  late final UsuarioService _usuarios =
      widget.usuarioService ?? UsuarioService();

  late int _indiceSeccion = widget.vistaInicial;
  String _filtroQuehaceres = 'mis';
  String? _hogarIdResuelto;

  Stream<List<Producto>>? _productosStream;
  Stream<List<Quehacer>>? _quehaceresStream;
  Stream<List<Integrante>>? _integrantesStream;
  String? _error;
  bool _cargandoInicial = true;

  bool _mostrarBuscador = false;
  final _busquedaCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _iniciar();
  }

  @override
  void dispose() {
    _busquedaCtrl.dispose();
    super.dispose();
  }

  Future<void> _iniciar() async {
    try {
      final hogarId = widget.hogarId ?? await _hogares.obtenerHogarIdActual();
      if (!mounted) return;

      if (hogarId == null) {
        setState(() {
          _error = 'Todavía no perteneces a ningún hogar';
          _cargandoInicial = false;
        });
        return;
      }

      setState(() {
        _hogarIdResuelto = hogarId;
        _productosStream = _compras.observarProductos(hogarId);
        _cargandoInicial = false;
      });

      // Rotación semanal automática (#20): se dispara al resolver el hogar
      _ejecutarRotacionSemanal(hogarId);
    } on HogarException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.mensaje;
          _cargandoInicial = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = HogarService.msgSinConexion;
          _cargandoInicial = false;
        });
      }
    }
  }

  Future<void> _ejecutarRotacionSemanal(String hogarId) async {
    try {
      final rotados = await _quehaceres.rotarSiCorresponde(hogarId);
      if (rotados > 0 && mounted) {
        AppFeedback.mostrarExito(
          context,
          'Se rotaron los quehaceres de la semana',
        );
      }
    } catch (_) {
      // Error silencioso: no bloquea el dashboard
    }
  }

  Stream<List<Quehacer>> _obtenerQuehaceresStream(String hogarId) {
    return _quehaceresStream ??= _quehaceres.observarQuehaceres(hogarId);
  }

  Stream<List<Integrante>> _obtenerIntegrantesStream(String hogarId) {
    return _integrantesStream ??= _hogares.observarIntegrantes(hogarId);
  }

  Future<void> _cambiarEstadoProducto(Producto producto) async {
    final nuevoEstado = !producto.comprado;
    try {
      await _compras.cambiarEstado(
        productoId: producto.id,
        comprado: nuevoEstado,
      );
      if (!mounted) return;
      AppFeedback.mostrarExito(
        context,
        nuevoEstado
            ? 'Marcado como comprado'
            : 'Movido a pendientes',
      );
    } catch (_) {
      if (!mounted) return;
      AppFeedback.mostrarError(context, ComprasService.msgErrorActualizar);
    }
  }

  Future<void> _confirmarEliminarProducto(Producto producto) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
            SizedBox(width: 8),
            Text(
              'Eliminar producto',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: Text(
          '¿Seguro que quieres eliminar este producto ("${producto.nombre}")?',
          key: const Key('mensaje_confirmar_eliminar'),
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            key: const Key('boton_cancelar_eliminar'),
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            key: const Key('boton_confirmar_eliminar'),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFC24134)),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      try {
        await _compras.eliminarProducto(producto.id);
        if (!mounted) return;
        AppFeedback.mostrarInfo(context, 'Producto eliminado');
      } catch (_) {
        if (!mounted) return;
        AppFeedback.mostrarError(context, ComprasService.msgSinConexion);
      }
    }
  }

  Future<void> _mostrarMenuOpciones(Producto producto) async {
    final opcion = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Material(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Text(
                  producto.nombre,
                  key: const Key('titulo_menu_opciones'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E2D27),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                key: const Key('opcion_editar'),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F1EC),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.edit_outlined,
                    color: Color(0xFF234E3F),
                    size: 20,
                  ),
                ),
                title: const Text(
                  'Editar',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
                subtitle: const Text('Modificar nombre y cantidad'),
                onTap: () => Navigator.of(ctx).pop('editar'),
              ),
              ListTile(
                key: const Key('opcion_eliminar'),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDE8E6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    color: Color(0xFFC24134),
                    size: 20,
                  ),
                ),
                title: const Text(
                  'Eliminar',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Color(0xFFC24134),
                  ),
                ),
                subtitle: const Text('Quitar este producto de la lista'),
                onTap: () => Navigator.of(ctx).pop('eliminar'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );

    if (!mounted || opcion == null) return;

    if (opcion == 'editar') {
      await _mostrarFormularioEditar(producto);
    } else if (opcion == 'eliminar') {
      await _confirmarEliminarProducto(producto);
    }
  }

  Future<void> _mostrarFormularioEditar(Producto producto) async {
    final formKey = GlobalKey<FormState>();
    final nombreCtrl = TextEditingController(text: producto.nombre);
    final cantidadCtrl =
        TextEditingController(text: producto.cantidad.toString());
    bool guardando = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          void ajustarCantidad(int delta) {
            final actual = int.tryParse(cantidadCtrl.text) ?? 1;
            final nuevo = actual + delta;
            if (nuevo >= 1) {
              setModalState(() {
                cantidadCtrl.text = nuevo.toString();
              });
            }
          }

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: Material(
              color: Colors.white,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
              clipBehavior: Clip.antiAlias,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.black12,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const Row(
                        children: [
                          Icon(Icons.edit_note_rounded,
                              color: Color(0xFF234E3F), size: 26),
                          SizedBox(width: 8),
                          Text(
                            'Editar producto',
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E2D27),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      TextFormField(
                        key: const Key('campo_editar_nombre_producto'),
                        controller: nombreCtrl,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          labelText: 'Nombre del producto',
                          prefixIcon: Icon(Icons.shopping_bag_outlined),
                        ),
                        validator: Validators.nombreProducto,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          IconButton.filledTonal(
                            key: const Key(
                                'boton_decrementar_cantidad_edicion'),
                            tooltip: 'Reducir cantidad',
                            icon: const Icon(Icons.remove_rounded),
                            onPressed: () => ajustarCantidad(-1),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              key: const Key(
                                  'campo_editar_cantidad_producto'),
                              controller: cantidadCtrl,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              decoration: const InputDecoration(
                                labelText: 'Cantidad',
                                prefixIcon: Icon(Icons.numbers_rounded),
                              ),
                              validator: Validators.cantidadProducto,
                            ),
                          ),
                          const SizedBox(width: 10),
                          IconButton.filledTonal(
                            key: const Key(
                                'boton_incrementar_cantidad_edicion'),
                            tooltip: 'Aumentar cantidad',
                            icon: const Icon(Icons.add_rounded),
                            onPressed: () => ajustarCantidad(1),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      FilledButton(
                        key: const Key('boton_guardar_edicion'),
                        onPressed: guardando
                            ? null
                            : () async {
                                if (!(formKey.currentState?.validate() ??
                                    false)) {
                                  return;
                                }
                                final nuevaCantidad =
                                    int.tryParse(cantidadCtrl.text.trim()) ?? 1;
                                final nuevoNombre = nombreCtrl.text.trim();

                                setModalState(() => guardando = true);
                                try {
                                  await _compras.editarProducto(
                                    productoId: producto.id,
                                    nombre: nuevoNombre,
                                    cantidad: nuevaCantidad,
                                  );
                                  if (!ctx.mounted) return;
                                  Navigator.of(ctx).pop();
                                  if (!mounted) return;
                                  AppFeedback.mostrarExito(
                                    context,
                                    'Producto actualizado',
                                  );
                                } catch (_) {
                                  if (!ctx.mounted) return;
                                  setModalState(() => guardando = false);
                                  AppFeedback.mostrarError(
                                    ctx,
                                    ComprasService.msgErrorActualizar,
                                  );
                                }
                              },
                        child: guardando
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Guardar cambios'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _irAAgregarProducto() async {
    final agregado =
        await Navigator.of(context).pushNamed(AppRoutes.agregarProducto);
    if (agregado == true && mounted) {
      AppFeedback.mostrarExito(context, 'Producto agregado');
    }
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    if (_cargandoInicial) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Compras')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline_rounded,
                    size: 52, color: tema.colorScheme.error),
                const SizedBox(height: 14),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: tema.textTheme.bodyLarge,
                ),
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: () {
                    setState(() {
                      _cargandoInicial = true;
                      _error = null;
                    });
                    _iniciar();
                  },
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_indiceSeccion == 1) {
      return _buildVistaQuehaceres(
          tema, _hogarIdResuelto ?? widget.hogarId ?? '');
    }

    final stream = _productosStream;
    if (stream == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return StreamBuilder<List<Producto>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Compras')),
            body: const Center(
              child: Text(ComprasService.msgErrorCargar),
            ),
          );
        }

        if (!snapshot.hasData &&
            snapshot.connectionState != ConnectionState.active) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final todos = snapshot.data ?? [];
        final query = _busquedaCtrl.text.trim().toLowerCase();
        final filtrados = query.isEmpty
            ? todos
            : todos
                .where((p) => p.nombre.toLowerCase().contains(query))
                .toList();

        final pendientes = filtrados.where((p) => !p.comprado).toList();
        final comprados = filtrados.where((p) => p.comprado).toList();

        return DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              scrolledUnderElevation: 0,
              elevation: 0,
              title: _mostrarBuscador
                  ? TextField(
                      controller: _busquedaCtrl,
                      autofocus: true,
                      decoration: const InputDecoration(
                        hintText: 'Buscar producto...',
                        isDense: true,
                        prefixIcon: Icon(Icons.search, size: 20),
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                      ),
                      onChanged: (_) => setState(() {}),
                    )
                  : const Text(
                      'Lista de compras',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
              actions: [
                IconButton(
                  tooltip: _mostrarBuscador ? 'Cerrar búsqueda' : 'Buscar',
                  icon: Icon(_mostrarBuscador
                      ? Icons.close_rounded
                      : Icons.search_rounded),
                  onPressed: () {
                    setState(() {
                      _mostrarBuscador = !_mostrarBuscador;
                      if (!_mostrarBuscador) {
                        _busquedaCtrl.clear();
                      }
                    });
                  },
                ),
                IconButton(
                  key: const Key('boton_perfil_hogar'),
                  tooltip: 'Perfil del hogar',
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFE8E4DA)),
                    ),
                    child: Icon(
                      Icons.group_rounded,
                      size: 20,
                      color: tema.colorScheme.primary,
                    ),
                  ),
                  onPressed: () =>
                      Navigator.of(context).pushNamed(AppRoutes.perfilHogar),
                ),
                IconButton(
                  key: const Key('boton_mi_perfil_dash'),
                  tooltip: 'Mi perfil',
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFE8E4DA)),
                    ),
                    child: Icon(
                      Icons.person_outline_rounded,
                      size: 20,
                      color: tema.colorScheme.primary,
                    ),
                  ),
                  onPressed: () =>
                      Navigator.of(context).pushNamed(AppRoutes.editarPerfil),
                ),
                const SizedBox(width: 8),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(56),
                child: Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEBE7DD),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: TabBar(
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    indicator: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x10000000),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    labelColor: tema.colorScheme.primary,
                    unselectedLabelColor: Colors.black54,
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    tabs: [
                      Tab(
                        key: const Key('tab_pendientes'),
                        text: 'Pendientes (${pendientes.length})',
                      ),
                      Tab(
                        key: const Key('tab_comprados'),
                        text: 'Comprados (${comprados.length})',
                      ),
                    ],
                  ),
                ),
              ),
            ),
            body: SafeArea(
              child: todos.isEmpty
                  ? const _EstadoVacioGlobal()
                  : Column(
                      children: [
                        if (todos.isNotEmpty && query.isEmpty)
                          _ProgresoComprasBanner(
                            comprados: todos.where((p) => p.comprado).length,
                            total: todos.length,
                          ),
                        Expanded(
                          child: TabBarView(
                            children: [
                              _ListaProductos(
                                productos: pendientes,
                                tipo: _TipoLista.pendientes,
                                onToggle: _cambiarEstadoProducto,
                                onDelete: _confirmarEliminarProducto,
                                onLongPress: _mostrarMenuOpciones,
                              ),
                              _ListaProductos(
                                productos: comprados,
                                tipo: _TipoLista.comprados,
                                onToggle: _cambiarEstadoProducto,
                                onDelete: _confirmarEliminarProducto,
                                onLongPress: _mostrarMenuOpciones,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
            bottomNavigationBar: _crearBottomNav(),
            floatingActionButton: FloatingActionButton.extended(
              key: const Key('boton_agregar_producto'),
              tooltip: 'Agregar producto',
              backgroundColor: tema.colorScheme.primary,
              foregroundColor: Colors.white,
              elevation: 4,
              onPressed: _irAAgregarProducto,
              icon: const Icon(Icons.add_rounded, size: 24),
              label: const Text(
                'Agregar',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _crearBottomNav() {
    return BottomNavigationBar(
      key: const Key('barra_navegacion_dashboard'),
      currentIndex: _indiceSeccion,
      onTap: (index) {
        setState(() {
          _indiceSeccion = index;
        });
      },
      selectedItemColor: const Color(0xFF234E3F),
      unselectedItemColor: Colors.black54,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.shopping_cart_outlined, key: Key('nav_compras')),
          activeIcon: Icon(Icons.shopping_cart_rounded),
          label: 'Compras',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.checklist_rounded, key: Key('nav_quehaceres')),
          activeIcon: Icon(Icons.checklist_outlined),
          label: 'Quehaceres',
        ),
      ],
    );
  }

  Future<void> _cambiarEstadoQuehacer(
      Quehacer quehacer, String nombreResponsable) async {
    final uidActual =
        widget.usuarioActualId ?? _usuarios.usuarioActualId ?? '';

    if (quehacer.asignadoA != uidActual) {
      AppFeedback.mostrarInfo(
          context, 'Solo $nombreResponsable puede marcar este quehacer');
      return;
    }

    final nuevoEstado = !quehacer.hecho;
    try {
      await _quehaceres.marcarHecho(
        quehacerId: quehacer.id,
        asignadoA: quehacer.asignadoA,
        nuevoEstado: nuevoEstado,
        uidActual: uidActual,
      );
      if (!mounted) return;
      AppFeedback.mostrarExito(
        context,
        nuevoEstado ? 'Quehacer completado' : 'Quehacer pendiente',
      );
    } on QuehaceresException catch (e) {
      if (!mounted) return;
      AppFeedback.mostrarError(context, e.mensaje);
    } catch (_) {
      if (!mounted) return;
      AppFeedback.mostrarError(
          context, QuehaceresService.msgErrorActualizar);
    }
  }

  Future<void> _mostrarMenuOpcionesQuehacer(
      Quehacer quehacer, List<Integrante> integrantes, bool esAdmin) async {
    if (!esAdmin) {
      AppFeedback.mostrarError(context, QuehaceresService.msgSinPermiso);
      return;
    }

    final opcion = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Material(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Text(
                  quehacer.titulo,
                  key: const Key('titulo_menu_opciones_quehacer'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E2D27),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                key: const Key('opcion_editar_quehacer'),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F1EC),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.edit_outlined,
                    color: Color(0xFF234E3F),
                    size: 20,
                  ),
                ),
                title: const Text(
                  'Editar',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
                subtitle: const Text('Modificar título y fecha límite'),
                onTap: () => Navigator.of(ctx).pop('editar'),
              ),
              ListTile(
                key: const Key('opcion_reasignar_quehacer'),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.swap_horiz_rounded,
                    color: Color(0xFFB45309),
                    size: 20,
                  ),
                ),
                title: const Text(
                  'Reasignar',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
                subtitle: const Text('Cambiar el integrante responsable'),
                onTap: () => Navigator.of(ctx).pop('reasignar'),
              ),
              ListTile(
                key: const Key('opcion_eliminar_quehacer'),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDE8E6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    color: Color(0xFFC24134),
                    size: 20,
                  ),
                ),
                title: const Text(
                  'Eliminar',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Color(0xFFC24134),
                  ),
                ),
                subtitle: const Text('Quitar este quehacer de la lista'),
                onTap: () => Navigator.of(ctx).pop('eliminar'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );

    if (!mounted || opcion == null) return;

    if (opcion == 'editar') {
      await _mostrarFormularioEditarQuehacer(quehacer, esAdmin);
    } else if (opcion == 'reasignar') {
      await _mostrarDialogoReasignarQuehacer(quehacer, integrantes, esAdmin);
    } else if (opcion == 'eliminar') {
      await _confirmarEliminarQuehacer(quehacer, esAdmin);
    }
  }

  Future<void> _mostrarFormularioEditarQuehacer(
      Quehacer quehacer, bool esAdmin) async {
    if (!esAdmin) {
      AppFeedback.mostrarError(context, QuehaceresService.msgSinPermiso);
      return;
    }

    final formKey = GlobalKey<FormState>();
    final tituloCtrl = TextEditingController(text: quehacer.titulo);
    DateTime? fechaSeleccionada = quehacer.fechaLimite;
    bool recurrente = quehacer.recurrente;
    bool guardando = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          Future<void> elegirFecha() async {
            final ahora = DateTime.now();
            final elegida = await showDatePicker(
              context: ctx,
              initialDate: fechaSeleccionada ?? ahora,
              firstDate: DateTime(ahora.year - 1),
              lastDate: DateTime(ahora.year + 5),
            );
            if (elegida != null) {
              setModalState(() {
                fechaSeleccionada = elegida;
              });
            }
          }

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: Material(
              color: Colors.white,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
              clipBehavior: Clip.antiAlias,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.black12,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const Row(
                        children: [
                          Icon(Icons.edit_note_rounded,
                              color: Color(0xFF234E3F), size: 26),
                          SizedBox(width: 8),
                          Text(
                            'Editar quehacer',
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E2D27),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      TextFormField(
                        key: const Key('campo_editar_titulo_quehacer'),
                        controller: tituloCtrl,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          labelText: 'Título del quehacer',
                          prefixIcon: Icon(Icons.task_alt_rounded),
                        ),
                        validator: Validators.tituloQuehacer,
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F5EE),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE8E4DA)),
                        ),
                        child: Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.calendar_month_rounded,
                                    size: 18, color: Color(0xFF234E3F)),
                                const SizedBox(width: 8),
                                Text(
                                  fechaSeleccionada == null
                                      ? 'Sin fecha límite'
                                      : '${fechaSeleccionada!.day.toString().padLeft(2, '0')}/${fechaSeleccionada!.month.toString().padLeft(2, '0')}/${fechaSeleccionada!.year}',
                                  key: const Key('texto_fecha_edicion'),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Wrap(
                              spacing: 6,
                              children: [
                                if (fechaSeleccionada != null)
                                  IconButton(
                                    key: const Key(
                                        'boton_quitar_fecha_edicion'),
                                    icon: const Icon(Icons.close_rounded,
                                        size: 18, color: Colors.redAccent),
                                    onPressed: () {
                                      setModalState(() {
                                        fechaSeleccionada = null;
                                      });
                                    },
                                  ),
                                FilledButton.tonal(
                                  key: const Key(
                                      'boton_editar_fecha_quehacer'),
                                  onPressed: elegirFecha,
                                  child: Text(fechaSeleccionada == null
                                      ? 'Elegir fecha'
                                      : 'Cambiar'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Material(
                        color: const Color(0xFFF7F5EE),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: const BorderSide(color: Color(0xFFE8E4DA)),
                        ),
                        child: SwitchListTile(
                          key: const Key('switch_recurrente_edicion'),
                          title: const Text(
                            'Repetir cada semana (rota entre integrantes)',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          value: recurrente,
                          activeThumbColor: const Color(0xFF234E3F),
                          onChanged: (val) {
                            setModalState(() {
                              recurrente = val;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                      FilledButton(
                        key: const Key('boton_guardar_edicion_quehacer'),
                        onPressed: guardando
                            ? null
                            : () async {
                                if (!(formKey.currentState?.validate() ??
                                    false)) {
                                  return;
                                }
                                setModalState(() => guardando = true);
                                try {
                                  await _quehaceres.actualizarQuehacer(
                                    quehacerId: quehacer.id,
                                    titulo: tituloCtrl.text.trim(),
                                    fechaLimite: fechaSeleccionada,
                                    limpiarFecha: fechaSeleccionada == null,
                                    esAdmin: esAdmin,
                                    recurrente: recurrente,
                                  );
                                  if (!ctx.mounted) return;
                                  Navigator.of(ctx).pop();
                                  if (!mounted) return;
                                  AppFeedback.mostrarExito(
                                    context,
                                    'Quehacer actualizado',
                                  );
                                } on QuehaceresException catch (e) {
                                  if (!ctx.mounted) return;
                                  setModalState(() => guardando = false);
                                  AppFeedback.mostrarError(ctx, e.mensaje);
                                } catch (_) {
                                  if (!ctx.mounted) return;
                                  setModalState(() => guardando = false);
                                  AppFeedback.mostrarError(
                                    ctx,
                                    QuehaceresService.msgErrorActualizar,
                                  );
                                }
                              },
                        child: guardando
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Guardar cambios'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _mostrarDialogoReasignarQuehacer(
      Quehacer quehacer, List<Integrante> integrantes, bool esAdmin) async {
    if (!esAdmin) {
      AppFeedback.mostrarError(context, QuehaceresService.msgSinPermiso);
      return;
    }

    String? seleccionado = quehacer.asignadoA;
    if (!integrantes.any((i) => i.uid == seleccionado) &&
        integrantes.isNotEmpty) {
      seleccionado = integrantes.first.uid;
    }

    final reasignar = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.swap_horiz_rounded, color: Color(0xFFB45309)),
              SizedBox(width: 8),
              Text(
                'Reasignar quehacer',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Selecciona el nuevo responsable para "${quehacer.titulo}":',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                key: const Key('dropdown_reasignar_integrante'),
                initialValue: seleccionado,
                decoration: const InputDecoration(
                  labelText: 'Nuevo responsable',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
                items: integrantes.map((i) {
                  return DropdownMenuItem<String>(
                    value: i.uid,
                    child: Text(i.nombre),
                  );
                }).toList(),
                onChanged: (val) {
                  setDialogState(() {
                    seleccionado = val;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              key: const Key('boton_cancelar_reasignar'),
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              key: const Key('boton_confirmar_reasignar'),
              onPressed: () => Navigator.of(ctx).pop(seleccionado),
              child: const Text('Reasignar'),
            ),
          ],
        ),
      ),
    );

    if (reasignar != null && reasignar.isNotEmpty && mounted) {
      try {
        await _quehaceres.reasignarQuehacer(
          quehacerId: quehacer.id,
          nuevoAsignadoA: reasignar,
          hogarId: quehacer.hogarId,
          esAdmin: esAdmin,
        );
        if (!mounted) return;
        AppFeedback.mostrarExito(context, 'Quehacer reasignado');
      } on QuehaceresException catch (e) {
        if (!mounted) return;
        AppFeedback.mostrarError(context, e.mensaje);
      } catch (_) {
        if (!mounted) return;
        AppFeedback.mostrarError(
            context, QuehaceresService.msgErrorActualizar);
      }
    }
  }

  Future<void> _confirmarEliminarQuehacer(
      Quehacer quehacer, bool esAdmin) async {
    if (!esAdmin) {
      AppFeedback.mostrarError(context, QuehaceresService.msgSinPermiso);
      return;
    }

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
            SizedBox(width: 8),
            Text(
              'Eliminar quehacer',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: Text(
          '¿Seguro que quieres eliminar este quehacer ("${quehacer.titulo}")?',
          key: const Key('mensaje_confirmar_eliminar_quehacer'),
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            key: const Key('boton_cancelar_eliminar_quehacer'),
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            key: const Key('boton_confirmar_eliminar_quehacer'),
            style:
                FilledButton.styleFrom(backgroundColor: const Color(0xFFC24134)),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar == true && mounted) {
      try {
        await _quehaceres.eliminarQuehacer(
          quehacerId: quehacer.id,
          esAdmin: esAdmin,
        );
        if (!mounted) return;
        AppFeedback.mostrarInfo(context, 'Quehacer eliminado');
      } on QuehaceresException catch (e) {
        if (!mounted) return;
        AppFeedback.mostrarError(context, e.mensaje);
      } catch (_) {
        if (!mounted) return;
        AppFeedback.mostrarError(
            context, QuehaceresService.msgErrorEliminar);
      }
    }
  }

  Widget _buildVistaQuehaceres(ThemeData tema, String hogarId) {
    final uidActual = widget.usuarioActualId ?? _usuarios.usuarioActualId ?? '';

    return StreamBuilder<List<Integrante>>(
      stream: _obtenerIntegrantesStream(hogarId),
      builder: (context, integrantesSnap) {
        final integrantes = integrantesSnap.data ?? [];
        final integrantesMap = {for (var i in integrantes) i.uid: i.nombre};
        final esAdmin = widget.esAdministrador ??
            integrantes.any((i) => i.uid == uidActual && i.esAdministrador);

        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            scrolledUnderElevation: 0,
            elevation: 0,
            title: const Text(
              'Quehaceres',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            actions: [
              IconButton(
                key: const Key('boton_perfil_hogar_quehaceres'),
                tooltip: 'Perfil del hogar',
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFE8E4DA)),
                  ),
                  child: Icon(
                    Icons.group_rounded,
                    size: 20,
                    color: tema.colorScheme.primary,
                  ),
                ),
                onPressed: () =>
                    Navigator.of(context).pushNamed(AppRoutes.perfilHogar),
              ),
              IconButton(
                key: const Key('boton_mi_perfil_quehaceres'),
                tooltip: 'Mi perfil',
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFE8E4DA)),
                  ),
                  child: Icon(
                    Icons.person_outline_rounded,
                    size: 20,
                    color: tema.colorScheme.primary,
                  ),
                ),
                onPressed: () =>
                    Navigator.of(context).pushNamed(AppRoutes.editarPerfil),
              ),
              const SizedBox(width: 8),
            ],
          ),
          bottomNavigationBar: _crearBottomNav(),
          floatingActionButton: esAdmin
              ? FloatingActionButton.extended(
                  key: const Key('boton_agregar_quehacer'),
                  tooltip: 'Agregar quehacer',
                  backgroundColor: tema.colorScheme.primary,
                  foregroundColor: Colors.white,
                  elevation: 4,
                  onPressed: () async {
                    await Navigator.of(context)
                        .pushNamed(AppRoutes.agregarQuehacer);
                  },
                  icon: const Icon(Icons.add_rounded, size: 24),
                  label: const Text(
                    'Agregar',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                )
              : null,
          body: SafeArea(
            child: StreamBuilder<List<Quehacer>>(
              stream: _obtenerQuehaceresStream(hogarId),
              builder: (context, quehaceresSnap) {
                if (quehaceresSnap.hasError) {
                  return const Center(
                    child: Text(QuehaceresService.msgErrorCargar),
                  );
                }

                if (!quehaceresSnap.hasData &&
                    quehaceresSnap.connectionState != ConnectionState.active) {
                  return const Center(child: CircularProgressIndicator());
                }

                final todos = quehaceresSnap.data ?? [];
                final misQuehaceres =
                    todos.where((q) => q.asignadoA == uidActual).toList();
                final lista =
                    _filtroQuehaceres == 'mis' ? misQuehaceres : todos;

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFEBE7DD),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.all(4),
                        child: Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                key: const Key('filtro_mis_quehaceres'),
                                borderRadius: BorderRadius.circular(12),
                                onTap: () =>
                                    setState(() => _filtroQuehaceres = 'mis'),
                                child: Container(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: _filtroQuehaceres == 'mis'
                                        ? Colors.white
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: _filtroQuehaceres == 'mis'
                                        ? const [
                                            BoxShadow(
                                              color: Color(0x10000000),
                                              blurRadius: 4,
                                              offset: Offset(0, 2),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Text(
                                    'Mis quehaceres',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: _filtroQuehaceres == 'mis'
                                          ? tema.colorScheme.primary
                                          : Colors.black54,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: InkWell(
                                key: const Key('filtro_todos_quehaceres'),
                                borderRadius: BorderRadius.circular(12),
                                onTap: () => setState(
                                    () => _filtroQuehaceres = 'todos'),
                                child: Container(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: _filtroQuehaceres == 'todos'
                                        ? Colors.white
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: _filtroQuehaceres == 'todos'
                                        ? const [
                                            BoxShadow(
                                              color: Color(0x10000000),
                                              blurRadius: 4,
                                              offset: Offset(0, 2),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Text(
                                    'Todos los del hogar',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: _filtroQuehaceres == 'todos'
                                          ? tema.colorScheme.primary
                                          : Colors.black54,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: lista.isEmpty
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(24),
                                child: Text(
                                  'Aún no hay quehaceres',
                                  key: Key('estado_vacio_quehaceres'),
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.black54,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              itemCount: lista.length,
                              itemBuilder: (context, index) {
                                final q = lista[index];
                                final responsable =
                                    integrantesMap[q.asignadoA] ?? 'Integrante';
                                final esResponsable = (q.asignadoA == uidActual);

                                return Card(
                                  key: Key('item_quehacer_${q.id}'),
                                  margin: const EdgeInsets.only(bottom: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    side: const BorderSide(
                                        color: Color(0xFFE8E4DA)),
                                  ),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(16),
                                    onTap: () => _cambiarEstadoQuehacer(
                                        q, responsable),
                                    onLongPress: () =>
                                        _mostrarMenuOpcionesQuehacer(
                                            q, integrantes, esAdmin),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(top: 2),
                                            child: Checkbox(
                                              key: Key(
                                                  'checkbox_quehacer_${q.id}'),
                                              value: q.hecho,
                                              activeColor:
                                                  const Color(0xFF234E3F),
                                              onChanged: esResponsable
                                                  ? (_) =>
                                                      _cambiarEstadoQuehacer(
                                                          q, responsable)
                                                  : null,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Wrap(
                                                  alignment: WrapAlignment
                                                      .spaceBetween,
                                                  crossAxisAlignment:
                                                      WrapCrossAlignment
                                                          .center,
                                                  spacing: 8,
                                                  runSpacing: 4,
                                                  children: [
                                                    Text(
                                                      q.titulo,
                                                      key: Key(
                                                          'titulo_quehacer_${q.id}'),
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        decoration: q.hecho
                                                            ? TextDecoration
                                                                .lineThrough
                                                            : null,
                                                        color: q.hecho
                                                            ? Colors.black45
                                                            : const Color(
                                                                0xFF1E2D27),
                                                      ),
                                                    ),
                                                    Container(
                                                       key: Key(
                                                           'badge_estado_${q.id}'),
                                                       padding: const EdgeInsets
                                                           .symmetric(
                                                           horizontal: 10,
                                                           vertical: 4),
                                                       decoration:
                                                           BoxDecoration(
                                                         color: q.hecho
                                                             ? const Color(
                                                                 0xFFE8F1EC)
                                                             : const Color(
                                                                 0xFFFEF3C7),
                                                         borderRadius:
                                                             BorderRadius
                                                                 .circular(12),
                                                       ),
                                                       child: Wrap(
                                                         crossAxisAlignment:
                                                             WrapCrossAlignment
                                                                 .center,
                                                         spacing: 4,
                                                         children: [
                                                           Icon(
                                                             q.hecho
                                                                 ? Icons
                                                                     .check_circle_rounded
                                                                 : Icons
                                                                     .pending_actions_rounded,
                                                             size: 16,
                                                             color: q.hecho
                                                                 ? const Color(
                                                                     0xFF234E3F)
                                                                 : const Color(
                                                                     0xFFB45309),
                                                           ),
                                                           Text(
                                                             q.hecho
                                                                 ? 'Hecho'
                                                                 : 'Pendiente',
                                                             key: Key(
                                                                 'texto_estado_${q.id}'),
                                                             style: TextStyle(
                                                               fontSize: 12,
                                                               fontWeight:
                                                                   FontWeight
                                                                       .bold,
                                                               color: q.hecho
                                                                   ? const Color(
                                                                       0xFF234E3F)
                                                                   : const Color(
                                                                       0xFFB45309),
                                                             ),
                                                           ),
                                                         ],
                                                       ),
                                                     ),
                                                     if (q.recurrente)
                                                       Container(
                                                         key: Key(
                                                             'badge_recurrente_${q.id}'),
                                                         padding:
                                                             const EdgeInsets
                                                                 .symmetric(
                                                           horizontal: 8,
                                                           vertical: 3,
                                                         ),
                                                         decoration:
                                                             BoxDecoration(
                                                           color: const Color(
                                                               0xFFE0F2FE),
                                                           borderRadius:
                                                               BorderRadius
                                                                   .circular(
                                                                       12),
                                                           border: Border.all(
                                                             color: const Color(
                                                                 0xFFBAE6FD),
                                                           ),
                                                         ),
                                                         child: const Wrap(
                                                           crossAxisAlignment:
                                                               WrapCrossAlignment
                                                                   .center,
                                                           spacing: 4,
                                                           children: [
                                                             Icon(
                                                               Icons
                                                                   .repeat_rounded,
                                                               size: 14,
                                                               color: Color(
                                                                   0xFF0369A1),
                                                             ),
                                                             Text(
                                                               'Semanal',
                                                               style: TextStyle(
                                                                 fontSize: 11,
                                                                 fontWeight:
                                                                     FontWeight
                                                                         .bold,
                                                                 color: Color(
                                                                     0xFF0369A1),
                                                               ),
                                                             ),
                                                           ],
                                                         ),
                                                       ),
                                                   ],
                                                 ),
                                                 const SizedBox(height: 10),
                                                Wrap(
                                                  spacing: 16,
                                                  runSpacing: 6,
                                                  crossAxisAlignment:
                                                      WrapCrossAlignment
                                                          .center,
                                                  children: [
                                                    Wrap(
                                                      crossAxisAlignment:
                                                          WrapCrossAlignment
                                                              .center,
                                                      spacing: 4,
                                                      children: [
                                                        const Icon(
                                                          Icons
                                                              .person_outline_rounded,
                                                          size: 16,
                                                          color:
                                                              Colors.black54,
                                                        ),
                                                        Text(
                                                          responsable,
                                                          key: Key(
                                                              'responsable_quehacer_${q.id}'),
                                                          style:
                                                              const TextStyle(
                                                            fontSize: 13,
                                                            color:
                                                                Colors.black87,
                                                            fontWeight:
                                                                FontWeight
                                                                    .w500,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    if (q.fechaLimite != null)
                                                      Wrap(
                                                        crossAxisAlignment:
                                                            WrapCrossAlignment
                                                                .center,
                                                        spacing: 4,
                                                        children: [
                                                          const Icon(
                                                            Icons
                                                                .calendar_today_outlined,
                                                            size: 14,
                                                            color:
                                                                Colors.black54,
                                                          ),
                                                          Text(
                                                            '${q.fechaLimite!.day.toString().padLeft(2, '0')}/${q.fechaLimite!.month.toString().padLeft(2, '0')}/${q.fechaLimite!.year}',
                                                            key: Key(
                                                                'fecha_quehacer_${q.id}'),
                                                            style:
                                                                const TextStyle(
                                                              fontSize: 13,
                                                              color: Colors
                                                                  .black87,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (esAdmin)
                                            IconButton(
                                              key: Key(
                                                  'boton_opciones_quehacer_${q.id}'),
                                              tooltip: 'Opciones del quehacer',
                                              icon: const Icon(
                                                Icons.more_vert_rounded,
                                                size: 20,
                                                color: Colors.black45,
                                              ),
                                              onPressed: () =>
                                                  _mostrarMenuOpcionesQuehacer(
                                                      q,
                                                      integrantes,
                                                      esAdmin),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _ProgresoComprasBanner extends StatelessWidget {
  const _ProgresoComprasBanner({
    required this.comprados,
    required this.total,
  });

  final int comprados;
  final int total;

  @override
  Widget build(BuildContext context) {
    final porcentaje = total > 0 ? (comprados / total) : 0.0;
    final completado = comprados == total && total > 0;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 10, 20, 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: completado ? const Color(0xFFBBE5D0) : const Color(0xFFE8E4DA),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                completado ? Icons.celebration_rounded : Icons.shopping_cart_checkout_rounded,
                size: 20,
                color: completado ? const Color(0xFF1E4D3E) : const Color(0xFF3D705F),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  completado
                      ? '¡Todo comprado! La despensa está lista 🎉'
                      : 'Progreso de compras: $comprados de $total listos',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: completado ? const Color(0xFF1E4D3E) : Colors.black87,
                  ),
                ),
              ),
              Text(
                '${(porcentaje * 100).toInt()}%',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E4D3E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: porcentaje,
              minHeight: 6,
              backgroundColor: const Color(0xFFECEAE4),
              valueColor: AlwaysStoppedAnimation<Color>(
                completado ? Colors.green : const Color(0xFF1E4D3E),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _TipoLista { pendientes, comprados }

class _ListaProductos extends StatelessWidget {
  const _ListaProductos({
    required this.productos,
    required this.tipo,
    required this.onToggle,
    required this.onDelete,
    required this.onLongPress,
  });

  final List<Producto> productos;
  final _TipoLista tipo;
  final ValueChanged<Producto> onToggle;
  final ValueChanged<Producto> onDelete;
  final ValueChanged<Producto> onLongPress;

  @override
  Widget build(BuildContext context) {
    if (productos.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE8E4DA)),
                ),
                child: Icon(
                  tipo == _TipoLista.pendientes
                      ? Icons.task_alt_rounded
                      : Icons.shopping_bag_outlined,
                  size: 44,
                  color: tipo == _TipoLista.pendientes
                      ? const Color(0xFF234E3F)
                      : Colors.black45,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                tipo == _TipoLista.pendientes
                    ? '¡No hay productos pendientes!'
                    : 'Aún no has marcado productos como comprados',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                tipo == _TipoLista.pendientes
                    ? 'Todos los productos de la lista ya fueron comprados.'
                    : 'Marca los productos de la pestaña "Pendientes" al comprarlos.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: Colors.black54),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 90),
      itemCount: productos.length,
      itemBuilder: (context, index) {
        final producto = productos[index];
        return _ProductoCard(
          producto: producto,
          onToggle: () => onToggle(producto),
          onDelete: () => onDelete(producto),
          onLongPress: () => onLongPress(producto),
        );
      },
    );
  }
}

class _ProductoCard extends StatelessWidget {
  const _ProductoCard({
    required this.producto,
    required this.onToggle,
    required this.onDelete,
    required this.onLongPress,
  });

  final Producto producto;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esComprado = producto.comprado;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      color: esComprado ? const Color(0xFFF0EDE5) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: esComprado ? const Color(0xFFDFD9CD) : const Color(0xFFE8E4DA),
          width: 1,
        ),
      ),
      child: InkWell(
        key: Key('tile_${producto.id}'),
        borderRadius: BorderRadius.circular(16),
        onTap: onToggle,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Transform.scale(
                scale: 1.1,
                child: Checkbox(
                  key: Key('checkbox_${producto.id}'),
                  value: esComprado,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  activeColor: tema.colorScheme.primary,
                  onChanged: (_) => onToggle(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      producto.nombre,
                      key: Key('nombre_${producto.id}'),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: esComprado ? Colors.black45 : const Color(0xFF1C2C26),
                        decoration: esComprado
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                      ),
                    ),
                    if (producto.cantidad > 0) ...[
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(
                            Icons.format_list_numbered_rounded,
                            size: 14,
                            color: esComprado
                                ? Colors.black38
                                : tema.colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Cantidad: ${producto.cantidad}',
                            key: Key('cantidad_${producto.id}'),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: esComprado
                                  ? Colors.black38
                                  : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (esComprado)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0x1F4CAF50),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_rounded, size: 14, color: Colors.green),
                      SizedBox(width: 4),
                      Text(
                        'Comprado',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              IconButton(
                tooltip: 'Eliminar de la lista',
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  size: 20,
                  color: Colors.black38,
                ),
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EstadoVacioGlobal extends StatelessWidget {
  const _EstadoVacioGlobal();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE8E4DA)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 16,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.shopping_basket_outlined,
                size: 64,
                color: Color(0xFF234E3F),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Aún no hay productos en la lista',
              key: Key('mensaje_lista_vacia'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF234E3F),
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Toca el botón (+ Agregar) para registrar lo que haga falta en casa. Todo se sincroniza en vivo.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.black54,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
