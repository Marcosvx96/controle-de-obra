import 'dart:typed_data';

import 'package:printing/printing.dart';

class PdfActions {
  /// Abre a tela de impressão do Android, onde também é possível
  /// escolher "Salvar como PDF".
  static Future<void> salvarOuImprimir(Uint8List bytes, String nome) async {
    await Printing.layoutPdf(
      name: nome,
      onLayout: (formato) async => bytes,
    );
  }

  /// Abre o compartilhamento (WhatsApp, e-mail, Drive...).
  static Future<void> compartilhar(Uint8List bytes, String nome) async {
    await Printing.sharePdf(bytes: bytes, filename: nome);
  }
}
