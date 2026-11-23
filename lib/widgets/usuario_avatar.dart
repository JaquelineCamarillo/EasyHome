import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Configuración serializable de color + personaje personalizado.
/// Se guarda dentro del campo existente `avatarColor` de `usuarios/{uid}`
/// para mantener 100% compatibilidad con las reglas de Firestore y usuarios previos.
///
/// Formato:
/// - Antiguo (solo color): `0xFF787F5D`
/// - Nuevo (con personaje): `0xFFA78BFA|piel=1|pelo=2|cpelo=1|acc=1|exp=0`
class AvatarConfig {
  const AvatarConfig({
    this.colorHex = '0xFF787F5D',
    this.usarPersonaje = false,
    this.tonoPiel = 1,
    this.estiloPelo = 1,
    this.colorPelo = 0,
    this.accesorio = 0,
    this.expresion = 0,
  });

  final String colorHex;
  final bool usarPersonaje;
  final int tonoPiel;
  final int estiloPelo;
  final int colorPelo;
  final int accesorio;
  final int expresion;

  /// Paleta ampliada de colores de fondo (incluye lila, lavanda, menta, coral, rosa, etc.).
  static const List<MapEntry<String, String>> paletaColores = [
    MapEntry('0xFF787F5D', 'Oliva'),
    MapEntry('0xFFA78BFA', 'Lila'),
    MapEntry('0xFF7C3AED', 'Morado'),
    MapEntry('0xFFF472B6', 'Rosa'),
    MapEntry('0xFFFB7185', 'Coral'),
    MapEntry('0xFFF59E0B', 'Ámbar'),
    MapEntry('0xFF10B981', 'Esmeralda'),
    MapEntry('0xFF14B8A6', 'Turquesa'),
    MapEntry('0xFF38BDF8', 'Cielo'),
    MapEntry('0xFF3B82F6', 'Azul'),
    MapEntry('0xFF6366F1', 'Índigo'),
    MapEntry('0xFFA68568', 'Mocha'),
    MapEntry('0xFF2C3E50', 'Marino'),
    MapEntry('0xFFC24134', 'Carmesí'),
  ];

  static const List<Color> tonosPiel = [
    Color(0xFFFFE0BD),
    Color(0xFFF1C27D),
    Color(0xFFE0AC69),
    Color(0xFFC68642),
    Color(0xFF8D5524),
  ];

  static const List<Color> coloresPelo = [
    Color(0xFF231F20), // Negro
    Color(0xFF5C3A21), // Castaño
    Color(0xFFD4A017), // Rubio
    Color(0xFFA52A2A), // Pelirrojo
    Color(0xFF7C3AED), // Lila/Morado
    Color(0xFF9CA3AF), // Gris/Plata
  ];

  static const List<String> estilosPelo = [
    'Corto',
    'Largo',
    'Rizado',
    'Chongo',
    'Sin cabello',
  ];

  static const List<String> accesorios = [
    'Ninguno',
    'Lentes',
    'Lentes de sol',
    'Gorra',
  ];

  static const List<String> expresiones = [
    'Sonrisa',
    'Feliz',
    'Sereno',
  ];

  Color get colorFondo {
    try {
      return Color(int.parse(colorHex));
    } catch (_) {
      return const Color(0xFF787F5D);
    }
  }

  String serialize() {
    if (!usarPersonaje) return colorHex;
    return '$colorHex|p=1|piel=$tonoPiel|pelo=$estiloPelo|cpelo=$colorPelo|acc=$accesorio|exp=$expresion';
  }

  factory AvatarConfig.parse(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return const AvatarConfig();
    }
    final partes = raw.split('|');
    final hex = partes.first.trim();
    if (partes.length == 1) {
      return AvatarConfig(colorHex: hex, usarPersonaje: false);
    }

    bool usarP = false;
    int piel = 1;
    int pelo = 1;
    int cpelo = 0;
    int acc = 0;
    int exp = 0;

    for (final p in partes.skip(1)) {
      final kv = p.split('=');
      if (kv.length != 2) continue;
      final k = kv[0];
      final v = int.tryParse(kv[1]);
      if (v == null) continue;
      switch (k) {
        case 'p':
          usarP = v == 1;
          break;
        case 'piel':
          piel = v.clamp(0, tonosPiel.length - 1);
          break;
        case 'pelo':
          pelo = v.clamp(0, estilosPelo.length - 1);
          break;
        case 'cpelo':
          cpelo = v.clamp(0, coloresPelo.length - 1);
          break;
        case 'acc':
          acc = v.clamp(0, accesorios.length - 1);
          break;
        case 'exp':
          exp = v.clamp(0, expresiones.length - 1);
          break;
      }
    }

    return AvatarConfig(
      colorHex: hex,
      usarPersonaje: usarP,
      tonoPiel: piel,
      estiloPelo: pelo,
      colorPelo: cpelo,
      accesorio: acc,
      expresion: exp,
    );
  }

  AvatarConfig copyWith({
    String? colorHex,
    bool? usarPersonaje,
    int? tonoPiel,
    int? estiloPelo,
    int? colorPelo,
    int? accesorio,
    int? expresion,
  }) {
    return AvatarConfig(
      colorHex: colorHex ?? this.colorHex,
      usarPersonaje: usarPersonaje ?? this.usarPersonaje,
      tonoPiel: tonoPiel ?? this.tonoPiel,
      estiloPelo: estiloPelo ?? this.estiloPelo,
      colorPelo: colorPelo ?? this.colorPelo,
      accesorio: accesorio ?? this.accesorio,
      expresion: expresion ?? this.expresion,
    );
  }
}

/// Widget reutilizable que dibuja el avatar del usuario:
/// ya sea inicial sobre color sólido o su personaje personalizado.
class UsuarioAvatar extends StatelessWidget {
  const UsuarioAvatar({
    super.key,
    required this.nombre,
    this.avatarRaw,
    this.config,
    this.radius = 22,
    this.mostrarSombra = false,
  });

  final String nombre;
  final String? avatarRaw;
  final AvatarConfig? config;
  final double radius;
  final bool mostrarSombra;

  @override
  Widget build(BuildContext context) {
    final cfg = config ?? AvatarConfig.parse(avatarRaw);
    final bg = cfg.colorFondo;
    final inicial = nombre.trim().isNotEmpty
        ? nombre.trim().characters.first.toUpperCase()
        : 'U';

    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        boxShadow: mostrarSombra
            ? [
                BoxShadow(
                  color: bg.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: cfg.usarPersonaje
          ? CustomPaint(
              size: Size.square(radius * 2),
              painter: _PersonajeAvatarPainter(cfg),
            )
          : Center(
              child: Text(
                inicial,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: radius * 0.85,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
    );
  }
}

class _PersonajeAvatarPainter extends CustomPainter {
  _PersonajeAvatarPainter(this.cfg);

  final AvatarConfig cfg;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;

    final pielColor = AvatarConfig.tonosPiel[cfg.tonoPiel];
    final peloColor = AvatarConfig.coloresPelo[cfg.colorPelo];

    final paintPiel = Paint()..color = pielColor;
    final paintPelo = Paint()..color = peloColor;

    // 1. Cabello trasero (si es largo o rizado)
    if (cfg.estiloPelo == 1) {
      // Largo
      final largoRect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, h * 0.56), width: w * 0.58, height: h * 0.52),
        Radius.circular(w * 0.25),
      );
      canvas.drawRRect(largoRect, paintPelo);
    } else if (cfg.estiloPelo == 2) {
      // Rizado (bolitas alrededor)
      for (final angle in [-2.6, -2.1, -1.6, -1.1, -0.5, 0.1, 3.0]) {
        final rx = cx + math.cos(angle) * w * 0.26;
        final ry = h * 0.44 + math.sin(angle) * h * 0.24;
        canvas.drawCircle(Offset(rx, ry), w * 0.11, paintPelo);
      }
    } else if (cfg.estiloPelo == 3) {
      // Chongo arriba
      canvas.drawCircle(Offset(cx, h * 0.19), w * 0.14, paintPelo);
    }

    // 2. Hombros / torso (camiseta clara contrastante)
    final paintCamisa = Paint()..color = Colors.white.withValues(alpha: 0.92);
    final torsoRect = Rect.fromCenter(
      center: Offset(cx, h * 0.96),
      width: w * 0.72,
      height: h * 0.42,
    );
    canvas.drawOval(torsoRect, paintCamisa);

    // 3. Cuello
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, h * 0.72), width: w * 0.16, height: h * 0.18),
        Radius.circular(w * 0.06),
      ),
      paintPiel,
    );

    // 4. Cabeza
    final headRadius = w * 0.24;
    final headCenter = Offset(cx, h * 0.48);
    canvas.drawCircle(headCenter, headRadius, paintPiel);

    // 5. Cabello frontal / fleco
    if (cfg.estiloPelo != 4) {
      final pathPelo = Path()
        ..addArc(
          Rect.fromCircle(center: headCenter, radius: headRadius * 1.04),
          math.pi,
          math.pi,
        )
        ..quadraticBezierTo(
          cx + headRadius * 0.3,
          headCenter.dy - headRadius * 0.25,
          cx - headRadius * 0.35,
          headCenter.dy - headRadius * 0.15,
        )
        ..close();
      canvas.drawPath(pathPelo, paintPelo);
    }

    // 6. Ojos
    final paintOjo = Paint()..color = const Color(0xFF1F2937);
    final ojoY = headCenter.dy + headRadius * 0.04;
    final ojoDx = headRadius * 0.38;
    if (cfg.expresion == 1) {
      // Ojos felices curvados
      final paintArc = Paint()
        ..color = const Color(0xFF1F2937)
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.5, w * 0.025)
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCenter(center: Offset(cx - ojoDx, ojoY), width: headRadius * 0.28, height: headRadius * 0.22),
        math.pi,
        math.pi,
        false,
        paintArc,
      );
      canvas.drawArc(
        Rect.fromCenter(center: Offset(cx + ojoDx, ojoY), width: headRadius * 0.28, height: headRadius * 0.22),
        math.pi,
        math.pi,
        false,
        paintArc,
      );
    } else {
      canvas.drawCircle(Offset(cx - ojoDx, ojoY), math.max(1.5, w * 0.028), paintOjo);
      canvas.drawCircle(Offset(cx + ojoDx, ojoY), math.max(1.5, w * 0.028), paintOjo);
    }

    // 7. Boca / expresión
    final paintBoca = Paint()
      ..color = const Color(0xFF7C2D12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.5, w * 0.024)
      ..strokeCap = StrokeCap.round;
    final bocaY = headCenter.dy + headRadius * 0.38;
    if (cfg.expresion == 0) {
      // Sonrisa
      canvas.drawArc(
        Rect.fromCenter(center: Offset(cx, bocaY - headRadius * 0.05), width: headRadius * 0.52, height: headRadius * 0.36),
        0.15 * math.pi,
        0.7 * math.pi,
        false,
        paintBoca,
      );
    } else if (cfg.expresion == 1) {
      // Feliz abierta
      final paintRelleno = Paint()..color = const Color(0xFFB91C1C);
      canvas.drawArc(
        Rect.fromCenter(center: Offset(cx, bocaY - headRadius * 0.04), width: headRadius * 0.56, height: headRadius * 0.42),
        0,
        math.pi,
        true,
        paintRelleno,
      );
    } else {
      // Sereno
      canvas.drawLine(
        Offset(cx - headRadius * 0.22, bocaY + headRadius * 0.06),
        Offset(cx + headRadius * 0.22, bocaY + headRadius * 0.06),
        paintBoca,
      );
    }

    // 8. Accesorios
    if (cfg.accesorio == 1 || cfg.accesorio == 2) {
      // Lentes / Lentes de sol
      final esSol = cfg.accesorio == 2;
      final marcoPaint = Paint()
        ..color = const Color(0xFF1F2937)
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.4, w * 0.024);
      final lenteW = headRadius * 0.56;
      final lenteH = headRadius * 0.42;
      final rectIzq = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx - ojoDx, ojoY), width: lenteW, height: lenteH),
        Radius.circular(w * 0.04),
      );
      final rectDer = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx + ojoDx, ojoY), width: lenteW, height: lenteH),
        Radius.circular(w * 0.04),
      );
      if (esSol) {
        final solFill = Paint()..color = const Color(0xFF111827).withValues(alpha: 0.85);
        canvas.drawRRect(rectIzq, solFill);
        canvas.drawRRect(rectDer, solFill);
      }
      canvas.drawRRect(rectIzq, marcoPaint);
      canvas.drawRRect(rectDer, marcoPaint);
      canvas.drawLine(
        Offset(cx - ojoDx + lenteW / 2, ojoY),
        Offset(cx + ojoDx - lenteW / 2, ojoY),
        marcoPaint,
      );
    } else if (cfg.accesorio == 3) {
      // Gorra
      final gorraPaint = Paint()..color = const Color(0xFF1F2937);
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, headCenter.dy - headRadius * 0.15), radius: headRadius * 1.06),
        math.pi,
        math.pi,
        true,
        gorraPaint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(cx - headRadius * 0.95, headCenter.dy - headRadius * 0.30, headRadius * 2.15, headRadius * 0.22),
          Radius.circular(w * 0.05),
        ),
        gorraPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PersonajeAvatarPainter oldDelegate) {
    return oldDelegate.cfg.serialize() != cfg.serialize();
  }
}
