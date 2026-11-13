import 'package:controle_mao_de_obra/data/repositorio.dart';
import 'package:controle_mao_de_obra/main.dart';
import 'package:controle_mao_de_obra/ui/tema.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Deixa o banco (que roda de verdade) terminar antes de continuar o teste.
Future<void> assentar(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 120)),
    );
    await tester.pump();
  }
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    sqfliteFfiInit();
    sqflite.databaseFactory = databaseFactoryFfi;
    Banco.caminhoPersonalizado = inMemoryDatabasePath;
  });

  testWidgets('abre vazio, cria relatório e lança um pagamento',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const AplicativoControle());
    await assentar(tester);

    expect(find.text('CONTROLE DE PAGAMENTO'), findsOneWidget);
    expect(find.text('DE MÃO DE OBRA'), findsOneWidget);
    expect(find.text('Nenhum relatório aberto'), findsOneWidget);

    await tester.tap(find.text('CRIAR MEU PRIMEIRO RELATÓRIO'));
    await tester.pumpAndSettle();

    final campos = find.byType(TextFormField);
    await tester.enterText(campos.at(0), '16062026');
    await tester.enterText(campos.at(1), 'Marcenaria Bela Vista ME');
    await tester.enterText(campos.at(2), 'Ana Paula Souza');
    await tester.enterText(campos.at(3), 'Reforma do galpão');
    await tester.enterText(campos.at(4), '9434800');
    await tester.pump();

    // A máscara precisa colocar as barras sozinha.
    expect(find.text('16/06/2026'), findsOneWidget);

    await tester.tap(find.text('SALVAR E ABRIR'));
    await assentar(tester);

    expect(find.text('Marcenaria Bela Vista ME'), findsOneWidget);
    expect(find.text('Início em 16/06/2026'), findsOneWidget);
    expect(find.text('R\$ 94.348,00'), findsWidgets);
    expect(
      tester
          .renderObject<RenderParagraph>(
            find.text('Marcenaria Bela Vista ME'),
          )
          .text
          .style
          ?.color,
      textoForte,
      reason: 'nome e valores precisam sair na cor de texto, não invisíveis',
    );

    await tester.tap(find.text('ADICIONAR PAGAMENTO'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).last, '700000');
    await tester.pump();
    await tester.tap(find.text('SALVAR PAGAMENTO'));
    await assentar(tester);

    expect(find.text('R\$ 7.000,00'), findsWidgets);
    expect(find.text('R\$ 87.348,00'), findsWidgets);
  });

  testWidgets('menu abre as opções principais', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const AplicativoControle());
    await assentar(tester);

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();

    expect(find.text('Criar novo relatório'), findsOneWidget);
    expect(find.text('Relatórios anteriores'), findsOneWidget);
    expect(find.text('Exportar backup'), findsOneWidget);
    expect(find.text('Restaurar backup'), findsOneWidget);
  });
}
