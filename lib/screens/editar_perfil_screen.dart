import 'package:flutter/material.dart';

import '../models/usuario.dart';
import '../routes.dart';
import '../services/usuario_service.dart';
import '../utils/app_feedback.dart';
import '../utils/validators.dart';

/// Pantalla para ver y editar el perfil personal del usuario.
class EditarPerfilScreen extends StatefulWidget {
  const EditarPerfilScreen({
    super.key,
    this.usuarioService,
    this.usuarioInicial,
  });

  final UsuarioService? usuarioService;
  final Usuario? usuarioInicial;

  @override
  State<EditarPerfilScreen> createState() => _EditarPerfilScreenState();
}

class _EditarPerfilScreenState extends State<EditarPerfilScreen> {
  late final UsuarioService _usuarios =
      widget.usuarioService ?? UsuarioService();

  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();

  Stream<Usuario?>? _perfilStream;
  Usuario? _usuarioActual;
  String? _colorSeleccionado;
  bool _cargando = false;

  static const List<String> _paletaColores = [
    '0xFF1E4D3E', // Verde esmeralda
    '0xFF2E6B56', // Salvia
    '0xFF2C3E50', // Azul marino
    '0xFF3F51B5', // Índigo
    '0xFF8E44AD', // Púrpura
    '0xFFD97736', // Terracota cálido
    '0xFFC24134', // Carmesí suave
  ];

  @override
  void initState() {
    super.initState();
    if (widget.usuarioInicial != null) {
      _aplicarUsuario(widget.usuarioInicial!);
    } else {
      _perfilStream = _usuarios.observarPerfilActual();
    }
  }

  void _aplicarUsuario(Usuario user) {
    _usuarioActual = user;
    if (_nombreCtrl.text.isEmpty) {
      _nombreCtrl.text = user.nombre;
    }
    _colorSeleccionado ??= user.avatarColor ?? _paletaColores.first;
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardarNombre() async {
    if (!(_formKey.currentState?.validate() ?? false) || _cargando) return;
    FocusScope.of(context).unfocus();

    setState(() => _cargando = true);
    try {
      await _usuarios.actualizarNombre(_nombreCtrl.text);
      if (!mounted) return;
      AppFeedback.mostrarExito(context, 'Nombre actualizado con éxito');
    } on UsuarioException catch (e) {
      if (!mounted) return;
      AppFeedback.mostrarError(context, e.mensaje);
    } catch (_) {
      if (!mounted) return;
      AppFeedback.mostrarError(context, UsuarioService.msgErrorActualizar);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _seleccionarColor(String colorHex) async {
    setState(() => _colorSeleccionado = colorHex);
    try {
      await _usuarios.actualizarAvatarColor(colorHex);
      if (!mounted) return;
      AppFeedback.mostrarExito(context, 'Color de perfil guardado');
    } catch (_) {
      if (!mounted) return;
      AppFeedback.mostrarError(context, UsuarioService.msgErrorActualizar);
    }
  }

  Future<void> _mostrarModalCambiarContrasena() async {
    final actualCtrl = TextEditingController();
    final nuevaCtrl = TextEditingController();
    final modalKey = GlobalKey<FormState>();
    bool ocultarActual = true;
    bool ocultarNueva = true;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final passText = nuevaCtrl.text;
          final tieneMin6 = Validators.tieneMinimo6(passText);
          final tieneLetra = Validators.tieneLetra(passText);
          final tieneNum = Validators.tieneNumero(passText);
          final nivel = Validators.nivelSeguridadContrasena(passText);

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Form(
                key: modalKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.black12,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Cambiar contraseña',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      key: const Key('campo_pass_actual'),
                      controller: actualCtrl,
                      obscureText: ocultarActual,
                      decoration: InputDecoration(
                        labelText: 'Contraseña actual',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          icon: Icon(ocultarActual
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined),
                          onPressed: () => setModalState(
                              () => ocultarActual = !ocultarActual),
                        ),
                      ),
                      validator: Validators.contrasenaNoVacia,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      key: const Key('campo_pass_nueva'),
                      controller: nuevaCtrl,
                      obscureText: ocultarNueva,
                      decoration: InputDecoration(
                        labelText: 'Nueva contraseña',
                        prefixIcon: const Icon(Icons.lock_reset_rounded),
                        suffixIcon: IconButton(
                          icon: Icon(ocultarNueva
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined),
                          onPressed: () =>
                              setModalState(() => ocultarNueva = !ocultarNueva),
                        ),
                      ),
                      validator: Validators.contrasena,
                      onChanged: (_) => setModalState(() {}),
                    ),
                    if (passText.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: nivel,
                        backgroundColor: const Color(0xFFECEAE4),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          nivel > 0.7 ? Colors.green : Colors.amber,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Cumplido: ${tieneMin6 ? "✓ 6+ carac." : ""} ${tieneLetra ? "✓ Letras" : ""} ${tieneNum ? "✓ Números" : ""}',
                        style: const TextStyle(fontSize: 11, color: Colors.black54),
                      ),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      key: const Key('boton_confirmar_pass'),
                      onPressed: () async {
                        if (!(modalKey.currentState?.validate() ?? false)) return;
                        try {
                          await _usuarios.cambiarContrasena(
                            contrasenaActual: actualCtrl.text,
                            nuevaContrasena: nuevaCtrl.text,
                          );
                          if (!ctx.mounted) return;
                          Navigator.of(ctx).pop();
                          if (!mounted) return;
                          AppFeedback.mostrarExito(
                              context, 'Contraseña actualizada con éxito');
                        } on UsuarioException catch (e) {
                          if (!ctx.mounted) return;
                          AppFeedback.mostrarError(ctx, e.mensaje);
                        } catch (_) {
                          if (!ctx.mounted) return;
                          AppFeedback.mostrarError(
                              ctx, UsuarioService.msgErrorContrasena);
                        }
                      },
                      child: const Text('Actualizar contraseña'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmarSalirHogar() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
            SizedBox(width: 8),
            Text(
              'Salir del hogar',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: const Text(
          '¿Estás seguro de que deseas desvincularte de este hogar? '
          'Perderás acceso a la lista de compras compartida hasta que te unas nuevamente con un código o crees otro hogar.',
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
            child: const Text('Sí, salir del hogar'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      try {
        await _usuarios.salirDelHogar();
        if (!mounted) return;
        AppFeedback.mostrarInfo(context, 'Has salido del hogar');
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.hogar,
          (_) => false,
        );
      } catch (_) {
        if (!mounted) return;
        AppFeedback.mostrarError(context, UsuarioService.msgSinConexion);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.usuarioInicial != null) {
      return _construirCuerpo(context, _usuarioActual!);
    }

    final stream = _perfilStream;
    if (stream == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return StreamBuilder<Usuario?>(
      stream: stream,
      builder: (context, snapshot) {
        if (!snapshot.hasData &&
            snapshot.connectionState != ConnectionState.active) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;
        if (user == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Mi Perfil')),
            body: const Center(
              child: Text('No se pudo encontrar tu perfil'),
            ),
          );
        }

        _aplicarUsuario(user);
        return _construirCuerpo(context, user);
      },
    );
  }

  Widget _construirCuerpo(BuildContext context, Usuario user) {
    final tema = Theme.of(context);
    final colorFondo = Color(int.parse(_colorSeleccionado ?? _paletaColores.first));
    final inicial = user.nombre.isNotEmpty ? user.nombre[0].toUpperCase() : 'U';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mi Perfil',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          color: colorFondo,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: colorFondo.withValues(alpha: 0.35),
                              blurRadius: 18,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            inicial,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 38,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          user.esAdministrador
                              ? Icons.star_rounded
                              : Icons.person_rounded,
                          size: 22,
                          color: user.esAdministrador
                              ? const Color(0xFFD48B38)
                              : tema.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Center(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: user.esAdministrador
                          ? const Color(0xFFFBF1DE)
                          : const Color(0xFFE8F1EC),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: user.esAdministrador
                            ? const Color(0xFFE8BA6E)
                            : const Color(0xFFB5D4C7),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          user.esAdministrador
                              ? Icons.admin_panel_settings_rounded
                              : Icons.group_rounded,
                          size: 16,
                          color: user.esAdministrador
                              ? const Color(0xFFB57000)
                              : const Color(0xFF1E4D3E),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          user.esAdministrador
                              ? 'Administrador del hogar'
                              : 'Integrante del hogar',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: user.esAdministrador
                                ? const Color(0xFFB57000)
                                : const Color(0xFF1E4D3E),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE8E4DA)),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Datos personales',
                          style: tema.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          key: const Key('campo_editar_nombre'),
                          controller: _nombreCtrl,
                          textCapitalization: TextCapitalization.words,
                          decoration: InputDecoration(
                            labelText: 'Nombre completo',
                            prefixIcon: Icon(
                              Icons.badge_outlined,
                              color: tema.colorScheme.primary,
                            ),
                            suffixIcon: IconButton(
                              key: const Key('boton_guardar_nombre'),
                              tooltip: 'Guardar nombre',
                              icon: _cargando
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.check_rounded, color: Colors.green),
                              onPressed: _guardarNombre,
                            ),
                          ),
                          validator: Validators.nombre,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          initialValue: user.correo,
                          readOnly: true,
                          decoration: const InputDecoration(
                            labelText: 'Correo electrónico',
                            prefixIcon: Icon(Icons.email_outlined, color: Colors.black45),
                            helperText: 'El correo no se puede modificar',
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Color de tu avatar',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: _paletaColores.map((hex) {
                            final colorItem = Color(int.parse(hex));
                            final esSeleccionado = _colorSeleccionado == hex;

                            return InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () => _seleccionarColor(hex),
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: colorItem,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: esSeleccionado
                                        ? Colors.black87
                                        : Colors.transparent,
                                    width: 2.5,
                                  ),
                                ),
                                child: esSeleccionado
                                    ? const Icon(
                                        Icons.check,
                                        size: 18,
                                        color: Colors.white,
                                      )
                                    : null,
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE8E4DA)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Seguridad y membresía',
                        style: tema.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 14),
                      OutlinedButton.icon(
                        key: const Key('boton_modal_cambiar_pass'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.key_rounded),
                        label: const Text('Cambiar contraseña'),
                        onPressed: _mostrarModalCambiarContrasena,
                      ),
                      if (user.hogarId != null) ...[
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          key: const Key('boton_salir_hogar'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFC24134),
                            side: const BorderSide(color: Color(0xFFECC8C5)),
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.exit_to_app_rounded),
                          label: const Text('Salir de este hogar'),
                          onPressed: _confirmarSalirHogar,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
