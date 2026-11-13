import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../core/data_input_formatter.dart';
import '../core/formatadores.dart';
import '../core/moeda_input_formatter.dart';
import '../data/models.dart';
import '../data/repositorio.dart';
import '../pdf/pdf_actions.dart';
import 'campo_data.dart';
import 'tema.dart';

class DialogoPagamento extends StatefulWidget {
  const DialogoPagamento({
    super.key,
    required this.relatorioId,
    required this.saldoCentavos,
  });

  final int relatorioId;
  final int saldoCentavos;

  @override
  State<DialogoPagamento> createState() => _DialogoPagamentoState();
}

class _DialogoPagamentoState extends State<DialogoPagamento> {
  final _formKey = GlobalKey<FormState>();
  final _valor = TextEditingController();
  final _dataTexto = TextEditingController();
  DateTime _data = somenteData(DateTime.now());
  TipoPagamento _tipo = TipoPagamento.normal;

  @override
  void initState() {
    super.initState();
    _dataTexto.text = formatarData(_data);
  }

  @override
  void dispose() {
    _valor.dispose();
    _dataTexto.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    final data = dataDoTexto(_dataTexto.text);
    if (data == null) return;
    final valor = centavosDoTexto(_valor.text);
    if (widget.saldoCentavos > 0 && valor > widget.saldoCentavos) {
      final confirmar = await showDialog<bool>(
        context: context,
        builder: (dialogo) => AlertDialog(
          title: const Text('Valor acima do saldo'),
          content: Text(
            'Esse pagamento (${formatarMoeda(valor)}) passa do saldo restante '
            '(${formatarMoeda(widget.saldoCentavos)}). Salvar mesmo assim?',
            style: const TextStyle(fontSize: 17),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogo, false),
              child: const Text('VOLTAR', style: TextStyle(fontSize: 17)),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogo, true),
              child: const Text('SALVAR', style: TextStyle(fontSize: 17)),
            ),
          ],
        ),
      );
      if (confirmar != true) return;
    }
    if (!mounted) return;
    Navigator.pop(
      context,
      Pagamento(
        relatorioId: widget.relatorioId,
        tipo: _tipo,
        valorCentavos: valor,
        data: data,
        criadoEm: DateTime.now(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        4,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Novo pagamento',
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                'Saldo restante: ${formatarMoeda(widget.saldoCentavos)}',
                style: const TextStyle(fontSize: 16, color: textoFraco),
              ),
              const SizedBox(height: 20),
              CampoData(
                label: 'Data do pagamento',
                controller: _dataTexto,
                onChanged: (data) {
                  if (data != null) _data = data;
                },
                tamanhoTexto: 19,
                negrito: true,
              ),
              const SizedBox(height: 18),
              const _TituloCampo('Tipo do pagamento'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: TipoPagamento.values.map((tipo) {
                  return ChoiceChip(
                    label: Text(
                      tipo.rotulo,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color:
                            _tipo == tipo ? Colors.white : textoForte,
                      ),
                    ),
                    selected: _tipo == tipo,
                    selectedColor: azulMedio,
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    onSelected: (_) => setState(() => _tipo = tipo),
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),
              const _TituloCampo('Valor'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _valor,
                keyboardType: TextInputType.number,
                inputFormatters: const [MoedaInputFormatter()],
                style: const TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.w800,
                ),
                decoration: const InputDecoration(
                  prefixText: 'R\$ ',
                  prefixStyle: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: textoFraco,
                  ),
                  hintText: '0,00',
                ),
                validator: (texto) {
                  if (centavosDoTexto(texto ?? '') <= 0) {
                    return 'Digite o valor do pagamento.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 26),
              SizedBox(
                height: 58,
                child: FilledButton(
                  onPressed: _salvar,
                  style: FilledButton.styleFrom(
                    backgroundColor: azulEscuro,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'SALVAR PAGAMENTO',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
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

class EditarContratoDialog extends StatefulWidget {
  const EditarContratoDialog({super.key, required this.relatorio});

  final Relatorio relatorio;

  @override
  State<EditarContratoDialog> createState() => _EditarContratoDialogState();
}

class _EditarContratoDialogState extends State<EditarContratoDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _contratante;
  late final TextEditingController _prestador;
  late final TextEditingController _obra;
  late final TextEditingController _valor;
  late final TextEditingController _dataTexto;
  late DateTime _dataInicio;

  @override
  void initState() {
    super.initState();
    _contratante = TextEditingController(text: widget.relatorio.contratante);
    _prestador = TextEditingController(text: widget.relatorio.prestador);
    _obra = TextEditingController(text: widget.relatorio.obra);
    _valor = TextEditingController(
      text: formatarValorSemSimbolo(widget.relatorio.valorCentavos),
    );
    _dataInicio = widget.relatorio.dataInicio;
    _dataTexto = TextEditingController(text: formatarData(_dataInicio));
  }

  @override
  void dispose() {
    _contratante.dispose();
    _prestador.dispose();
    _obra.dispose();
    _valor.dispose();
    _dataTexto.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    final dataInicio = dataDoTexto(_dataTexto.text);
    if (dataInicio == null) return;
    await Repositorio.instancia.atualizarRelatorio(
      widget.relatorio.copyWith(
        contratante: _contratante.text.trim(),
        prestador: _prestador.text.trim(),
        obra: _obra.text.trim(),
        valorCentavos: centavosDoTexto(_valor.text),
        dataInicio: dataInicio,
      ),
    );
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      insetPadding: const EdgeInsets.all(16),
      title: const Text(
        'Editar contrato',
        style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
      ),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _contratante,
                  textCapitalization: TextCapitalization.words,
                  style: const TextStyle(fontSize: 19),
                  decoration: const InputDecoration(labelText: 'Contratante'),
                  validator: (texto) => (texto ?? '').trim().isEmpty
                      ? 'Informe o contratante.'
                      : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _prestador,
                  textCapitalization: TextCapitalization.words,
                  style: const TextStyle(fontSize: 19),
                  decoration: const InputDecoration(labelText: 'Prestador'),
                  validator: (texto) => (texto ?? '').trim().isEmpty
                      ? 'Informe o prestador.'
                      : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _obra,
                  textCapitalization: TextCapitalization.sentences,
                  style: const TextStyle(fontSize: 19),
                  decoration: const InputDecoration(
                    labelText: 'Obra ou serviço (opcional)',
                  ),
                ),
                const SizedBox(height: 14),
                CampoData(
                  label: 'Data de início',
                  controller: _dataTexto,
                  onChanged: (data) {
                    if (data != null) _dataInicio = data;
                  },
                  tamanhoTexto: 19,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _valor,
                  keyboardType: TextInputType.number,
                  inputFormatters: const [MoedaInputFormatter()],
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Valor do contrato',
                    prefixText: 'R\$ ',
                  ),
                  validator: (texto) => centavosDoTexto(texto ?? '') <= 0
                      ? 'Digite o valor do contrato.'
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('VOLTAR', style: TextStyle(fontSize: 17)),
        ),
        FilledButton(
          onPressed: _salvar,
          style: FilledButton.styleFrom(backgroundColor: azulEscuro),
          child: const Text('SALVAR', style: TextStyle(fontSize: 17)),
        ),
      ],
    );
  }
}

class OpcoesPdf extends StatelessWidget {
  const OpcoesPdf({super.key, required this.bytes, required this.nome});

  final Uint8List bytes;
  final String nome;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(4, 0, 4, 12),
              child: Text(
                'PDF pronto',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
              ),
            ),
            _Opcao(
              icone: Icons.download_for_offline_outlined,
              titulo: 'SALVAR NO CELULAR',
              descricao:
                  'Abre a tela do Android. Toque em "Salvar como PDF".',
              cor: azulEscuro,
              onTap: () async {
                Navigator.pop(context);
                await PdfActions.salvarOuImprimir(bytes, nome);
              },
            ),
            const SizedBox(height: 10),
            _Opcao(
              icone: Icons.share_outlined,
              titulo: 'COMPARTILHAR',
              descricao: 'Enviar pelo WhatsApp, e-mail ou Drive.',
              cor: verdePago,
              onTap: () async {
                Navigator.pop(context);
                await PdfActions.compartilhar(bytes, nome);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Opcao extends StatelessWidget {
  const _Opcao({
    required this.icone,
    required this.titulo,
    required this.descricao,
    required this.cor,
    required this.onTap,
  });

  final IconData icone;
  final String titulo;
  final String descricao;
  final Color cor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cor.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: cor.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            Icon(icone, size: 32, color: cor),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: cor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    descricao,
                    style: const TextStyle(
                      fontSize: 15,
                      color: textoFraco,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TituloCampo extends StatelessWidget {
  const _TituloCampo(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Text(
      texto,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: textoFraco,
        letterSpacing: 1.1,
      ),
    );
  }
}
