import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/hogar.dart';
import '../models/integrante.dart';
import '../services/hogar_service.dart';

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
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(
        content: Text('Código copiado'),
        duration: Duration(seconds: 2),
      ));
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
                  style: Theme.of(context).textTheme.titleSmall,
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
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: tema.colorScheme.primary,
            foregroundColor: Colors.white,
            child: Text(inicial),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              integrante.nombre,
              style: tema.textTheme.titleMedium,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (integrante.esAdministrador)
            Container(
              key: const Key('etiqueta_admin'),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF6E3C3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star_rounded, size: 16, color: Color(0xFF9A5B00)),
                  SizedBox(width: 4),
                  Text(
                    'Admin',
                    style: TextStyle(
                      color: Color(0xFF9A5B00),
                      fontWeight: FontWeight.bold,
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
        borderRadius: BorderRadius.circular(16),
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