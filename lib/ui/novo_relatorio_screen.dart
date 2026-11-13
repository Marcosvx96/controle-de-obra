import 'package:flutter/material.dart';

import '../core/formatadores.dart';
import '../core/moeda_input_formatter.dart';
import '../data/repositorio.dart';
import 'tema.dart';

class NovoRelatorioScreen extends StatefulWidget {
  const NovoRelatorioScreen({super.key});

  @override
  State<NovoRelatorioScreen> createState() => _NovoRelatorioScreenState();
}

class _NovoRelatorioScreenState extends State<NovoRelatorioScreen> {
  final _formKey = GlobalKey<FormState>();
  final _contratante = TextEditingController();
  final _prestador = TextEditingController();
  final _obra = TextEditingController();
  final _valor = TextEditingController();
  DateTime _dataInicio = somenteData(DateTime.now());
  bool _salvando = false;

  @override
  void dispose() {
    _contratante.dispose();
    _prestador.dispose();
    _obra.dispose();
    _valor.dispose();
    super.dispose();
  }

  Future<void> _escolherData() async {
    final escolhida = await showDatePicker(
      context: context,
      initialDate: _dataInicio,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      locale: const Locale('pt', 'BR'),
    );
    if (escolhida != null) setState(() => _dataInicio = escolhida);
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _salvando = true);
    await Repositorio.instancia.criarRelatorio(
      contratante: _contratante.text.trim(),
      prestador: _prestador.text.trim(),
      obra: _obra.text.trim(),
      valorCentavos: centavosDoTexto(_valor.text),
      dataInicio: _dataInicio,
    );
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Novo relatório')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            children: [
              const Text(
                'Dados do contrato',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              const Text(
                'Preencha e o relatório já abre na tela principal.',
                style: TextStyle(fontSize: 16, color: textoFraco),
              ),
              const SizedBox(height: 24),
              InkWell(
                onTap: _escolherData,
                borderRadius: BorderRadius.circular(14),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Data de início',
                    suffixIcon: Icon(Icons.event_outlined, size: 26),
                  ),
                  child: Text(
                    formatarData(_dataInicio),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contratante,
                textCapitalization: TextCapitalization.words,
                style: const TextStyle(fontSize: 20),
                decoration: const InputDecoration(
                  labelText: 'Nome do contratante',
                  hintText: 'Quem está pagando',
                ),
                validator: (texto) => (texto ?? '').trim().isEmpty
                    ? 'Informe o nome do contratante.'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _prestador,
                textCapitalization: TextCapitalization.words,
                style: const TextStyle(fontSize: 20),
                decoration: const InputDecoration(
                  labelText: 'Nome do prestador',
                  hintText: 'Quem está recebendo',
                ),
                validator: (texto) => (texto ?? '').trim().isEmpty
                    ? 'Informe o nome do prestador.'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _obra,
                textCapitalization: TextCapitalization.sentences,
                style: const TextStyle(fontSize: 20),
                decoration: const InputDecoration(
                  labelText: 'Obra ou serviço (opcional)',
                  hintText: 'Ex.: reforma do galpão',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _valor,
                keyboardType: TextInputType.number,
                inputFormatters: const [MoedaInputFormatter()],
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
                decoration: const InputDecoration(
                  labelText: 'Valor total do contrato',
                  prefixText: 'R\$ ',
                  prefixStyle: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: textoFraco,
                  ),
                  hintText: '0,00',
                ),
                validator: (texto) => centavosDoTexto(texto ?? '') <= 0
                    ? 'Digite o valor do contrato.'
                    : null,
              ),
              const SizedBox(height: 30),
              SizedBox(
                height: 60,
                child: FilledButton.icon(
                  onPressed: _salvando ? null : _salvar,
                  icon: const Icon(Icons.check, size: 26),
                  label: Text(
                    _salvando ? 'SALVANDO...' : 'SALVAR E ABRIR',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: azulEscuro,
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
