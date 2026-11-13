import 'package:flutter/services.dart';

import 'formatadores.dart';

/// Mantém o campo no formato 1.234,56 enquanto o usuário digita só números.
class MoedaInputFormatter extends TextInputFormatter {
  const MoedaInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitos = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitos.isEmpty) return const TextEditingValue(text: '');
    final limitado = digitos.length > 12 ? digitos.substring(0, 12) : digitos;
    final texto = formatarValorSemSimbolo(int.parse(limitado));
    return TextEditingValue(
      text: texto,
      selection: TextSelection.collapsed(offset: texto.length),
    );
  }
}
