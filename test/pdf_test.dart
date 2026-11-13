import 'dart:io';

import 'package:controle_mao_de_obra/data/models.dart';
import 'package:controle_mao_de_obra/pdf/pdf_service.dart';
import 'package:flutter_test/flutter_test.dart';

Relatorio _relatorioExemplo() {
  return Relatorio(
    id: 1,
    contratante: 'Marcenaria Bela Vista ME',
    prestador: 'Ana Paula Souza',
    obra: 'Reforma do galpão',
    valorCentavos: 9434800,
    dataInicio: DateTime(2026, 6, 16),
    criadoEm: DateTime(2026, 6, 16, 9, 30),
    ativo: true,
  );
}

List<Pagamento> _pagamentosExemplo() {
  final dados = <(String, int, TipoPagamento)>[
    ('2026-06-16', 700000, TipoPagamento.normal),
    ('2026-06-26', 650000, TipoPagamento.normal),
    ('2026-07-08', 530000, TipoPagamento.normal),
    ('2026-08-12', 300000, TipoPagamento.antecipado),
    ('2026-08-21', 500000, TipoPagamento.normal),
    ('2026-10-02', 480000, TipoPagamento.extra),
  ];
  return [
    for (var i = 0; i < dados.length; i++)
      Pagamento(
        id: i + 1,
        relatorioId: 1,
        tipo: dados[i].$3,
        valorCentavos: dados[i].$2,
        data: DateTime.parse(dados[i].$1),
        criadoEm: DateTime.parse(dados[i].$1),
      ),
  ];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('gera o PDF do contrato com todos os pagamentos', () async {
    final bytes = await PdfService.gerar(
      relatorio: _relatorioExemplo(),
      pagamentos: _pagamentosExemplo(),
    );

    expect(bytes.length, greaterThan(2000));

    final arquivo = File('build/test-artifacts/relatorio_exemplo.pdf');
    await arquivo.parent.create(recursive: true);
    await arquivo.writeAsBytes(bytes);
    expect(await arquivo.exists(), isTrue);
  });

  test('gera o PDF mesmo sem pagamentos', () async {
    final bytes = await PdfService.gerar(
      relatorio: _relatorioExemplo(),
      pagamentos: const [],
    );
    expect(bytes.length, greaterThan(2000));
  });
}
