import 'package:easyhome/utils/mayusculas_formatter.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('convierte a mayúsculas y conserva la posición del cursor', () {
    const formatter = MayusculasFormatter();
    final resultado = formatter.formatEditUpdate(
      TextEditingValue.empty,
      const TextEditingValue(
        text: 'ab12cd',
        selection: TextSelection.collapsed(offset: 6),
      ),
    );

    expect(resultado.text, 'AB12CD');
    expect(resultado.selection.baseOffset, 6);
  });
}