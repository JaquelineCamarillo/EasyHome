import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/compras_service.dart';
import '../services/hogar_service.dart';
import '../utils/app_feedback.dart';
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
  final _cantidadCtrl = TextEditingController(text: '1');

  late final ComprasService _compras =
      widget.comprasService ?? ComprasService();
  late final HogarService _hogares =
      widget.hogarService ?? HogarService();

  bool _cargando = false;
  String? _errorGeneral;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _cantidadCtrl.dispose();
    super.dispose();
  }

  void _ajustarCantidad(int delta) {
    final actual = int.tryParse(_cantidadCtrl.text) ?? 1;
    final nuevo = actual + delta;
    if (nuevo >= 1) {
      setState(() {
        _cantidadCtrl.text = nuevo.toString();
        _errorGeneral = null;
      });
    }
  }

  void _limpiarFormulario() {
    _nombreCtrl.clear();
    _cantidadCtrl.text = '1';
  }

  Future<void> _guardarProducto() async {
    if (!(_formKey.currentState?.validate() ?? false) || _cargando) return;
    FocusScope.of(context).unfocus();

    final cantidadEntera = int.tryParse(_cantidadCtrl.text.trim());
    if (cantidadEntera == null || cantidadEntera <= 0) {
      return;
    }

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
        cantidad: cantidadEntera,
      );

      if (!mounted) return;

      // Limpiar formulario antes de regresar
      _limpiarFormulario();

      AppFeedback.mostrarExito(context, 'Producto agregado');

      // Regresar al dashboard (#9)
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
          'Agregar producto',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFE8E4DA)),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x06000000),
                            blurRadius: 12,
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
                              borderRadius: BorderRadius.circular(14),
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
                                    color: const Color(0xFF1E2D27),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Aparecerá de inmediato en el dashboard de compras para todos los integrantes.',
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
                        hintText: 'Ej. Leche, Manzanas, Huevos...',
                        prefixIcon: Icon(
                          Icons.shopping_bag_outlined,
                          color: tema.colorScheme.primary,
                        ),
                      ),
                      validator: Validators.nombreProducto,
                      onChanged: (_) => setState(() => _errorGeneral = null),
                    ),
                    const SizedBox(height: 18),
                    TextFormField(
                      key: const Key('campo_cantidad_producto'),
                      controller: _cantidadCtrl,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: InputDecoration(
                        labelText: 'Cantidad',
                        prefixIcon: Icon(
                          Icons.format_list_numbered_rounded,
                          color: tema.colorScheme.primary,
                        ),
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              key: const Key('boton_decrementar_cantidad'),
                              tooltip: 'Disminuir',
                              icon: const Icon(Icons.remove_circle_outline_rounded),
                              onPressed: () => _ajustarCantidad(-1),
                            ),
                            IconButton(
                              key: const Key('boton_incrementar_cantidad'),
                              tooltip: 'Aumentar',
                              icon: const Icon(Icons.add_circle_outline_rounded),
                              onPressed: () => _ajustarCantidad(1),
                            ),
                          ],
                        ),
                      ),
                      validator: Validators.cantidadProducto,
                      onChanged: (_) => setState(() => _errorGeneral = null),
                      onFieldSubmitted: (_) => _guardarProducto(),
                    ),
                    const SizedBox(height: 24),
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
                                key: const Key('error_general_producto'),
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
                      const SizedBox(height: 18),
                    ],
                    FilledButton(
                      key: const Key('boton_agregar'),
                      onPressed: _cargando ? null : _guardarProducto,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _cargando
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Agregar',
                              style: TextStyle(
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
