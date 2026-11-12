import 'package:flutter/material.dart';
import '../models/producto.dart';

/// Banner visual del progreso de la lista de compras del hogar.
class ProgresoComprasBanner extends StatelessWidget {
  const ProgresoComprasBanner({
    super.key,
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
                completado
                    ? Icons.celebration_rounded
                    : Icons.shopping_cart_checkout_rounded,
                size: 20,
                color:
                    completado ? const Color(0xFF1E4D3E) : const Color(0xFF3D705F),
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

/// Clasificación para las listas de productos de la despensa.
enum TipoListaProductos { pendientes, comprados }

/// Listado de productos organizados por estado.
class ListaProductos extends StatelessWidget {
  const ListaProductos({
    super.key,
    required this.productos,
    required this.tipo,
    required this.onToggle,
    required this.onDelete,
    required this.onLongPress,
  });

  final List<Producto> productos;
  final TipoListaProductos tipo;
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
                  tipo == TipoListaProductos.pendientes
                      ? Icons.task_alt_rounded
                      : Icons.shopping_bag_outlined,
                  size: 44,
                  color: tipo == TipoListaProductos.pendientes
                      ? const Color(0xFF234E3F)
                      : Colors.black45,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                tipo == TipoListaProductos.pendientes
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
                tipo == TipoListaProductos.pendientes
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
        return ProductoCard(
          producto: producto,
          onToggle: () => onToggle(producto),
          onDelete: () => onDelete(producto),
          onLongPress: () => onLongPress(producto),
        );
      },
    );
  }
}

/// Tarjeta reutilizable individual de un [Producto].
class ProductoCard extends StatelessWidget {
  const ProductoCard({
    super.key,
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
                        color:
                            esComprado ? Colors.black45 : const Color(0xFF1C2C26),
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

/// Estado visual cuando no existe ningún producto registrado en la despensa.
class EstadoVacioProductos extends StatelessWidget {
  const EstadoVacioProductos({super.key});

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
