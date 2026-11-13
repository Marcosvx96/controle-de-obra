import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../data/repositorio.dart';

class BackupService {
  static Future<void> exportar() async {
    final dados = await Repositorio.instancia.exportarDados();
    final agora = DateTime.now();
    final nome =
        'backup_contratos_${agora.year}${agora.month.toString().padLeft(2, '0')}${agora.day.toString().padLeft(2, '0')}_${agora.hour.toString().padLeft(2, '0')}${agora.minute.toString().padLeft(2, '0')}.json';
    final diretorio = await getTemporaryDirectory();
    final arquivo = File('${diretorio.path}/$nome');
    await arquivo.writeAsString(
      const JsonEncoder.withIndent('  ').convert(dados),
    );
    await Share.shareXFiles(
      [XFile(arquivo.path, mimeType: 'application/json')],
      subject: 'Backup do Controle de Pagamento',
      text: 'Backup dos relatórios do Controle de Pagamento de Mão de Obra.',
    );
  }

  /// Abre o seletor de arquivos e devolve o conteúdo do backup.
  static Future<Map<String, dynamic>?> escolherBackup() async {
    final resultado = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );
    if (resultado == null || resultado.files.isEmpty) return null;
    final arquivo = resultado.files.first;
    final bytes = arquivo.bytes;
    final texto = bytes != null
        ? utf8.decode(bytes)
        : await File(arquivo.path!).readAsString();
    final dados = jsonDecode(texto);
    if (dados is! Map<String, dynamic>) {
      throw const FormatException('Arquivo de backup inválido.');
    }
    return dados;
  }

  static Future<void> restaurar(Map<String, dynamic> dados) async {
    await Repositorio.instancia.importarDados(dados);
  }
}
