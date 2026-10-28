import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/hogar.dart';
import '../models/integrante.dart';
import '../routes.dart';
import '../services/hogar_service.dart';
import '../services/usuario_service.dart';
import '../utils/app_feedback.dart';

/// Pantalla #7 — Perfil del hogar: integrantes y código de invitación,
/// escuchando Firestore en tiempo real.
class PerfilHogarScreen extends StatefulWidget {
  const PerfilHogarScreen({
    super.key,
    this.hogarId,
    this.hogarService,
    this.usuarioService,
  });

  /// Si no se pasa, se lee del documento del usuario actual.
  final String? hogarId;

  /// Inyectable para pruebas; por defecto usa Firebase real.
  final HogarService? hogarService;
  final UsuarioService? usuarioService;

  @override
  State<PerfilHogarScreen> createState() => _PerfilHogarScreenState();
}

class _PerfilHogarScreenState extends State<PerfilHogarScreen> {
  late final HogarService _hogares = widget.hogarService ?? HogarService();
  late final UsuarioService _usuarios =
      widget.usuarioService ?? UsuarioService();

  Stream<Hogar?>? _hogarStream;
  Stream<List<Integrante>>? _integrantesStream;
  String? _error;
  String? _hogarIdResuelto;

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
      _hogarIdResuelto = hogarId;
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

  Future<void> _confirmarRegenerarCodigo() async {
    final hogarId = _hogarIdResuelto;
    if (hogarId == null) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.refresh_rounded, color: Color(0xFF234E3F)),
            SizedBox(width: 8),
            Text(
              'Regenerar código',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: const Text(
          '¿Deseas generar un nuevo código de invitación? '
          'El código actual dejará de funcionar para nuevos integrantes.',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Generar nuevo'),
          ),
        ],
      ),
    );

    if (confirmar == true && mounted) {
      try {
        final nuevoCodigo = await _usuarios.regenerarCodigoHogar(hogarId);
        if (!mounted) return;
        AppFeedback.mostrarExito(
          context,
          'Nuevo código generado: $nuevoCodigo',
        );
      } catch (_) {
        if (!mounted) return;
        AppFeedback.mostrarError(
          context,
          'No se pudo generar el nuevo código',
        );
      }
    }
  }

  Future<void> _confirmarCerrarSesion() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: Color(0xFFC24134)),
            SizedBox(width: 8),
            Text(
              'Cerrar sesión',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: const Text(
          '¿Estás seguro de que deseas salir de tu cuenta?',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFC24134)),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );

    if (confirmar == true && mounted) {
      await _hogares.cerrarSesion();
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            key: const Key('boton_mi_perfil'),
            tooltip: 'Mi Perfil',
            icon: const Icon(Icons.person_outline_rounded, color: Color(0xFF234E3F)),
            onPressed: () =>
                Navigator.of(context).pushNamed(AppRoutes.editarPerfil),
          ),
          IconButton(
            key: const Key('boton_cerrar_sesion'),
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout_rounded, color: Colors.black54),
            onPressed: _confirmarCerrarSesion,
          ),
        ],
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
            Expanded(
              child: _ListaIntegrantes(
                stream: integrantesStream,
                usuarioActualId: _usuarios.usuarioActualId,
                usuarioService: _usuarios,
              ),
            ),
            _CodigoInvitacionBox(
              codigo: hogar.codigoInvitacion,
              onCopiar: () => _copiarCodigo(hogar.codigoInvitacion),
              onRegenerar: _confirmarRegenerarCodigo,
            ),
          ],
        );
      },
    );
  }
}

class _ListaIntegrantes extends StatelessWidget {
  const _ListaIntegrantes({
    required this.stream,
    this.usuarioActualId,
    this.usuarioService,
  });

  final Stream<List<Integrante>> stream;
  final String? usuarioActualId;
  final UsuarioService? usuarioService;

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
          return const Center(child: CircularProgressIndicator());
        }

        final soyAdmin = integrantes.any(
          (i) => i.uid == usuarioActualId && i.esAdministrador,
        );

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
            final integrante = integrantes[i - 1];
            return _IntegranteTile(
              integrante: integrante,
              esYo: integrante.uid == usuarioActualId,
              puedeAdministrar: soyAdmin && integrante.uid != usuarioActualId,
              usuarioService: usuarioService,
            );
          },
        );
      },
    );
  }
}

class _IntegranteTile extends StatelessWidget {
  const _IntegranteTile({
    required this.integrante,
    this.esYo = false,
    this.puedeAdministrar = false,
    this.usuarioService,
  });

  final Integrante integrante;
  final bool esYo;
  final bool puedeAdministrar;
  final UsuarioService? usuarioService;

  Future<void> _cambiarRol(BuildContext context, bool nuevoEsAdmin) async {
    try {
      await usuarioService?.cambiarRolIntegrante(
        integranteUid: integrante.uid,
        esAdmin: nuevoEsAdmin,
      );
      if (!context.mounted) return;
      AppFeedback.mostrarExito(
        context,
        nuevoEsAdmin
            ? '${integrante.nombre} ahora es Administrador'
            : '${integrante.nombre} ahora es Integrante',
      );
    } catch (_) {
      if (!context.mounted) return;
      AppFeedback.mostrarError(context, 'No se pudo actualizar el rol');
    }
  }

  Future<void> _confirmarExpulsar(BuildContext context) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.person_remove_rounded, color: Color(0xFFC24134)),
            SizedBox(width: 8),
            Text(
              'Remover integrante',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: Text(
          '¿Estás seguro de que deseas expulsar a ${integrante.nombre} de este hogar?',
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFC24134)),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Expulsar'),
          ),
        ],
      ),
    );

    if (confirmar == true && context.mounted) {
      try {
        await usuarioService?.removerIntegrante(integranteUid: integrante.uid);
        if (!context.mounted) return;
        AppFeedback.mostrarInfo(
          context,
          '${integrante.nombre} fue removido del hogar',
        );
      } catch (_) {
        if (!context.mounted) return;
        AppFeedback.mostrarError(context, 'No se pudo remover al integrante');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final inicial = integrante.nombre.isNotEmpty
        ? integrante.nombre.characters.first.toUpperCase()
        : 'U';

    Color avatarColor = tema.colorScheme.primary;
    if (integrante.avatarColor != null) {
      try {
        avatarColor = Color(int.parse(integrante.avatarColor!));
      } catch (_) {}
    }

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
            backgroundColor: avatarColor,
            foregroundColor: Colors.white,
            child: Text(
              inicial,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    integrante.nombre,
                    style: tema.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (esYo) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECEAE4),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Tú',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black54),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (integrante.esAdministrador) ...[
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
          if (puedeAdministrar) ...[
            const SizedBox(width: 4),
            PopupMenuButton<String>(
              key: Key('menu_integrante_${integrante.uid}'),
              icon: const Icon(Icons.more_vert_rounded, color: Colors.black45, size: 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              onSelected: (val) {
                if (val == 'rol') {
                  _cambiarRol(context, !integrante.esAdministrador);
                } else if (val == 'expulsar') {
                  _confirmarExpulsar(context);
                }
              },
              itemBuilder: (ctx) => [
                PopupMenuItem(
                  value: 'rol',
                  child: Row(
                    children: [
                      Icon(
                        integrante.esAdministrador
                            ? Icons.person_outline_rounded
                            : Icons.star_outline_rounded,
                        size: 20,
                        color: Colors.black87,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        integrante.esAdministrador
                            ? 'Quitar rol de admin'
                            : 'Hacer administrador',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'expulsar',
                  child: Row(
                    children: [
                      Icon(Icons.person_remove_outlined, size: 20, color: Color(0xFFC24134)),
                      SizedBox(width: 10),
                      Text(
                        'Remover del hogar',
                        style: TextStyle(fontSize: 13, color: Color(0xFFC24134)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _CodigoInvitacionBox extends StatelessWidget {
  const _CodigoInvitacionBox({
    required this.codigo,
    required this.onCopiar,
    this.onRegenerar,
  });

  final String codigo;
  final VoidCallback onCopiar;
  final VoidCallback? onRegenerar;

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
          if (onRegenerar != null && codigo.isNotEmpty)
            IconButton(
              key: const Key('boton_regenerar_codigo'),
              tooltip: 'Generar nuevo código',
              color: Colors.white70,
              icon: const Icon(Icons.refresh_rounded),
              onPressed: onRegenerar,
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
