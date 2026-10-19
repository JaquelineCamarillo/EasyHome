import 'package:flutter/services.dart';

/// Convierte a mayúsculas mientras se escribe (funciona también en web y con
/// teclado físico, a diferencia de `textCapitalization`).
class MayusculasFormatter extends TextInputFormatter {
  const MayusculasFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final mayusculas = newValue.text.toUpperCase();
    // Casos raros (ej. 'ß' -> 'SS') cambian la longitud: no tocar la selección.
    if (mayusculas.length != newValue.text.length) return newValue;
    return newValue.copyWith(text: mayusculas, composing: TextRange.empty);
  }
}