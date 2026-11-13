String _comMilhar(String inteiro) {
  final buffer = StringBuffer();
  for (var i = 0; i < inteiro.length; i++) {
    if (i > 0 && (inteiro.length - i) % 3 == 0) buffer.write('.');
    buffer.write(inteiro[i]);
  }
  return buffer.toString();
}

/// Formata centavos como moeda brasileira: 123456 -> "R$ 1.234,56".
String formatarMoeda(int centavos) {
  final negativo = centavos < 0;
  final absoluto = centavos.abs();
  final reais = absoluto ~/ 100;
  final resto = absoluto % 100;
  final texto =
      '${_comMilhar(reais.toString())},${resto.toString().padLeft(2, '0')}';
  return negativo ? '-R\$ $texto' : 'R\$ $texto';
}

/// Formata sem o símbolo, para usar dentro do campo de digitação.
String formatarValorSemSimbolo(int centavos) {
  final texto = formatarMoeda(centavos);
  if (texto.startsWith('-R\$ ')) return '-${texto.substring(4)}';
  if (texto.startsWith('R\$ ')) return texto.substring(3);
  return texto;
}

/// Extrai os centavos de um texto digitado ("7.000,00" -> 700000).
int centavosDoTexto(String texto) {
  final digitos = texto.replaceAll(RegExp(r'[^0-9]'), '');
  if (digitos.isEmpty) return 0;
  return int.tryParse(digitos) ?? 0;
}

String formatarData(DateTime data) {
  final dia = data.day.toString().padLeft(2, '0');
  final mes = data.month.toString().padLeft(2, '0');
  return '$dia/$mes/${data.year}';
}

String formatarDataHora(DateTime data) {
  final hora = data.hour.toString().padLeft(2, '0');
  final minuto = data.minute.toString().padLeft(2, '0');
  return '${formatarData(data)} às $hora:$minuto';
}

String dataParaBanco(DateTime data) {
  final mes = data.month.toString().padLeft(2, '0');
  final dia = data.day.toString().padLeft(2, '0');
  return '${data.year.toString().padLeft(4, '0')}-$mes-$dia';
}

DateTime dataDoBanco(String texto) => DateTime.parse(texto);

DateTime somenteData(DateTime data) =>
    DateTime(data.year, data.month, data.day);

const String _comAcento = 'áàâãäéèêëíìîïóòôõöúùûüçÁÀÂÃÄÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇ';
const String _semAcento = 'aaaaaeeeeiiiiooooouuuucAAAAAEEEEIIIIOOOOOUUUUC';

/// Deixa o texto em minúsculas e sem acento, para busca.
String normalizar(String texto) {
  final buffer = StringBuffer();
  for (final rune in texto.runes) {
    final caractere = String.fromCharCode(rune);
    final indice = _comAcento.indexOf(caractere);
    buffer.write(indice >= 0 ? _semAcento[indice] : caractere);
  }
  return buffer.toString().toLowerCase();
}

/// Percentual pago, entre 0 e 1.
double progressoPago(int valorContratado, int totalPago) {
  if (valorContratado <= 0) return 0;
  return (totalPago / valorContratado).clamp(0.0, 1.0).toDouble();
}

String nomeArquivoLimpo(String texto) {
  final limpo = normalizar(texto)
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');
  return limpo.isEmpty ? 'relatorio' : limpo;
}
