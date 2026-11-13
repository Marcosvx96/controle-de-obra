import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../core/formatadores.dart';
import '../data/models.dart';

/// Gera o PDF no formato de contrato impresso (A4 retrato).
class PdfService {
  static pw.Font? _fonteRegular;
  static pw.Font? _fonteNegrito;

  static final PdfColor _azul = PdfColor.fromInt(0xFF0F3D5C);
  static final PdfColor _cinza = PdfColor.fromInt(0xFFEDF1F4);
  static final PdfColor _borda = PdfColor.fromInt(0xFF9AA7B2);
  static final PdfColor _verde = PdfColor.fromInt(0xFF1E7A46);
  static final PdfColor _laranja = PdfColor.fromInt(0xFFB45309);
  static final PdfColor _fraco = PdfColor.fromInt(0xFF4A5966);

  /// Fonte com acentos (o Helvetica padrão do PDF não aceita acentuação).
  static Future<pw.ThemeData> _tema() async {
    _fonteRegular ??=
        pw.Font.ttf(await rootBundle.load('assets/fonts/NotoSans-Regular.ttf'));
    _fonteNegrito ??=
        pw.Font.ttf(await rootBundle.load('assets/fonts/NotoSans-Bold.ttf'));
    return pw.ThemeData.withFont(
      base: _fonteRegular,
      bold: _fonteNegrito,
    );
  }

  static String nomeArquivo(Relatorio relatorio) {
    final data = formatarData(relatorio.dataInicio).replaceAll('/', '-');
    return 'contrato_${nomeArquivoLimpo(relatorio.contratante)}_$data.pdf';
  }

  static Future<Uint8List> gerar({
    required Relatorio relatorio,
    required List<Pagamento> pagamentos,
  }) async {
    final totalPago =
        pagamentos.fold<int>(0, (soma, item) => soma + item.valorCentavos);
    final saldo = relatorio.valorCentavos - totalPago;

    final documento = pw.Document(
      title: 'Controle de Pagamento de Mão de Obra',
      author: 'Controle de Pagamento de Mão de Obra',
      subject: '${relatorio.contratante} / ${relatorio.prestador}',
      creator: 'Controle de Pagamento de Mão de Obra',
    );

    final tema = await _tema();

    documento.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: tema,
        margin: const pw.EdgeInsets.fromLTRB(34, 30, 34, 34),
        header: (contexto) => contexto.pageNumber == 1
            ? pw.SizedBox.shrink()
            : _cabecalhoRepetido(relatorio),
        footer: (contexto) => _rodape(contexto),
        build: (contexto) => [
          _titulo(),
          pw.SizedBox(height: 12),
          _resumo(relatorio, totalPago, saldo),
          pw.SizedBox(height: 18),
          _tituloSecao('PAGAMENTOS EFETUADOS'),
          pw.SizedBox(height: 6),
          if (pagamentos.isEmpty)
            _avisoSemPagamentos()
          else
            _tabela(relatorio, pagamentos),
          pw.SizedBox(height: 8),
          _subtotal(totalPago),
          pw.SizedBox(height: 30),
          _assinaturas(),
        ],
      ),
    );
    return documento.save();
  }

  static pw.Widget _titulo() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'CONTROLE DE PAGAMENTO',
          style: pw.TextStyle(
            fontSize: 19,
            fontWeight: pw.FontWeight.bold,
            color: _azul,
            letterSpacing: 0.6,
          ),
        ),
        pw.Text(
          'DE MÃO DE OBRA',
          style: pw.TextStyle(
            fontSize: 19,
            fontWeight: pw.FontWeight.bold,
            color: _azul,
            letterSpacing: 0.6,
          ),
        ),
        pw.SizedBox(height: 6),
        pw.Container(width: 140, height: 2.5, color: _azul),
      ],
    );
  }

  static pw.Widget _cabecalhoRepetido(Relatorio relatorio) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 10),
      padding: const pw.EdgeInsets.only(bottom: 5),
      decoration: pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: _borda, width: 0.8)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'CONTROLE DE PAGAMENTO DE MÃO DE OBRA',
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: _azul,
            ),
          ),
          pw.Text(
            '${relatorio.contratante}  •  ${relatorio.prestador}',
            style: pw.TextStyle(fontSize: 8, color: _fraco),
          ),
        ],
      ),
    );
  }

  static pw.Widget _linhaInfo(String rotulo, String valor) {
    return pw.RichText(
      text: pw.TextSpan(
        children: [
          pw.TextSpan(
            text: '$rotulo: ',
            style: pw.TextStyle(
              fontSize: 8,
              color: _fraco,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.TextSpan(
            text: valor,
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.black,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _blocoValor(String rotulo, String valor, PdfColor cor) {
    return pw.Expanded(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            rotulo,
            style: pw.TextStyle(
              fontSize: 7.5,
              color: _fraco,
              fontWeight: pw.FontWeight.bold,
              letterSpacing: 0.4,
            ),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            valor,
            style: pw.TextStyle(
              fontSize: 12.5,
              fontWeight: pw.FontWeight.bold,
              color: cor,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _resumo(Relatorio relatorio, int totalPago, int saldo) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _borda, width: 0.8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Padding(
            padding: const pw.EdgeInsets.all(10),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _linhaInfo('CONTRATANTE', relatorio.contratante),
                pw.SizedBox(height: 5),
                pw.Row(
                  children: [
                    pw.Expanded(
                      child: _linhaInfo('PRESTADOR', relatorio.prestador),
                    ),
                    _linhaInfo(
                      'DATA DE INÍCIO',
                      formatarData(relatorio.dataInicio),
                    ),
                  ],
                ),
                if (relatorio.obra.trim().isNotEmpty) ...[
                  pw.SizedBox(height: 5),
                  _linhaInfo('OBRA / SERVIÇO', relatorio.obra),
                ],
              ],
            ),
          ),
          pw.Container(
            color: _cinza,
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: pw.Row(
              children: [
                _blocoValor(
                  'VALOR CONTRATADO',
                  formatarMoeda(relatorio.valorCentavos),
                  PdfColors.black,
                ),
                _blocoValor('TOTAL PAGO', formatarMoeda(totalPago), _verde),
                _blocoValor('SALDO RESTANTE', formatarMoeda(saldo), _laranja),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _tituloSecao(String texto) {
    return pw.Text(
      texto,
      style: pw.TextStyle(
        fontSize: 11,
        fontWeight: pw.FontWeight.bold,
        color: _azul,
        letterSpacing: 0.8,
      ),
    );
  }

  static pw.Widget _celula(
    String texto, {
    bool cabecalho = false,
    pw.Alignment alinhamento = pw.Alignment.centerLeft,
    double altura = 30,
  }) {
    return pw.Container(
      height: altura,
      padding: const pw.EdgeInsets.symmetric(horizontal: 4),
      alignment: alinhamento,
      child: pw.Text(
        texto,
        style: pw.TextStyle(
          fontSize: cabecalho ? 8 : 9.5,
          fontWeight: cabecalho ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: cabecalho ? _azul : PdfColors.black,
        ),
      ),
    );
  }

  static pw.Widget _tabela(Relatorio relatorio, List<Pagamento> pagamentos) {
    final linhas = <pw.TableRow>[
      pw.TableRow(
        repeat: true,
        decoration: pw.BoxDecoration(color: _cinza),
        children: [
          _celula('Nº', cabecalho: true, alinhamento: pw.Alignment.center),
          _celula('DATA', cabecalho: true, alinhamento: pw.Alignment.center),
          _celula('TIPO', cabecalho: true, alinhamento: pw.Alignment.center),
          _celula('VALOR PAGO',
              cabecalho: true, alinhamento: pw.Alignment.centerRight),
          _celula('RESTANTE',
              cabecalho: true, alinhamento: pw.Alignment.centerRight),
          _celula('ASSINATURA',
              cabecalho: true, alinhamento: pw.Alignment.center),
        ],
      ),
    ];

    var acumulado = 0;
    for (var i = 0; i < pagamentos.length; i++) {
      final pagamento = pagamentos[i];
      acumulado += pagamento.valorCentavos;
      final restante = relatorio.valorCentavos - acumulado;
      linhas.add(
        pw.TableRow(
          children: [
            _celula('${i + 1}', alinhamento: pw.Alignment.center),
            _celula(formatarData(pagamento.data),
                alinhamento: pw.Alignment.center),
            _celula(pagamento.tipo.rotulo, alinhamento: pw.Alignment.center),
            _celula(formatarMoeda(pagamento.valorCentavos),
                alinhamento: pw.Alignment.centerRight),
            _celula(formatarMoeda(restante),
                alinhamento: pw.Alignment.centerRight),
            _celula(''),
          ],
        ),
      );
    }

    return pw.Table(
      border: pw.TableBorder.all(color: _borda, width: 0.6),
      columnWidths: {
        0: const pw.FixedColumnWidth(38),
        1: const pw.FixedColumnWidth(58),
        2: const pw.FixedColumnWidth(70),
        3: const pw.FixedColumnWidth(82),
        4: const pw.FixedColumnWidth(82),
        5: const pw.FlexColumnWidth(),
      },
      children: linhas,
    );
  }

  static pw.Widget _avisoSemPagamentos() {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _borda, width: 0.6),
      ),
      child: pw.Text(
        'Nenhum pagamento lançado até o momento.',
        style: pw.TextStyle(fontSize: 10, color: _fraco),
      ),
    );
  }

  static pw.Widget _subtotal(int totalPago) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        color: _cinza,
        border: pw.Border.all(color: _borda, width: 0.6),
      ),
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'SUBTOTAL',
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: _azul,
              letterSpacing: 0.8,
            ),
          ),
          pw.Text(
            formatarMoeda(totalPago),
            style: pw.TextStyle(
              fontSize: 13,
              fontWeight: pw.FontWeight.bold,
              color: _azul,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _linhaAssinatura(String rotulo) {
    return pw.Column(
      children: [
        pw.Container(
          height: 42,
          decoration: pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(color: _borda, width: 0.8)),
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          rotulo,
          style: pw.TextStyle(fontSize: 8, color: _fraco),
        ),
      ],
    );
  }

  static pw.Widget _assinaturas() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'ASSINATURAS',
          style: pw.TextStyle(
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
            color: _fraco,
            letterSpacing: 0.8,
          ),
        ),
        pw.SizedBox(height: 26),
        pw.Row(
          children: [
            pw.Expanded(child: _linhaAssinatura('Assinatura do contratante')),
            pw.SizedBox(width: 40),
            pw.Expanded(child: _linhaAssinatura('Assinatura do prestador')),
          ],
        ),
      ],
    );
  }

  static pw.Widget _rodape(pw.Context contexto) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 10),
      padding: const pw.EdgeInsets.only(top: 5),
      decoration: pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: _borda, width: 0.5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Emitido em ${formatarDataHora(DateTime.now())}',
            style: pw.TextStyle(fontSize: 7.5, color: _fraco),
          ),
          pw.Text(
            'Página ${contexto.pageNumber} de ${contexto.pagesCount}',
            style: pw.TextStyle(fontSize: 7.5, color: _fraco),
          ),
        ],
      ),
    );
  }
}
