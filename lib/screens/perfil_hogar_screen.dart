import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/hogar.dart';
import '../models/integrante.dart';
import '../services/hogar_service.dart';
import '../utils/app_feedback.dart';

/// Pantalla #7 — Perfil del hogar: integrantes y código de invitación,
/// escuchando Firestore en tiempo real.
class PerfilHogarScreen extends StatefulWidget {
  const PerfilHogarScreen({super.key, this.hogarId, this.hogarService});

  /// Si no se pasa, se lee del documento del usuario actual.
  final String? hogarId;

  /// Inyectable para pruebas; por defecto usa Firebase real.
  final HogarService? hogarService;

  @override
  State<PerfilHogarScreen> createState() => _PerfilHogarScreenState();
}

class _PerfilHogarScreenState extends State<PerfilHogarScreen> {
  late final HogarService _hogares = widget.hogarService ?? HogarService();

  Stream<Hogar?>? _hogarStream;
  Stream<List<Integrante>>? _integrantesStream;
  String? _error;

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
        setState(() => _error = 'Todavía no perteneces a ningún hogar');
        return;
      }
      // Los streams se crean una sola vez (no dentro de build).
      setState(() {
        _hogarStream = _hogares.observarHogar(hogarId);
        _integrantesStream = _hogares.observarIntegrantes(hogarId);
      });
    } on HogarException catch (e) {
      if (mounted) setState(() => _error = e.mensaje);
    } catch (_) {
      if (mounted) setState(() => _error = HogarService.msgSinConexion);
    }
  }

  Future<void> _copiarCodigo(String codigo) async {
    await Clipboard.setData(ClipboardData(text: codigo));
    if (!mounted) return;
    AppFeedback.mostrarExito(context, 'Código copiado');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
      ),
      body: SafeArea(child: _cuerpo(context)),
    );
  }

  Widget _cuerpo(BuildContext context) {
    if (_error != null) return _Mensaje(_error!);
    final hogarStream = _hogarStream;
    final integrantesStream = _integrantesStream;
    if (hogarStream == null || integrantesStream == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return StreamBuilder<Hogar?>(
      stream: hogarStream,
      builder: (context, snap) {
        if (snap.hasError) return const _Mensaje('No se pudo cargar el hogar');
        if (!snap.hasData && snap.connectionState != ConnectionState.active) {
          return const Center(child: CircularProgressIndicator());
        }
        final hogar = snap.data;
        if (hogar == null) {
          return const _Mensaje('No se encontró tu hogar');
        }

        final tema = Theme.of(context);
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  hogar.nombre,
                  key: const Key('nombre_hogar'),
                  style: tema.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: tema.colorScheme.primary,
                  ),
                ),
              ),
            ),
            Expanded(child: _ListaIntegrantes(stream: integrantesStream)),
            _CodigoInvitacionBox(
              codigo: hogar.codigoInvitacion,
              onCopiar: () => _copiarCodigo(hogar.codigoInvitacion),
            ),
          ],
        );
      },
    );
  }
}

class _ListaIntegrantes extends StatelessWidget {
  const _ListaIntegrantes({required this.stream});

  final Stream<List<Integrante>> stream;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Integrante>>(
      stream: stream,
      builder: (context, snap) {
        if (snap.hasError) {
          return const _Mensaje('No se pudo cargar la lista de integrantes');
        }
        final integrantes = snap.data;
        if (integrantes == null) {
          // Aún cargando: spinner, no una lista vacía.
          return const Center(child: CircularProgressIndicator());
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          itemCount: integrantes.length + 1,
          itemBuilder: (context, i) {
            if (i == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Integrantes (${integrantes.length})',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.black54,
                      ),
                ),
              );
            }
            return _IntegranteTile(integrante: integrantes[i - 1]);
          },
        );
      },
    );
  }
}

class _IntegranteTile extends StatelessWidget {
  const _IntegranteTile({required this.integrante});

  final Integrante integrante;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final inicial = integrante.nombre.characters.first.toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8E4DA)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: tema.colorScheme.primary,
            foregroundColor: Colors.white,
            child: Text(
              inicial,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              integrante.nombre,
              style: tema.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (integrante.esAdministrador)
            Container(
              key: const Key('etiqueta_admin'),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFBF1DE),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE8BA6E)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star_rounded, size: 16, color: Color(0xFFB57000)),
                  SizedBox(width: 4),
                  Text(
                    'Admin',
                    style: TextStyle(
                      color: Color(0xFFB57000),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _CodigoInvitacionBox extends StatelessWidget {
  const _CodigoInvitacionBox({required this.codigo, required this.onCopiar});

  final String codigo;
  final VoidCallback onCopiar;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      padding: const EdgeInsets.fromLTRB(20, 16, 8, 16),
      decoration: BoxDecoration(
        color: tema.colorScheme.primary,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: tema.colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Código de invitación del hogar',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  codigo.isEmpty ? '—' : codigo,
                  key: const Key('codigo_invitacion'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 6,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            key: const Key('boton_copiar'),
            tooltip: 'Copiar código',
            color: Colors.white,
            icon: const Icon(Icons.copy_rounded),
            onPressed: codigo.isEmpty ? null : onCopiar,
          ),
        ],
      ),
    );
  }
}

class _Mensaje extends StatelessWidget {
  const _Mensaje(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(texto, textAlign: TextAlign.center),
      ),
    );
  }
}
