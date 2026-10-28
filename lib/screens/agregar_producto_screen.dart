import 'package:flutter/material.dart';

import '../services/compras_service.dart';
import '../services/hogar_service.dart';
import '../utils/validators.dart';

/// Pantalla #10 — Formulario para agregar un nuevo producto a la lista de compras.
class AgregarProductoScreen extends StatefulWidget {
  const AgregarProductoScreen({
    super.key,
    this.hogarId,
    this.comprasService,
    this.hogarService,
  });

  final String? hogarId;
  final ComprasService? comprasService;
  final HogarService? hogarService;

  @override
  State<AgregarProductoScreen> createState() => _AgregarProductoScreenState();
}

class _AgregarProductoScreenState extends State<AgregarProductoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _cantidadCtrl = TextEditingController();

  late final ComprasService _compras =
      widget.comprasService ?? ComprasService();
  late final HogarService _hogares =
      widget.hogarService ?? HogarService();

  bool _cargando = false;
  String? _errorGeneral;

  static const List<String> _sugerenciasCantidad = [
    '1 unidad',
    '2 unidades',
    '1 kg',
    '500 gr',
    '1 litro',
    '1 paquete',
    '1 caja',
  ];

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _cantidadCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardarProducto() async {
    if (!(_formKey.currentState?.validate() ?? false) || _cargando) return;
    FocusScope.of(context).unfocus();

    setState(() {
      _cargando = true;
      _errorGeneral = null;
    });

    try {
      final hogarId = widget.hogarId ?? await _hogares.obtenerHogarIdActual();
      if (hogarId == null) {
        if (!mounted) return;
        setState(() {
          _errorGeneral = 'No se encontró el hogar actual';
          _cargando = false;
        });
        return;
      }

      await _compras.agregarProducto(
        hogarId: hogarId,
        nombre: _nombreCtrl.text,
        cantidad: _cantidadCtrl.text,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Producto agregado con éxito'),
          backgroundColor: Color(0xFF2F5446),
          duration: Duration(seconds: 2),
        ),
      );
      Navigator.of(context).pop(true);
    } on ComprasException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorGeneral = e.mensaje;
        _cargando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorGeneral = ComprasService.msgErrorAgregar;
        _cargando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
        title: const Text(
          'Agregar a la lista',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x0A000000),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: tema.colorScheme.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.add_shopping_cart_rounded,
                              color: tema.colorScheme.primary,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Nuevo producto',
                                  style: tema.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Se sincronizará en tiempo real con todos los integrantes de tu hogar.',
                                  style: tema.textTheme.bodySmall?.copyWith(
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      key: const Key('campo_nombre_producto'),
                      controller: _nombreCtrl,
                      autofocus: true,
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'Nombre del producto',
                        hintText: 'Ej. Leche deslactosada, Manzanas...',
                        prefixIcon: Icon(
                          Icons.shopping_bag_outlined,
                          color: tema.colorScheme.primary,
                        ),
                      ),
                      validator: Validators.nombreProducto,
                      onChanged: (_) => setState(() => _errorGeneral = null),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      key: const Key('campo_cantidad_producto'),
                      controller: _cantidadCtrl,
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        labelText: 'Cantidad o presentación',
                        hintText: 'Ej. 2 litros, 1 kg, 6 piezas...',
                        prefixIcon: Icon(
                          Icons.format_list_numbered_rounded,
                          color: tema.colorScheme.primary,
                        ),
                      ),
                      validator: Validators.cantidadProducto,
                      onChanged: (_) => setState(() => _errorGeneral = null),
                      onFieldSubmitted: (_) => _guardarProducto(),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: _sugerenciasCantidad.map((sug) {
                        return ActionChip(
                          label: Text(
                            sug,
                            style: const TextStyle(fontSize: 12),
                          ),
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: const BorderSide(
                              color: Color(0x22000000),
                              width: 1,
                            ),
                          ),
                          onPressed: () {
                            setState(() {
                              _cantidadCtrl.text = sug;
                              _errorGeneral = null;
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    if (_errorGeneral != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: tema.colorScheme.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _errorGeneral!,
                          key: const Key('error_general_producto'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: tema.colorScheme.error,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    FilledButton.icon(
                      key: const Key('boton_guardar_producto'),
                      onPressed: _cargando ? null : _guardarProducto,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: _cargando
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check_rounded),
                      label: Text(
                        _cargando ? 'Guardando...' : 'Agregar a la lista',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
