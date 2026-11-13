import 'package:controle_mao_de_obra/core/formatadores.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formata valores em reais', () {
    expect(formatarMoeda(0), 'R\$ 0,00');
    expect(formatarMoeda(5), 'R\$ 0,05');
    expect(formatarMoeda(123456), 'R\$ 1.234,56');
    expect(formatarMoeda(9434800), 'R\$ 94.348,00');
    expect(formatarMoeda(-1550), '-R\$ 15,50');
  });

  test('extrai centavos do texto digitado', () {
    expect(centavosDoTexto(''), 0);
    expect(centavosDoTexto('1.234,56'), 123456);
    expect(centavosDoTexto('R\$ 7.000,00'), 700000);
  });

  test('formata datas', () {
    expect(formatarData(DateTime(2026, 6, 16)), '16/06/2026');
    expect(dataParaBanco(DateTime(2026, 6, 9)), '2026-06-09');
  });

  test('normaliza acentos e maiúsculas para busca', () {
    expect(normalizar('João ÁVILA'), 'joao avila');
    expect(normalizar('Conceição'), 'conceicao');
  });

  test('calcula o progresso pago', () {
    expect(progressoPago(1000, 500), 0.5);
    expect(progressoPago(0, 500), 0);
    expect(progressoPago(1000, 3000), 1);
  });

  test('limpa o nome do arquivo', () {
    expect(nomeArquivoLimpo('Fearless Marketing LTDA'), 'fearless_marketing_ltda');
    expect(nomeArquivoLimpo('Ação & Cia.'), 'acao_cia');
  });
}
