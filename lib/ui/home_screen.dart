import 'package:flutter/material.dart';

import '../core/formatadores.dart';
import '../data/models.dart';
import '../data/repositorio.dart';
import '../pdf/pdf_service.dart';
import '../services/backup_service.dart';
import 'dialogos.dart';
import 'historico_screen.dart';
import 'novo_relatorio_screen.dart';
import 'tema.dart';
import 'widgets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Relatorio? _relatorio;
  List<Pagamento> _pagamentos = const [];
  bool _carregando = true;
  bool _gerandoPdf = false;

  int get _totalPago =>
      _pagamentos.fold<int>(0, (soma, item) => soma + item.valorCentavos);

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    final relatorio = await Repositorio.instancia.buscarAtivo();
    var pagamentos = <Pagamento>[];
    if (relatorio != null) {
      pagamentos = await Repositorio.instancia.listarPagamentos(relatorio.id!);
    }
    if (!mounted) return;
    setState(() {
      _relatorio = relatorio;
      _pagamentos = pagamentos;
      _carregando = false;
    });
  }

  void _aviso(String texto) {
    if (!mounted) return;
    final mensageiro = ScaffoldMessenger.of(context);
    mensageiro.hideCurrentSnackBar();
    mensageiro.showSnackBar(SnackBar(content: Text(texto)));
  }

  // ------------------------------------------------------------------ navegação
  Future<void> _abrirNovoRelatorio() async {
    final criado = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const NovoRelatorioScreen()),
    );
    if (criado == true) {
      await _carregar();
      _aviso('Relatório criado e aberto.');
    }
  }

  Future<void> _abrirHistorico() async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const HistoricoScreen()),
    );
    await _carregar();
  }

  // -------------------------------------------------------------------- ações
  Future<void> _editarContrato() async {
    final relatorio = _relatorio;
    if (relatorio == null) return;
    final alterado = await showDialog<bool>(
      context: context,
      builder: (_) => EditarContratoDialog(relatorio: relatorio),
    );
    if (alterado == true) {
      await _carregar();
      _aviso('Contrato atualizado.');
    }
  }

  Future<void> _novoPagamento() async {
    final relatorio = _relatorio;
    if (relatorio == null) return;
    final pagamento = await showModalBottomSheet<Pagamento>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => DialogoPagamento(
        relatorioId: relatorio.id!,
        saldoCentavos: relatorio.valorCentavos - _totalPago,
      ),
    );
    if (pagamento == null) return;
    await Repositorio.instancia.adicionarPagamento(pagamento);
    await _carregar();
    _aviso('Pagamento salvo.');
  }

  Future<void> _apagarPagamento(Pagamento pagamento) async {
    await Repositorio.instancia.excluirPagamento(pagamento.id!);
    await _carregar();
    if (!mounted) return;
    final mensageiro = ScaffoldMessenger.of(context);
    mensageiro.hideCurrentSnackBar();
    mensageiro.showSnackBar(
      SnackBar(
        content: const Text('Pagamento apagado.'),
        duration: const Duration(seconds: 6),
        action: SnackBarAction(
          label: 'DESFAZER',
          onPressed: () async {
            await Repositorio.instancia.recriarPagamento(pagamento);
            await _carregar();
          },
        ),
      ),
    );
  }

  Future<void> _baixarPdf() async {
    final relatorio = _relatorio;
    if (relatorio == null) return;
    setState(() => _gerandoPdf = true);
    try {
      final bytes = await PdfService.gerar(
        relatorio: relatorio,
        pagamentos: _pagamentos,
      );
      if (!mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (_) => OpcoesPdf(
          bytes: bytes,
          nome: PdfService.nomeArquivo(relatorio),
        ),
      );
    } catch (erro) {
      _aviso('Não foi possível gerar o PDF.');
    } finally {
      if (mounted) setState(() => _gerandoPdf = false);
    }
  }

  Future<void> _exportarBackup() async {
    try {
      await BackupService.exportar();
    } catch (erro) {
      _aviso('Não foi possível exportar o backup.');
    }
  }

  Future<void> _restaurarBackup() async {
    try {
      final dados = await BackupService.escolherBackup();
      if (dados == null || !mounted) return;
      final confirmar = await showDialog<bool>(
        context: context,
        builder: (dialogo) => AlertDialog(
          title: const Text(
            'Restaurar backup',
            style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
          ),
          content: const Text(
            'Todos os relatórios atuais serão substituídos pelos do backup. '
            'Essa ação não pode ser desfeita.',
            style: TextStyle(fontSize: 17),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogo, false),
              child: const Text('CANCELAR', style: TextStyle(fontSize: 17)),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogo, true),
              style: FilledButton.styleFrom(backgroundColor: vermelhoApagar),
              child: const Text('RESTAURAR', style: TextStyle(fontSize: 17)),
            ),
          ],
        ),
      );
      if (confirmar != true) return;
      await BackupService.restaurar(dados);
      await _carregar();
      _aviso('Backup restaurado.');
    } catch (erro) {
      _aviso('Arquivo de backup inválido.');
    }
  }

  // ---------------------------------------------------------------------- menu
  void _abrirMenu() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (menu) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _itemMenu(
              menu,
              Icons.note_add_outlined,
              'Criar novo relatório',
              null,
              () {
                Navigator.pop(menu);
                _abrirNovoRelatorio();
              },
            ),
            _itemMenu(
              menu,
              Icons.history,
              'Relatórios anteriores',
              'Abrir, apagar ou pesquisar',
              () {
                Navigator.pop(menu);
                _abrirHistorico();
              },
            ),
            const Divider(height: 1),
            _itemMenu(
              menu,
              Icons.upload_file_outlined,
              'Exportar backup',
              'Salvar uma cópia dos dados',
              () {
                Navigator.pop(menu);
                _exportarBackup();
              },
            ),
            _itemMenu(
              menu,
              Icons.download_outlined,
              'Restaurar backup',
              'Recuperar dados de uma cópia',
              () {
                Navigator.pop(menu);
                _restaurarBackup();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _itemMenu(
    BuildContext menu,
    IconData icone,
    String titulo,
    String? descricao,
    VoidCallback acao,
  ) {
    return ListTile(
      leading: Icon(icone, size: 30, color: azulEscuro),
      title: Text(
        titulo,
        style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w600),
      ),
      subtitle: descricao == null
          ? null
          : Text(
              descricao,
              style: const TextStyle(fontSize: 14, color: textoFraco),
            ),
      minVerticalPadding: 12,
      onTap: acao,
    );
  }

  // -------------------------------------------------------------------- layout
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            CabecalhoApp(onMenu: _abrirMenu),
            Expanded(
              child: _carregando
                  ? const Center(child: CircularProgressIndicator())
                  : _relatorio == null
                      ? _semRelatorio()
                      : _conteudo(),
            ),
            if (!_carregando && _relatorio != null) _barraInferior(),
          ],
        ),
      ),
    );
  }

  Widget _semRelatorio() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.description_outlined,
              size: 96,
              color: azulMedio.withValues(alpha: 0.30),
            ),
            const SizedBox(height: 20),
            const Text(
              'Nenhum relatório aberto',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            const Text(
              'Crie o primeiro relatório para começar a controlar os pagamentos.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, color: textoFraco, height: 1.4),
            ),
            const SizedBox(height: 28),
            SizedBox(
              height: 60,
              child: FilledButton.icon(
                onPressed: _abrirNovoRelatorio,
                icon: const Icon(Icons.add, size: 28),
                label: const Text(
                  'CRIAR MEU PRIMEIRO RELATÓRIO',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: azulEscuro,
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _conteudo() {
    final relatorio = _relatorio!;
    return RefreshIndicator(
      onRefresh: _carregar,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
        children: [
          ResumoCard(
            relatorio: relatorio,
            totalPago: _totalPago,
            onEditar: _editarContrato,
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              const Text(
                'PAGAMENTOS EFETUADOS',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: textoFraco,
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
                decoration: BoxDecoration(
                  color: azulEscuro.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_pagamentos.length}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: azulEscuro,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_pagamentos.isEmpty)
            Cartao(
              child: Column(
                children: [
                  Icon(
                    Icons.payments_outlined,
                    size: 46,
                    color: textoFraco.withValues(alpha: 0.55),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Nenhum pagamento ainda',
                    style:
                        TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Toque em ADICIONAR PAGAMENTO para lançar o primeiro.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: textoFraco),
                  ),
                ],
              ),
            )
          else
            ...List.generate(
              _pagamentos.length,
              (indice) => _LinhaPagamento(
                numero: indice + 1,
                pagamento: _pagamentos[indice],
                onApagar: () => _apagarPagamento(_pagamentos[indice]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _barraInferior() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Flexible(
                    child: Text(
                      'SUBTOTAL',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: textoFraco,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(
                        formatarMoeda(_totalPago),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: azulEscuro,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 58,
                child: FilledButton.icon(
                  onPressed: _gerandoPdf ? null : _novoPagamento,
                  icon: const Icon(Icons.add_circle_outline, size: 26),
                  label: const Text(
                    'ADICIONAR PAGAMENTO',
                    style:
                        TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: azulEscuro,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: _gerandoPdf ? null : _baixarPdf,
                  icon: _gerandoPdf
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.picture_as_pdf_outlined, size: 24),
                  label: Text(
                    _gerandoPdf ? 'GERANDO PDF...' : 'BAIXAR PDF',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: azulEscuro,
                    side: const BorderSide(color: azulEscuro, width: 1.6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LinhaPagamento extends StatelessWidget {
  const _LinhaPagamento({
    required this.numero,
    required this.pagamento,
    required this.onApagar,
  });

  final int numero;
  final Pagamento pagamento;
  final VoidCallback onApagar;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: bordaSuave),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: azulMedio.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Text(
              '$numero',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: azulEscuro,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formatarData(pagamento.data),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                EtiquetaTipo(tipo: pagamento.tipo),
              ],
            ),
          ),
          Text(
            formatarMoeda(pagamento.valorCentavos),
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
          IconButton(
            onPressed: onApagar,
            icon: const Icon(Icons.delete_outline),
            iconSize: 23,
            color: vermelhoApagar,
            tooltip: 'Apagar pagamento',
          ),
        ],
      ),
    );
  }
}
