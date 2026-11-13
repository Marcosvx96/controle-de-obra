import 'package:controle_mao_de_obra/data/models.dart';
import 'package:controle_mao_de_obra/data/repositorio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() async {
    sqfliteFfiInit();
    sqflite.databaseFactory = databaseFactoryFfi;
    Banco.caminhoPersonalizado = inMemoryDatabasePath;
  });

  final repositorio = Repositorio.instancia;

  test('cria relatório, ativa e lista do mais novo para o mais antigo',
      () async {
    final primeiro = await repositorio.criarRelatorio(
      contratante: 'Marcenaria Bela Vista ME',
      prestador: 'Ana Paula Souza',
      obra: 'Reforma do galpão',
      valorCentavos: 9434800,
      dataInicio: DateTime(2026, 6, 16),
    );
    expect(primeiro.ativo, isTrue);
    expect(await repositorio.buscarAtivo(), isNotNull);

    final segundo = await repositorio.criarRelatorio(
      contratante: 'Construtora Aurora LTDA',
      prestador: 'Carlos Eduardo Lima',
      obra: '',
      valorCentavos: 500000,
      dataInicio: DateTime(2026, 7, 1),
    );

    final lista = await repositorio.listarRelatorios();
    expect(lista.length, 2);
    expect(lista.first.id, segundo.id, reason: 'o último criado fica no topo');
    expect(lista.first.ativo, isTrue);
    expect((await repositorio.buscarRelatorio(primeiro.id!))!.ativo, isFalse);
  });

  test('lança pagamentos e calcula o total', () async {
    final relatorio = (await repositorio.buscarAtivo())!;
    await repositorio.adicionarPagamento(
      Pagamento(
        relatorioId: relatorio.id!,
        tipo: TipoPagamento.normal,
        valorCentavos: 700000,
        data: DateTime(2026, 6, 16),
        criadoEm: DateTime(2026, 6, 16, 10),
      ),
    );
    await repositorio.adicionarPagamento(
      Pagamento(
        relatorioId: relatorio.id!,
        tipo: TipoPagamento.antecipado,
        valorCentavos: 300000,
        data: DateTime(2026, 6, 10),
        criadoEm: DateTime(2026, 6, 10, 9),
      ),
    );

    final pagamentos = await repositorio.listarPagamentos(relatorio.id!);
    expect(pagamentos.length, 2);
    expect(pagamentos.first.tipo, TipoPagamento.antecipado,
        reason: 'ordem por data');
    expect(
      pagamentos.fold<int>(0, (soma, item) => soma + item.valorCentavos),
      1000000,
    );
  });

  test('apagar o relatório ativo abre o mais recente que sobrou', () async {
    final ativo = (await repositorio.buscarAtivo())!;
    await repositorio.excluirRelatorio(ativo.id!);

    final novoAtivo = await repositorio.buscarAtivo();
    expect(novoAtivo, isNotNull);
    expect(novoAtivo!.contratante, 'Marcenaria Bela Vista ME');
    expect(await repositorio.listarPagamentos(ativo.id!), isEmpty,
        reason: 'os pagamentos são apagados junto');
  });

  test('abrir um relatório anterior devolve a fila', () async {
    final lista = await repositorio.listarRelatorios();
    final outro = await repositorio.criarRelatorio(
      contratante: 'Terceiro Contrato',
      prestador: 'Maria Silva',
      obra: '',
      valorCentavos: 100000,
      dataInicio: DateTime(2026, 8, 1),
    );
    await repositorio.ativarRelatorio(lista.first.id!);

    final ativo = (await repositorio.buscarAtivo())!;
    expect(ativo.id, lista.first.id);
    expect((await repositorio.buscarRelatorio(outro.id!))!.ativo, isFalse);
  });

  test('backup exporta e restaura os dados', () async {
    final dados = await repositorio.exportarDados();
    expect(dados['relatorios'], isA<List>());
    expect((dados['relatorios'] as List).isNotEmpty, isTrue);

    await repositorio.importarDados(dados);
    final lista = await repositorio.listarRelatorios();
    expect(lista.length, (dados['relatorios'] as List).length);
    expect(await repositorio.buscarAtivo(), isNotNull);
  });

  test('recusa backup inválido', () async {
    expect(
      () => repositorio.importarDados({'relatorios': 'nada'}),
      throwsA(isA<FormatException>()),
    );
  });
}
