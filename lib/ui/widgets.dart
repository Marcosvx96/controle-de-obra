import 'package:flutter/material.dart';

import '../core/formatadores.dart';
import '../data/models.dart';
import 'tema.dart';

class CabecalhoApp extends StatelessWidget {
  const CabecalhoApp({super.key, required this.onMenu});

  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [azulEscuro, azulMedio],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(18, 14, 8, 16),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CONTROLE DE PAGAMENTO',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFBFD8E8),
                    letterSpacing: 1.2,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'DE MÃO DE OBRA',
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.4,
                    height: 1.15,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onMenu,
            icon: const Icon(Icons.menu),
            iconSize: 34,
            color: Colors.white,
            tooltip: 'Menu',
            style: IconButton.styleFrom(
              minimumSize: const Size(56, 56),
            ),
          ),
        ],
      ),
    );
  }
}

class Cartao extends StatelessWidget {
  const Cartao({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: azulEscuro.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

class ResumoCard extends StatelessWidget {
  const ResumoCard({
    super.key,
    required this.relatorio,
    required this.totalPago,
    required this.onEditar,
  });

  final Relatorio relatorio;
  final int totalPago;
  final VoidCallback onEditar;

  @override
  Widget build(BuildContext context) {
    final saldo = relatorio.valorCentavos - totalPago;
    final progresso = progressoPago(relatorio.valorCentavos, totalPago);
    final percentual = (progresso * 100).round();

    return Cartao(
      padding: const EdgeInsets.fromLTRB(18, 16, 12, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _Rotulo('CONTRATANTE'),
                    const SizedBox(height: 2),
                    Text(
                      relatorio.contratante,
                      style: const TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onEditar,
                icon: const Icon(Icons.edit_outlined),
                iconSize: 27,
                color: azulMedio,
                tooltip: 'Editar contratante',
                style: IconButton.styleFrom(
                  backgroundColor: azulMedio.withValues(alpha: 0.10),
                  minimumSize: const Size(50, 50),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _Rotulo('PRESTADOR'),
                    Text(
                      relatorio.prestador,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onEditar,
                icon: const Icon(Icons.edit_outlined),
                iconSize: 21,
                color: textoFraco,
                tooltip: 'Editar prestador',
                visualDensity: VisualDensity.compact,
                style: IconButton.styleFrom(
                  minimumSize: const Size(42, 42),
                  backgroundColor: fundoClaro,
                ),
              ),
            ],
          ),
          if (relatorio.obra.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Obra: ${relatorio.obra}',
              style: const TextStyle(fontSize: 16, color: textoFraco),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.event_outlined, size: 19, color: textoFraco),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Início em ${formatarData(relatorio.dataInicio)}',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 16, color: textoFraco),
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(height: 1, color: bordaSuave),
          ),
          const _Rotulo('VALOR CONTRATADO'),
          const SizedBox(height: 2),
          Text(
            formatarMoeda(relatorio.valorCentavos),
            style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _CaixaValor(
                  rotulo: 'TOTAL PAGO',
                  valor: formatarMoeda(totalPago),
                  cor: verdePago,
                  fundo: verdePago.withValues(alpha: 0.10),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _CaixaValor(
                  rotulo: 'SALDO RESTANTE',
                  valor: formatarMoeda(saldo),
                  cor: saldo < 0 ? vermelhoApagar : laranjaSaldo,
                  fundo: (saldo < 0 ? vermelhoApagar : laranjaSaldo)
                      .withValues(alpha: 0.10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const _Rotulo('PROGRESSO'),
              const Spacer(),
              Text(
                '$percentual%',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: azulEscuro,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progresso,
              minHeight: 12,
              backgroundColor: bordaSuave,
              valueColor: AlwaysStoppedAnimation<Color>(
                progresso >= 1 ? verdePago : azulMedio,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Rotulo extends StatelessWidget {
  const _Rotulo(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Text(
      texto,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: textoFraco,
        letterSpacing: 1.3,
      ),
    );
  }
}

class _CaixaValor extends StatelessWidget {
  const _CaixaValor({
    required this.rotulo,
    required this.valor,
    required this.cor,
    required this.fundo,
  });

  final String rotulo;
  final String valor;
  final Color cor;
  final Color fundo;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: fundo,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            rotulo,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: cor,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              valor,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: cor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class EtiquetaTipo extends StatelessWidget {
  const EtiquetaTipo({super.key, required this.tipo});

  final TipoPagamento tipo;

  @override
  Widget build(BuildContext context) {
    final (cor, fundo) = switch (tipo) {
      TipoPagamento.normal => (azulMedio, azulMedio.withValues(alpha: 0.10)),
      TipoPagamento.antecipado => (
          const Color(0xFF6B4FA1),
          const Color(0xFF6B4FA1).withValues(alpha: 0.10),
        ),
      TipoPagamento.extra => (verdePago, verdePago.withValues(alpha: 0.10)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: fundo,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        tipo.rotulo,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: cor,
        ),
      ),
    );
  }
}

class SeloEmUso extends StatelessWidget {
  const SeloEmUso({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: verdePago.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        'EM USO',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: verdePago,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}
