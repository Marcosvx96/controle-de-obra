import 'package:flutter/material.dart';

import '../core/formatadores.dart';
import '../data/models.dart';
import '../data/repositorio.dart';
import 'tema.dart';
import 'widgets.dart';

class HistoricoScreen extends StatefulWidget {
  const HistoricoScreen({super.key});

  @override
  State<HistoricoScreen> createState() => _HistoricoScreenState();
}

class _HistoricoScreenState extends State<HistoricoScreen> {
  final _busca = TextEditingController();
  List<Relatorio> _todos = const [];
  List<Relatorio> _filtrados = const [];
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void dispose() {
    _busca.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    final lista = await Repositorio.instancia.listarRelatorios();
    if (!mounted) return;
    setState(() {
      _todos = lista;
      _carregando = false;
    });
    _filtrar();
  }

  void _filtrar() {
    final termo = normalizar(_busca.text.trim());
    final lista = termo.isEmpty
        ? _todos
        : _todos.where((relatorio) {
            final texto = normalizar(
              '${relatorio.contratante} ${relatorio.prestador} '
              '${relatorio.obra} ${formatarData(relatorio.dataInicio)} '
              '${formatarData(relatorio.criadoEm)}',
            );
            return texto.contains(termo);
          }).toList();
    setState(() => _filtrados = lista);
  }

  Future<void> _abrirOpcoes(Relatorio relatorio) async {
    final acao = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (menu) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                relatorio.contratante,
                style:
                    const TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 2),
              Text(
                relatorio.prestador,
                style: const TextStyle(fontSize: 17, color: textoFraco),
              ),
              const SizedBox(height: 4),
              Text(
                'Início em ${formatarData(relatorio.dataInicio)} • '
                '${formatarMoeda(relatorio.valorCentavos)}',
                style: const TextStyle(fontSize: 15, color: textoFraco),
              ),
              const SizedBox(height: 20),
              _BotaoAcao(
                icone: Icons.folder_open_outlined,
                texto: 'ABRIR',
                cor: azulEscuro,
                preenchido: true,
                onTap: () => Navigator.pop(menu, 'abrir'),
              ),
              const SizedBox(height: 10),
              _BotaoAcao(
                icone: Icons.delete_forever_outlined,
                texto: 'APAGAR',
                cor: vermelhoApagar,
                onTap: () => Navigator.pop(menu, 'apagar'),
              ),
              const SizedBox(height: 10),
              _BotaoAcao(
                icone: Icons.arrow_back,
                texto: 'VOLTAR',
                cor: textoFraco,
                onTap: () => Navigator.pop(menu, 'voltar'),
              ),
            ],
          ),
        ),
      ),
    );

    if (acao == 'abrir') {
      await Repositorio.instancia.ativarRelatorio(relatorio.id!);
      if (!mounted) return;
      Navigator.pop(context, true);
    } else if (acao == 'apagar') {
      await _confirmarApagar(relatorio);
    }
  }

  Future<void> _confirmarApagar(Relatorio relatorio) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogo) => AlertDialog(
        title: const Text(
          'Apagar relatório?',
          style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
        ),
        content: Text(
          '"${relatorio.contratante}" e todos os pagamentos dele serão '
          'apagados para sempre. Não dá para desfazer.',
          style: const TextStyle(fontSize: 17, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogo, false),
            child: const Text('VOLTAR', style: TextStyle(fontSize: 17)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogo, true),
            style: FilledButton.styleFrom(backgroundColor: vermelhoApagar),
            child: const Text(
              'APAGAR DEFINITIVAMENTE',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
    if (confirmar != true) return;
    await Repositorio.instancia.excluirRelatorio(relatorio.id!);
    await _carregar();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Relatório apagado.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Relatórios anteriores')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                controller: _busca,
                onChanged: (_) => _filtrar(),
                style: const TextStyle(fontSize: 18),
                decoration: InputDecoration(
                  hintText: 'Buscar por nome, obra ou data',
                  prefixIcon: const Icon(Icons.search, size: 26),
                  suffixIcon: _busca.text.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _busca.clear();
                            _filtrar();
                          },
                          icon: const Icon(Icons.close),
                          tooltip: 'Limpar busca',
                        ),
                ),
              ),
            ),
            Expanded(
              child: _carregando
                  ? const Center(child: CircularProgressIndicator())
                  : _filtrados.isEmpty
                      ? _vazio()
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          itemCount: _filtrados.length,
                          itemBuilder: (contexto, indice) {
                            final relatorio = _filtrados[indice];
                            return _CartaoRelatorio(
                              relatorio: relatorio,
                              onTap: () => _abrirOpcoes(relatorio),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _vazio() {
    final buscando = _busca.text.trim().isNotEmpty;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              buscando ? Icons.search_off : Icons.folder_open_outlined,
              size: 82,
              color: azulMedio.withValues(alpha: 0.30),
            ),
            const SizedBox(height: 16),
            Text(
              buscando
                  ? 'Nada encontrado'
                  : 'Nenhum relatório salvo ainda',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              buscando
                  ? 'Tente outro nome ou outra data.'
                  : 'Crie um relatório no menu para ele aparecer aqui.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 17, color: textoFraco),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartaoRelatorio extends StatelessWidget {
  const _CartaoRelatorio({required this.relatorio, required this.onTap});

  final Relatorio relatorio;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: relatorio.ativo ? verdePago : bordaSuave,
                width: relatorio.ativo ? 2 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        relatorio.contratante,
                        style: const TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (relatorio.ativo) const SeloEmUso(),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  relatorio.prestador,
                  style: const TextStyle(fontSize: 17, color: textoFraco),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.event_outlined,
                        size: 18, color: textoFraco),
                    const SizedBox(width: 5),
                    Text(
                      formatarData(relatorio.dataInicio),
                      style: const TextStyle(fontSize: 15, color: textoFraco),
                    ),
                    const Spacer(),
                    Text(
                      formatarMoeda(relatorio.valorCentavos),
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BotaoAcao extends StatelessWidget {
  const _BotaoAcao({
    required this.icone,
    required this.texto,
    required this.cor,
    required this.onTap,
    this.preenchido = false,
  });

  final IconData icone;
  final String texto;
  final Color cor;
  final VoidCallback onTap;
  final bool preenchido;

  @override
  Widget build(BuildContext context) {
    final estilo = preenchido
        ? FilledButton.styleFrom(backgroundColor: cor)
        : OutlinedButton.styleFrom(
            foregroundColor: cor,
            side: BorderSide(color: cor, width: 1.6),
          );
    final filho = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icone, size: 24),
        const SizedBox(width: 10),
        Text(
          texto,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
      ],
    );
    return SizedBox(
      height: 56,
      child: preenchido
          ? FilledButton(
              onPressed: onTap,
              style: estilo.copyWith(
                shape: WidgetStatePropertyAll(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              child: filho,
            )
          : OutlinedButton(
              onPressed: onTap,
              style: estilo.copyWith(
                shape: WidgetStatePropertyAll(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              child: filho,
            ),
    );
  }
}
