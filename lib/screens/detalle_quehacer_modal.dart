import 'package:flutter/material.dart';

import '../models/comentario.dart';
import '../models/quehacer.dart';
import '../services/quehaceres_service.dart';
import '../utils/app_feedback.dart';

/// Modal con el detalle completo de un quehacer y su hilo de comentarios en tiempo real (#Requerimiento 1 Retro).
class DetalleQuehacerModal extends StatefulWidget {
  const DetalleQuehacerModal({
    super.key,
    required this.quehacer,
    required this.responsableNombre,
    required this.quehaceresService,
    this.usuarioActualNombre,
  });

  final Quehacer quehacer;
  final String responsableNombre;
  final QuehaceresService quehaceresService;
  final String? usuarioActualNombre;

  /// Muestra el modal ocupando hasta el 85% de la pantalla para máxima comodidad al escribir comentarios.
  static Future<void> mostrar({
    required BuildContext context,
    required Quehacer quehacer,
    required String responsableNombre,
    required QuehaceresService quehaceresService,
    String? usuarioActualNombre,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: DetalleQuehacerModal(
            quehacer: quehacer,
            responsableNombre: responsableNombre,
            quehaceresService: quehaceresService,
            usuarioActualNombre: usuarioActualNombre,
          ),
        ),
      ),
    );
  }

  @override
  State<DetalleQuehacerModal> createState() => _DetalleQuehacerModalState();
}

class _DetalleQuehacerModalState extends State<DetalleQuehacerModal> {
  final _textoCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _enviando = false;
  String? _errorTexto;

  @override
  void dispose() {
    _textoCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  String _formatearFechaHora(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = dt.year.toString();
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$d/$m/$y, $h:$min';
  }

  Future<void> _enviarComentario() async {
    final texto = _textoCtrl.text.trim();
    if (texto.isEmpty) {
      setState(() => _errorTexto = QuehaceresService.msgComentarioVacio);
      return;
    }
    if (texto.length > 300) {
      setState(() => _errorTexto = QuehaceresService.msgComentarioLargo);
      return;
    }

    setState(() {
      _enviando = true;
      _errorTexto = null;
    });

    try {
      await widget.quehaceresService.agregarComentario(
        quehacerId: widget.quehacer.id,
        texto: texto,
        autorNombre: widget.usuarioActualNombre,
      );
      _textoCtrl.clear();

      // Scroll suave hacia el final (el más reciente)
      if (_scrollCtrl.hasClients) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollCtrl.hasClients) {
            _scrollCtrl.animateTo(
              _scrollCtrl.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    } on QuehaceresException catch (e) {
      if (mounted) {
        AppFeedback.mostrarError(context, e.mensaje);
      }
    } catch (_) {
      if (mounted) {
        AppFeedback.mostrarError(context, QuehaceresService.msgSinConexion);
      }
    } finally {
      if (mounted) {
        setState(() => _enviando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.quehacer;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        top: false,
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          decoration: const BoxDecoration(
            color: Color(0xFFF7F5EE),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
          // Barra de agarre
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 44,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(10),
            ),
          ),

          // Encabezado del modal
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        q.titulo,
                        key: const Key('detalle_titulo_quehacer'),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E2D27),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          // Estado
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: q.hecho
                                  ? const Color(0xFFE8F1EC)
                                  : const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  q.hecho
                                      ? Icons.check_circle_rounded
                                      : Icons.pending_actions_rounded,
                                  size: 14,
                                  color: q.hecho
                                      ? const Color(0xFF234E3F)
                                      : const Color(0xFFB45309),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  q.hecho ? 'Hecho' : 'Pendiente',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: q.hecho
                                        ? const Color(0xFF234E3F)
                                        : const Color(0xFFB45309),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Recurrente
                          if (q.recurrente)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE0F2FE),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.repeat_rounded,
                                      size: 14, color: Color(0xFF0369A1)),
                                  SizedBox(width: 4),
                                  Text(
                                    'Semanal',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0369A1),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          // Responsable
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.black12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.person_outline_rounded,
                                    size: 14, color: Colors.black54),
                                const SizedBox(width: 4),
                                Text(
                                  widget.responsableNombre,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  key: const Key('boton_cerrar_detalle_quehacer'),
                  icon: const Icon(Icons.close_rounded, color: Colors.black54),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFFE5E0D4)),

          // Lista de comentarios (más antiguo a más reciente)
          Expanded(
            child: StreamBuilder<List<Comentario>>(
              stream: widget.quehaceresService.observarComentarios(q.id),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting &&
                    !snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final comentarios = snap.data ?? [];
                if (comentarios.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 48,
                            color: Colors.black26,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'No hay comentarios aún',
                            key: Key('estado_vacio_comentarios'),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Escribe un aviso o aclaración para los demás integrantes del hogar.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13, color: Colors.black45),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  key: const Key('lista_comentarios_quehacer'),
                  controller: _scrollCtrl,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: comentarios.length,
                  itemBuilder: (context, index) {
                    final c = comentarios[index];
                    final esMio = (c.autorId ==
                        widget.quehaceresService.usuarioActualId);

                    return Padding(
                      key: Key('item_comentario_${c.id}'),
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Nombre del autor y fecha/hora
                          Row(
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        c.autorNombre,
                                        key: Key('autor_comentario_${c.id}'),
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: Color(0xFF1E2D27),
                                        ),
                                      ),
                                    ),
                                    if (esMio) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF234E3F)
                                              .withValues(alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: const Text(
                                          'Tú',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF234E3F),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _formatearFechaHora(c.creadoEn),
                                key: Key('fecha_comentario_${c.id}'),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.black45,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          // Burbuja del comentario
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: esMio
                                    ? const Color(0xFF234E3F).withValues(alpha: 0.3)
                                    : const Color(0xFFE8E4DA),
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x08000000),
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              c.texto,
                              key: Key('texto_comentario_${c.id}'),
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF2C3E35),
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Campo de texto para agregar comentario (1 a 300 caracteres)
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Color(0xFFE5E0D4)),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_errorTexto != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      _errorTexto!,
                      key: const Key('error_comentario'),
                      style: const TextStyle(
                        color: Color(0xFFC24134),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextFormField(
                        key: const Key('campo_comentario'),
                        controller: _textoCtrl,
                        maxLength: 300,
                        maxLines: null,
                        keyboardType: TextInputType.multiline,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          hintText: 'Escribe un comentario (1 a 300 caracteres)...',
                          hintStyle: const TextStyle(fontSize: 13, color: Colors.black38),
                          counterText: '',
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          filled: true,
                          fillColor: const Color(0xFFF7F5EE),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (val) {
                          if (_errorTexto != null) {
                            setState(() => _errorTexto = null);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      key: const Key('boton_enviar_comentario'),
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFF234E3F),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: _enviando
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send_rounded, size: 20),
                      onPressed: _enviando ? null : _enviarComentario,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
    ),
    );
  }
}
