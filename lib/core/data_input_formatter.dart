import 'package:flutter/services.dart';

/// Coloca as barras da data sozinho enquanto o usuário digita só os números.
/// Ex.: 16062026 -> 16/06/2026
class DataInputFormatter extends TextInputFormatter {
  const DataInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitos = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    final limitado = digitos.length > 8 ? digitos.substring(0, 8) : digitos;
    final formatado = formatarDataParcial(limitado);

    // Mantém o cursor perto de onde o usuário estava digitando.
    final cursor = newValue.selection.baseOffset;
    final antesDoCursor = cursor >= 0 && cursor <= newValue.text.length
        ? newValue.text.substring(0, cursor)
        : newValue.text;
    var digitosAntes =
        antesDoCursor.replaceAll(RegExp(r'[^0-9]'), '').length;
    if (digitosAntes > limitado.length) digitosAntes = limitado.length;

    var posicao = 0;
    var contados = 0;
    while (posicao < formatado.length && contados < digitosAntes) {
      if (formatado[posicao] != '/') contados++;
      posicao++;
    }
    if (posicao < formatado.length && formatado[posicao] == '/') posicao++;

    return TextEditingValue(
      text: formatado,
      selection: TextSelection.collapsed(offset: posicao),
    );
  }
}

/// Formata os dígitos já digitados, sem inventar barra no fim
/// (assim o apagar funciona normalmente).
String formatarDataParcial(String digitos) {
  if (digitos.isEmpty) return '';
  if (digitos.length <= 2) return digitos;
  if (digitos.length <= 4) {
    return '${digitos.substring(0, 2)}/${digitos.substring(2)}';
  }
  return '${digitos.substring(0, 2)}/${digitos.substring(2, 4)}/'
      '${digitos.substring(4)}';
}

/// Lê "dd/mm/aaaa" e devolve a data, ou null se estiver incompleta ou inválida.
DateTime? dataDoTexto(String texto) {
  final partes = texto.trim().split('/');
  if (partes.length != 3) return null;
  if (partes[0].length != 2 ||
      partes[1].length != 2 ||
      partes[2].length != 4) {
    return null;
  }
  final dia = int.tryParse(partes[0]);
  final mes = int.tryParse(partes[1]);
  final ano = int.tryParse(partes[2]);
  if (dia == null || mes == null || ano == null) return null;
  if (mes < 1 || mes > 12 || dia < 1) return null;
  final data = DateTime(ano, mes, dia);
  if (data.year != ano || data.month != mes || data.day != dia) return null;
  return data;
}
