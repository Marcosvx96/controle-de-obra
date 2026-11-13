import 'package:controle_mao_de_obra/core/data_input_formatter.dart';
import 'package:controle_mao_de_obra/core/formatadores.dart';
import 'package:flutter/services.dart';
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

  test('mascara a data enquanto digita', () {
    expect(formatarDataParcial(''), '');
    expect(formatarDataParcial('1'), '1');
    expect(formatarDataParcial('12'), '12');
    expect(formatarDataParcial('123'), '12/3');
    expect(formatarDataParcial('1234'), '12/34');
    expect(formatarDataParcial('12345'), '12/34/5');
    expect(formatarDataParcial('16062026'), '16/06/2026');

    const formatador = DataInputFormatter();
    TextEditingValue digitar(String texto) => formatador.formatEditUpdate(
          TextEditingValue.empty,
          TextEditingValue(
            text: texto,
            selection: TextSelection.collapsed(offset: texto.length),
          ),
        );

    expect(digitar('16062026').text, '16/06/2026');
    expect(digitar('123456789').text, '12/34/5678');
  });

  test('lê a data digitada', () {
    expect(dataDoTexto('16/06/2026'), DateTime(2026, 6, 16));
    expect(dataDoTexto('29/02/2024'), DateTime(2024, 2, 29));
    expect(dataDoTexto('31/02/2026'), isNull);
    expect(dataDoTexto('16/06'), isNull);
    expect(dataDoTexto('16062026'), isNull);
    expect(dataDoTexto(''), isNull);
  });

  test('normaliza acentos e maiúsculas para busca', () {
    expect(normalizar('José ÁVILA'), 'jose avila');
    expect(normalizar('Conceição'), 'conceicao');
  });

  test('calcula o progresso pago', () {
    expect(progressoPago(1000, 500), 0.5);
    expect(progressoPago(0, 500), 0);
    expect(progressoPago(1000, 3000), 1);
  });

  test('limpa o nome do arquivo', () {
    expect(
      nomeArquivoLimpo('Marcenaria Bela Vista ME'),
      'marcenaria_bela_vista_me',
    );
    expect(nomeArquivoLimpo('Ação & Cia.'), 'acao_cia');
  });
}
