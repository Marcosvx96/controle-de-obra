import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../core/formatadores.dart';
import 'models.dart';

class Banco {
  Banco._();
  static final Banco instancia = Banco._();

  Database? _banco;

  /// Caminho alternativo usado nos testes (banco em memória).
  static String? caminhoPersonalizado;

  Future<Database> get banco async {
    final existente = _banco;
    if (existente != null) return existente;
    final caminho = caminhoPersonalizado ??
        p.join(await getDatabasesPath(), 'controle_mao_de_obra.db');
    final aberto = await openDatabase(
      caminho,
      version: 1,
      onConfigure: (db) async => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: (db, versao) async {
        await db.execute('''
          CREATE TABLE relatorios (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            contratante TEXT NOT NULL,
            prestador TEXT NOT NULL,
            obra TEXT NOT NULL DEFAULT '',
            valor_centavos INTEGER NOT NULL,
            data_inicio TEXT NOT NULL,
            ativo INTEGER NOT NULL DEFAULT 0,
            criado_em TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE pagamentos (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            relatorio_id INTEGER NOT NULL,
            tipo TEXT NOT NULL,
            valor_centavos INTEGER NOT NULL,
            data_pagamento TEXT NOT NULL,
            criado_em TEXT NOT NULL,
            FOREIGN KEY (relatorio_id) REFERENCES relatorios (id) ON DELETE CASCADE
          )
        ''');
      },
    );
    _banco = aberto;
    return aberto;
  }
}

class Repositorio {
  Repositorio._();
  static final Repositorio instancia = Repositorio._();

  Future<Database> get _db => Banco.instancia.banco;

  // ---------------------------------------------------------------- relatórios
  Future<List<Relatorio>> listarRelatorios() async {
    final db = await _db;
    final linhas = await db.query(
      'relatorios',
      orderBy: 'criado_em DESC, id DESC',
    );
    return linhas.map(Relatorio.doMapa).toList();
  }

  Future<Relatorio?> buscarAtivo() async {
    final db = await _db;
    final linhas = await db.query(
      'relatorios',
      where: 'ativo = 1',
      orderBy: 'criado_em DESC, id DESC',
      limit: 1,
    );
    if (linhas.isEmpty) return null;
    return Relatorio.doMapa(linhas.first);
  }

  Future<Relatorio?> buscarRelatorio(int id) async {
    final db = await _db;
    final linhas =
        await db.query('relatorios', where: 'id = ?', whereArgs: [id], limit: 1);
    if (linhas.isEmpty) return null;
    return Relatorio.doMapa(linhas.first);
  }

  Future<Relatorio> criarRelatorio({
    required String contratante,
    required String prestador,
    required String obra,
    required int valorCentavos,
    required DateTime dataInicio,
  }) async {
    final db = await _db;
    late int id;
    await db.transaction((txn) async {
      await txn.update('relatorios', {'ativo': 0});
      id = await txn.insert('relatorios', {
        'contratante': contratante,
        'prestador': prestador,
        'obra': obra,
        'valor_centavos': valorCentavos,
        'data_inicio': dataParaBanco(dataInicio),
        'ativo': 1,
        'criado_em': DateTime.now().toIso8601String(),
      });
    });
    return (await buscarRelatorio(id))!;
  }

  Future<void> atualizarRelatorio(Relatorio relatorio) async {
    final db = await _db;
    await db.update(
      'relatorios',
      {
        'contratante': relatorio.contratante,
        'prestador': relatorio.prestador,
        'obra': relatorio.obra,
        'valor_centavos': relatorio.valorCentavos,
        'data_inicio': dataParaBanco(relatorio.dataInicio),
      },
      where: 'id = ?',
      whereArgs: [relatorio.id],
    );
  }

  Future<void> ativarRelatorio(int id) async {
    final db = await _db;
    await db.transaction((txn) async {
      await txn.update('relatorios', {'ativo': 0});
      await txn.update('relatorios', {'ativo': 1},
          where: 'id = ?', whereArgs: [id]);
    });
  }

  /// Apaga o relatório e todas as parcelas. Se era o ativo, abre o mais recente.
  Future<void> excluirRelatorio(int id) async {
    final db = await _db;
    await db.transaction((txn) async {
      await txn.delete('relatorios', where: 'id = ?', whereArgs: [id]);
      final ativos =
          await txn.query('relatorios', where: 'ativo = 1', limit: 1);
      if (ativos.isEmpty) {
        final restantes = await txn.query(
          'relatorios',
          orderBy: 'criado_em DESC, id DESC',
          limit: 1,
        );
        if (restantes.isNotEmpty) {
          await txn.update('relatorios', {'ativo': 1},
              where: 'id = ?', whereArgs: [restantes.first['id']]);
        }
      }
    });
  }

  // ---------------------------------------------------------------- pagamentos
  Future<List<Pagamento>> listarPagamentos(int relatorioId) async {
    final db = await _db;
    final linhas = await db.query(
      'pagamentos',
      where: 'relatorio_id = ?',
      whereArgs: [relatorioId],
      orderBy: 'data_pagamento ASC, id ASC',
    );
    return linhas.map(Pagamento.doMapa).toList();
  }

  Future<int> adicionarPagamento(Pagamento pagamento) async {
    final db = await _db;
    return db.insert('pagamentos', {
      'relatorio_id': pagamento.relatorioId,
      'tipo': pagamento.tipo.rotulo,
      'valor_centavos': pagamento.valorCentavos,
      'data_pagamento': dataParaBanco(pagamento.data),
      'criado_em': pagamento.criadoEm.toIso8601String(),
    });
  }

  Future<void> excluirPagamento(int id) async {
    final db = await _db;
    await db.delete('pagamentos', where: 'id = ?', whereArgs: [id]);
  }

  /// Usado pelo botão DESFAZER depois de apagar um pagamento.
  Future<void> recriarPagamento(Pagamento pagamento) async {
    await adicionarPagamento(pagamento);
  }

  // -------------------------------------------------------------------- backup
  Future<Map<String, dynamic>> exportarDados() async {
    final db = await _db;
    final relatorios = await db.query('relatorios', orderBy: 'id ASC');
    final pagamentos = await db.query('pagamentos', orderBy: 'id ASC');
    return {
      'aplicativo': 'controle_mao_de_obra',
      'versao_backup': 1,
      'exportado_em': DateTime.now().toIso8601String(),
      'relatorios': relatorios,
      'pagamentos': pagamentos,
    };
  }

  /// Substitui todos os dados pelos do backup.
  Future<void> importarDados(Map<String, dynamic> dados) async {
    final relatorios = dados['relatorios'];
    final pagamentos = dados['pagamentos'];
    if (relatorios is! List || pagamentos is! List) {
      throw const FormatException('Backup inválido.');
    }
    final db = await _db;
    await db.transaction((txn) async {
      await txn.delete('relatorios');
      await txn.delete('pagamentos');
      for (final item in relatorios) {
        final mapa = Map<String, Object?>.from(item as Map);
        await txn.insert('relatorios', {
          'id': mapa['id'],
          'contratante': mapa['contratante'] ?? '',
          'prestador': mapa['prestador'] ?? '',
          'obra': mapa['obra'] ?? '',
          'valor_centavos': mapa['valor_centavos'] ?? 0,
          'data_inicio': mapa['data_inicio'] ?? dataParaBanco(DateTime.now()),
          'ativo': mapa['ativo'] ?? 0,
          'criado_em': mapa['criado_em'] ?? DateTime.now().toIso8601String(),
        });
      }
      for (final item in pagamentos) {
        final mapa = Map<String, Object?>.from(item as Map);
        await txn.insert('pagamentos', {
          'id': mapa['id'],
          'relatorio_id': mapa['relatorio_id'],
          'tipo': mapa['tipo'] ?? 'Normal',
          'valor_centavos': mapa['valor_centavos'] ?? 0,
          'data_pagamento':
              mapa['data_pagamento'] ?? dataParaBanco(DateTime.now()),
          'criado_em': mapa['criado_em'] ?? DateTime.now().toIso8601String(),
        });
      }
      final ativos =
          await txn.query('relatorios', where: 'ativo = 1', limit: 1);
      if (ativos.isEmpty) {
        final primeiro = await txn.query('relatorios',
            orderBy: 'criado_em DESC, id DESC', limit: 1);
        if (primeiro.isNotEmpty) {
          await txn.update('relatorios', {'ativo': 1},
              where: 'id = ?', whereArgs: [primeiro.first['id']]);
        }
      }
    });
  }
}
