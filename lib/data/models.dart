enum TipoPagamento { normal, antecipado, extra }

extension TipoPagamentoTexto on TipoPagamento {
  String get rotulo => switch (this) {
        TipoPagamento.normal => 'Normal',
        TipoPagamento.antecipado => 'Antecipado',
        TipoPagamento.extra => 'Extra',
      };
}

TipoPagamento tipoPeloRotulo(String rotulo) {
  return switch (rotulo) {
    'Antecipado' => TipoPagamento.antecipado,
    'Extra' => TipoPagamento.extra,
    _ => TipoPagamento.normal,
  };
}

class Relatorio {
  const Relatorio({
    this.id,
    required this.contratante,
    required this.prestador,
    required this.obra,
    required this.valorCentavos,
    required this.dataInicio,
    required this.criadoEm,
    required this.ativo,
  });

  final int? id;
  final String contratante;
  final String prestador;
  final String obra;
  final int valorCentavos;
  final DateTime dataInicio;
  final DateTime criadoEm;
  final bool ativo;

  Relatorio copyWith({
    String? contratante,
    String? prestador,
    String? obra,
    int? valorCentavos,
    DateTime? dataInicio,
  }) {
    return Relatorio(
      id: id,
      contratante: contratante ?? this.contratante,
      prestador: prestador ?? this.prestador,
      obra: obra ?? this.obra,
      valorCentavos: valorCentavos ?? this.valorCentavos,
      dataInicio: dataInicio ?? this.dataInicio,
      criadoEm: criadoEm,
      ativo: ativo,
    );
  }

  factory Relatorio.doMapa(Map<String, Object?> mapa) {
    return Relatorio(
      id: mapa['id'] as int?,
      contratante: (mapa['contratante'] as String?) ?? '',
      prestador: (mapa['prestador'] as String?) ?? '',
      obra: (mapa['obra'] as String?) ?? '',
      valorCentavos: (mapa['valor_centavos'] as num?)?.toInt() ?? 0,
      dataInicio: DateTime.parse(mapa['data_inicio'] as String),
      criadoEm: DateTime.parse(mapa['criado_em'] as String),
      ativo: ((mapa['ativo'] as num?)?.toInt() ?? 0) == 1,
    );
  }
}

class Pagamento {
  const Pagamento({
    this.id,
    required this.relatorioId,
    required this.tipo,
    required this.valorCentavos,
    required this.data,
    required this.criadoEm,
  });

  final int? id;
  final int relatorioId;
  final TipoPagamento tipo;
  final int valorCentavos;
  final DateTime data;
  final DateTime criadoEm;

  Pagamento copyWith({int? id}) => Pagamento(
        id: id ?? this.id,
        relatorioId: relatorioId,
        tipo: tipo,
        valorCentavos: valorCentavos,
        data: data,
        criadoEm: criadoEm,
      );

  factory Pagamento.doMapa(Map<String, Object?> mapa) {
    return Pagamento(
      id: mapa['id'] as int?,
      relatorioId: (mapa['relatorio_id'] as num).toInt(),
      tipo: tipoPeloRotulo((mapa['tipo'] as String?) ?? 'Normal'),
      valorCentavos: (mapa['valor_centavos'] as num?)?.toInt() ?? 0,
      data: DateTime.parse(mapa['data_pagamento'] as String),
      criadoEm: DateTime.parse(mapa['criado_em'] as String),
    );
  }
}
