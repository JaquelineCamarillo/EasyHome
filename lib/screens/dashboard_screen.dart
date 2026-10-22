import 'package:flutter/material.dart';

import '../models/producto.dart';
import '../routes.dart';
import '../services/compras_service.dart';
import '../services/hogar_service.dart';

/// Pantalla #9 — Dashboard de compras en tiempo real.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    this.hogarId,
    this.comprasService,
    this.hogarService,
  });

  /// Si no se especifica, se consulta del usuario actual.
  final String? hogarId;

  /// Inyectable para pruebas; por defecto usa Firebase real.
  final ComprasService? comprasService;
  final HogarService? hogarService;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final ComprasService _compras =
      widget.comprasService ?? ComprasService();
  late final HogarService _hogares =
      widget.hogarService ?? HogarService();

  Stream<List<Producto>>? _productosStream;
  String? _error;
  bool _cargandoInicial = true;

  @override
  void initState() {
    super.initState();
    _iniciar();
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
        _productosStream = _compras.observarProductos(hogarId);
        _cargandoInicial = false;
      });
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

  Future<void> _cambiarEstadoProducto(Producto producto) async {
    final nuevoEstado = !producto.comprado;
    try {
      await _compras.cambiarEstado(
        productoId: producto.id,
        comprado: nuevoEstado,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            nuevoEstado
                ? '"${producto.nombre}" marcado como comprado'
                : '"${producto.nombre}" movido a pendientes',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(ComprasService.msgErrorActualizar),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _eliminarProducto(Producto producto) async {
    try {
      await _compras.eliminarProducto(producto.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Se eliminó "${producto.nombre}"'),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(ComprasService.msgSinConexion),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _irAAgregarProducto() {
    Navigator.of(context).pushNamed(AppRoutes.agregarProducto);
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
        final pendientes = todos.where((p) => !p.comprado).toList();
        final comprados = todos.where((p) => p.comprado).toList();

        return DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              scrolledUnderElevation: 0,
              elevation: 0,
              title: const Text(
                'Lista de compras',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              actions: [
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
                  : TabBarView(
                      children: [
                        _ListaProductos(
                          productos: pendientes,
                          tipo: _TipoLista.pendientes,
                          onToggle: _cambiarEstadoProducto,
                          onDelete: _eliminarProducto,
                        ),
                        _ListaProductos(
                          productos: comprados,
                          tipo: _TipoLista.comprados,
                          onToggle: _cambiarEstadoProducto,
                          onDelete: _eliminarProducto,
                        ),
                      ],
                    ),
            ),
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
}

enum _TipoLista { pendientes, comprados }

class _ListaProductos extends StatelessWidget {
  const _ListaProductos({
    required this.productos,
    required this.tipo,
    required this.onToggle,
    required this.onDelete,
  });

  final List<Producto> productos;
  final _TipoLista tipo;
  final ValueChanged<Producto> onToggle;
  final ValueChanged<Producto> onDelete;

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
  });

  final Producto producto;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

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
