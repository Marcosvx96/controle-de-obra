import 'package:flutter/material.dart';

import '../core/data_input_formatter.dart';
import '../core/formatadores.dart';

/// Campo de data que pode ser digitado (as barras entram sozinhas) ou
/// escolhido no calendário pelo ícone ao lado.
class CampoData extends StatefulWidget {
  const CampoData({
    super.key,
    required this.label,
    required this.controller,
    required this.onChanged,
    this.primeiraData,
    this.ultimaData,
    this.tamanhoTexto = 20,
    this.negrito = false,
    this.autofocus = false,
  });

  final String label;
  final TextEditingController controller;
  final ValueChanged<DateTime?> onChanged;
  final DateTime? primeiraData;
  final DateTime? ultimaData;
  final double tamanhoTexto;
  final bool negrito;
  final bool autofocus;

  @override
  State<CampoData> createState() => _CampoDataState();
}

class _CampoDataState extends State<CampoData> {
  final FocusNode _foco = FocusNode();

  @override
  void initState() {
    super.initState();
    _foco.addListener(_aoFocar);
  }

  @override
  void dispose() {
    _foco.dispose();
    super.dispose();
  }

  /// Ao tocar no campo, seleciona a data inteira: digitar já substitui.
  void _aoFocar() {
    if (!_foco.hasFocus) return;
    final texto = widget.controller.text;
    if (texto.isEmpty) return;
    widget.controller.selection =
        TextSelection(baseOffset: 0, extentOffset: texto.length);
  }

  DateTime get _primeira => widget.primeiraData ?? DateTime(2000);
  DateTime get _ultima => widget.ultimaData ?? DateTime(2100);

  Future<void> _escolherNoCalendario() async {
    var inicial = dataDoTexto(widget.controller.text) ??
        somenteData(DateTime.now());
    if (inicial.isBefore(_primeira)) inicial = _primeira;
    if (inicial.isAfter(_ultima)) inicial = _ultima;

    final escolhida = await showDatePicker(
      context: context,
      initialDate: inicial,
      firstDate: _primeira,
      lastDate: _ultima,
      locale: const Locale('pt', 'BR'),
      // Só o calendário: o modo de digitar do sistema não coloca as barras.
      initialEntryMode: DatePickerEntryMode.calendarOnly,
    );
    if (escolhida == null || !mounted) return;

    final data = somenteData(escolhida);
    widget.controller.value = TextEditingValue(
      text: formatarData(data),
      selection: TextSelection.collapsed(offset: 10),
    );
    widget.onChanged(data);
  }

  String? _validar(String? texto) {
    final data = dataDoTexto(texto ?? '');
    if (data == null) return 'Digite a data completa: dd/mm/aaaa.';
    if (data.isBefore(_primeira) || data.isAfter(_ultima)) {
      return 'Escolha uma data entre ${formatarData(_primeira)} '
          'e ${formatarData(_ultima)}.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      focusNode: _foco,
      keyboardType: TextInputType.number,
      inputFormatters: const [DataInputFormatter()],
      autofocus: widget.autofocus,
      style: TextStyle(
        fontSize: widget.tamanhoTexto,
        fontWeight: widget.negrito ? FontWeight.w600 : FontWeight.w500,
        letterSpacing: 0.5,
      ),
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: 'dd/mm/aaaa',
        suffixIcon: IconButton(
          onPressed: _escolherNoCalendario,
          tooltip: 'Escolher no calendário',
          icon: const Icon(Icons.event_outlined, size: 26),
        ),
      ),
      validator: _validar,
      onChanged: (texto) => widget.onChanged(dataDoTexto(texto)),
    );
  }
}
