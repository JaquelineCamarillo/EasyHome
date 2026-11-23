import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/hogar.dart';
import '../models/integrante.dart';
import '../routes.dart';
import '../services/hogar_service.dart';
import '../services/usuario_service.dart';
import '../theme/app_theme.dart';
import '../utils/app_feedback.dart';
import '../widgets/usuario_avatar.dart';

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
  List<Hogar> _misHogares = [];

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
        setState(() => _error = 'Todavía no perteneces a ningún espacio');
        return;
      }
      _hogarIdResuelto = hogarId;
      // Sincronizar el correo del usuario actual en Firestore si aún no lo tiene
      try {
        _usuarios.sincronizarCorreoActual();
      } catch (_) {}
      // Los streams se crean una sola vez (no dentro de build).
      setState(() {
        _hogarStream = _hogares.observarHogar(hogarId);
        _integrantesStream = _hogares.observarIntegrantes(hogarId);
      });
      // Cargar lista de todos los hogares del usuario en segundo plano (para selector multi-hogar)
      _hogares.obtenerHogaresDelUsuario().then((lista) {
        if (mounted) {
          setState(() => _misHogares = lista);
        }
      }).catchError((_) {});
    } on HogarException catch (e) {
      if (mounted) setState(() => _error = e.mensaje);
    } catch (_) {
      if (mounted) setState(() => _error = HogarService.msgSinConexion);
    }
  }

  Future<void> _cambiarHogarSeleccionado(String nuevoHogarId) async {
    if (nuevoHogarId == _hogarIdResuelto) return;
    try {
      await _hogares.cambiarHogarActivo(nuevoHogarId);
      if (!mounted) return;
      setState(() {
        _hogarIdResuelto = nuevoHogarId;
        _hogarStream = _hogares.observarHogar(nuevoHogarId);
        _integrantesStream = _hogares.observarIntegrantes(nuevoHogarId);
      });
      AppFeedback.mostrarExito(context, 'Cambiaste de espacio activo');
    } catch (_) {
      if (!mounted) return;
      AppFeedback.mostrarError(context, 'No se pudo cambiar de espacio');
    }
  }

  Future<void> _mostrarSelectorMultihogar(Hogar hogarActual) async {
    try {
      final lista = await _hogares.obtenerHogaresDelUsuario();
      if (mounted) {
        setState(() => _misHogares = lista);
      }
    } catch (_) {}

    if (!mounted) return;
    final hogares = _misHogares.isNotEmpty ? _misHogares : [hogarActual];

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540),
          child: Material(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            clipBehavior: Clip.antiAlias,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
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
                      Icon(Icons.workspaces_rounded, color: Color(0xFF234E3F)),
                      SizedBox(width: 8),
                      Text(
                        'Mis espacios',
                        key: Key('titulo_selector_hogares'),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E2D27),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...hogares.map((h) {
                    final esActual = h.id == _hogarIdResuelto;
                    return ListTile(
                      key: Key('item_hogar_${h.id}'),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      leading: CircleAvatar(
                        backgroundColor: esActual
                            ? AppColors.verdeOliva
                            : const Color(0xFFE8E4DA),
                        foregroundColor:
                            esActual ? Colors.white : const Color(0xFF1E2D27),
                        child: const Icon(Icons.home_work_outlined, size: 20),
                      ),
                      title: Text(
                        h.nombre,
                        style: TextStyle(
                          fontWeight:
                              esActual ? FontWeight.bold : FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        TipoEspacio.etiquetaDe(h.tipoEspacio),
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: esActual
                          ? const Icon(Icons.check_circle_rounded,
                              color: AppColors.verdeOliva)
                          : const Icon(Icons.swap_horiz_rounded,
                              color: Colors.black45),
                      onTap: () {
                        Navigator.of(ctx).pop();
                        _cambiarHogarSeleccionado(h.id);
                      },
                    );
                  }),
                  const Divider(height: 24),
                  FilledButton.icon(
                    key: const Key('boton_crear_nuevo_hogar_admin'),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Crear espacio'),
                    onPressed: () async {
                      final nav = Navigator.of(context);
                      Navigator.of(ctx).pop();
                      await nav.pushNamed(AppRoutes.hogar);
                      if (mounted) {
                        await _iniciar();
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    key: const Key('boton_unirse_otro_hogar_admin'),
                    icon: const Icon(Icons.key_rounded),
                    label: const Text('Unirme a otro espacio con código'),
                    onPressed: () async {
                      final nav = Navigator.of(context);
                      Navigator.of(ctx).pop();
                      await nav.pushNamed(AppRoutes.unirseHogar);
                      if (mounted) {
                        await _iniciar();
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
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

  Future<void> _confirmarSalirHogar() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.exit_to_app_rounded, color: AppColors.error),
            SizedBox(width: 8),
            Text(
              'Salir del espacio',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: const Text(
          '¿Estás seguro de que deseas salir de este espacio? '
          'Podrás unirte al espacio correcto ingresando su código de invitación.',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Salir del espacio'),
          ),
        ],
      ),
    );

    if (confirmar == true && mounted) {
      try {
        await _usuarios.salirDelHogar();
        if (!mounted) return;
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.hogar,
          (_) => false,
        );
      } catch (_) {
        if (!mounted) return;
        AppFeedback.mostrarError(context, 'No se pudo salir del espacio');
      }
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
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: _cuerpo(context),
          ),
        ),
      ),
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
        if (snap.hasError) return const _Mensaje('No se pudo cargar el espacio');
        if (!snap.hasData && snap.connectionState != ConnectionState.active) {
          return const Center(child: CircularProgressIndicator());
        }
        final hogar = snap.data;
        if (hogar == null) {
          return const _Mensaje('No se encontró tu espacio');
        }

        final tema = Theme.of(context);
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hogar.nombre,
                          key: const Key('nombre_hogar'),
                          style: tema.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: tema.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          key: const Key('badge_tipo_espacio'),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.verdeOliva.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            TipoEspacio.etiquetaDe(hogar.tipoEspacio),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.verdeOliva,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton.icon(
                    key: const Key('boton_gestionar_hogares'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.workspaces_outline, size: 18),
                    label: Text(
                      _misHogares.length > 1
                          ? 'Espacios (${_misHogares.length})'
                          : 'Espacios',
                      style: const TextStyle(fontSize: 12),
                    ),
                    onPressed: () => _mostrarSelectorMultihogar(hogar),
                  ),
                ],
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
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 12),
              child: TextButton.icon(
                key: const Key('boton_salir_hogar_perfil'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.error,
                ),
                icon: const Icon(Icons.exit_to_app_rounded, size: 18),
                label: const Text('Salir de este espacio'),
                onPressed: _confirmarSalirHogar,
              ),
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
              soyAdmin: soyAdmin,
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
    this.soyAdmin = false,
    this.usuarioService,
  });

  final Integrante integrante;
  final bool esYo;
  final bool puedeAdministrar;
  final bool soyAdmin;
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
          '¿Estás seguro de que deseas expulsar a ${integrante.nombre} de este espacio?',
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
          '${integrante.nombre} fue removido del espacio',
        );
      } catch (_) {
        if (!context.mounted) return;
        AppFeedback.mostrarError(context, 'No se pudo remover al integrante');
      }
    }
  }

  Future<void> _mostrarDialogoEditarCorreo(BuildContext context) async {
    final ctrl = TextEditingController(text: integrante.correo ?? '');
    final formKey = GlobalKey<FormState>();

    final guardado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.email_outlined, color: Color(0xFF234E3F)),
            SizedBox(width: 8),
            Text(
              'Registrar correo',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ingresa el correo electrónico para ${integrante.nombre}:',
                style: const TextStyle(fontSize: 13, color: Colors.black87),
              ),
              const SizedBox(height: 14),
              TextFormField(
                key: const Key('campo_editar_correo_integrante'),
                controller: ctrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Correo electrónico',
                  hintText: 'ejemplo@correo.com',
                  prefixIcon: Icon(Icons.alternate_email_rounded),
                ),
                validator: (val) {
                  final v = (val ?? '').trim();
                  if (v.isEmpty) return 'Ingresa un correo';
                  if (!v.contains('@') || !v.contains('.')) return 'Correo inválido';
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            key: const Key('boton_guardar_correo_integrante'),
            onPressed: () async {
              if (!(formKey.currentState?.validate() ?? false)) return;
              try {
                await usuarioService?.actualizarCorreoIntegrante(
                  integranteUid: integrante.uid,
                  nuevoCorreo: ctrl.text.trim(),
                );
                if (!ctx.mounted) return;
                Navigator.of(ctx).pop(true);
              } catch (_) {
                if (!ctx.mounted) return;
                AppFeedback.mostrarError(ctx, 'No se pudo guardar el correo');
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (guardado == true && context.mounted) {
      AppFeedback.mostrarExito(context, 'Correo registrado');
    }
  }

  void _mostrarDetallePerfil(
    BuildContext context,
    ThemeData tema,
    Color avatarColor,
    String inicial,
  ) {
    final correoEfectivo = esYo
        ? (integrante.correo ?? usuarioService?.usuarioActual?.email)
        : integrante.correo;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
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
            Row(
              children: [
                UsuarioAvatar(
                  nombre: integrante.nombre,
                  avatarRaw: integrante.avatarColor,
                  radius: 28,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              integrante.nombre,
                              key: Key('detalle_nombre_${integrante.uid}'),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E2D27),
                              ),
                            ),
                          ),
                          if (esYo) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFECEAE4),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Tú',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black54,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: integrante.esAdministrador
                              ? AppColors.arenaTaupe.withValues(alpha: 0.22)
                              : AppColors.verdeOliva.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: integrante.esAdministrador
                                ? AppColors.arenaTaupe
                                : AppColors.verdeOliva.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              integrante.esAdministrador
                                  ? Icons.star_rounded
                                  : Icons.person_rounded,
                              size: 14,
                              color: integrante.esAdministrador
                                  ? AppColors.bronceMocha
                                  : AppColors.verdeOliva,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              integrante.esAdministrador
                                  ? 'Administrador del espacio'
                                  : 'Integrante',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: integrante.esAdministrador
                                    ? AppColors.bronceMocha
                                    : AppColors.verdeOliva,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(height: 1, color: Color(0xFFE8E4DA)),
            const SizedBox(height: 16),
            // Información de correo electrónico
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F5EE),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE8E4DA)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.email_outlined,
                      color: Color(0xFF234E3F), size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Correo electrónico',
                          style: TextStyle(fontSize: 11, color: Colors.black54),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          soyAdmin
                              ? (correoEfectivo != null &&
                                      correoEfectivo.isNotEmpty
                                  ? correoEfectivo
                                  : 'Sin correo registrado')
                              : 'Visible solo para administradores',
                          key: Key('detalle_correo_${integrante.uid}'),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: soyAdmin
                                ? const Color(0xFF1E2D27)
                                : Colors.black45,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (soyAdmin &&
                      correoEfectivo != null &&
                      correoEfectivo.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.copy_rounded,
                          size: 18, color: Colors.black45),
                      tooltip: 'Copiar correo',
                      onPressed: () async {
                        await Clipboard.setData(
                            ClipboardData(text: correoEfectivo));
                        if (!context.mounted) return;
                        AppFeedback.mostrarExito(context, 'Correo copiado');
                      },
                    ),
                  if (soyAdmin)
                    IconButton(
                      key: Key('boton_editar_correo_${integrante.uid}'),
                      icon: const Icon(Icons.edit_outlined,
                          size: 18, color: Color(0xFF234E3F)),
                      tooltip: correoEfectivo != null && correoEfectivo.isNotEmpty
                          ? 'Editar correo'
                          : 'Registrar correo',
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        _mostrarDialogoEditarCorreo(context);
                      },
                    ),
                ],
              ),
            ),
            if (puedeAdministrar) ...[
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: Icon(
                        integrante.esAdministrador
                            ? Icons.person_outline_rounded
                            : Icons.star_outline_rounded,
                        size: 18,
                      ),
                      label: Text(
                        integrante.esAdministrador
                            ? 'Quitar admin'
                            : 'Hacer admin',
                      ),
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        _cambiarRol(context, !integrante.esAdministrador);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.tonalIcon(
                      style: FilledButton.styleFrom(
                        backgroundColor:
                            const Color(0xFFC24134).withValues(alpha: 0.1),
                        foregroundColor: const Color(0xFFC24134),
                      ),
                      icon: const Icon(Icons.person_remove_outlined, size: 18),
                      label: const Text('Remover'),
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        _confirmarExpulsar(context);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    ),
  ),
);
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final inicial = integrante.nombre.isNotEmpty
        ? integrante.nombre.characters.first.toUpperCase()
        : 'U';
    final correoEfectivo = esYo
        ? (integrante.correo ?? usuarioService?.usuarioActual?.email)
        : integrante.correo;

    final avatarColor = integrante.avatarColor != null
        ? AvatarConfig.parse(integrante.avatarColor).colorFondo
        : tema.colorScheme.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: Key('tile_integrante_${integrante.uid}'),
          borderRadius: BorderRadius.circular(16),
          onTap: () =>
              _mostrarDetallePerfil(context, tema, avatarColor, inicial),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                UsuarioAvatar(
                  nombre: integrante.nombre,
                  avatarRaw: integrante.avatarColor,
                  radius: 20,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
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
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFECEAE4),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Tú',
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black54),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (soyAdmin &&
                          correoEfectivo != null &&
                          correoEfectivo.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          correoEfectivo,
                          key: Key('correo_integrante_${integrante.uid}'),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                if (integrante.esAdministrador) ...[
                  Container(
                    key: const Key('etiqueta_admin'),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.arenaTaupe.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.arenaTaupe),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star_rounded,
                            size: 16, color: AppColors.bronceMocha),
                        SizedBox(width: 4),
                        Text(
                          'Admin',
                          style: TextStyle(
                            color: AppColors.bronceMocha,
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
                    icon: const Icon(Icons.more_vert_rounded,
                        color: Colors.black45, size: 20),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
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
                            Icon(Icons.person_remove_outlined,
                                size: 20, color: Color(0xFFC24134)),
                            SizedBox(width: 10),
                            Text(
                              'Remover del espacio',
                              style: TextStyle(
                                  fontSize: 13, color: Color(0xFFC24134)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
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
                  'Código de invitación del espacio',
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
