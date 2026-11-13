// Gera as imagens usadas no README.
//
// Rode somente quando quiser atualizar as capturas:
//   flutter test test/screenshot_test.dart --update-goldens \
//     --dart-define=GERAR_SCREENSHOTS=true
//
// Sem essa opção o teste é ignorado, então `flutter test` continua rápido e
// estável em qualquer máquina (as fontes mudam um pouco entre sistemas).
import 'package:controle_mao_de_obra/data/models.dart';
import 'package:controle_mao_de_obra/data/repositorio.dart';
import 'package:controle_mao_de_obra/ui/home_screen.dart';
import 'package:controle_mao_de_obra/ui/tema.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader, rootBundle;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const bool gerarCapturas = bool.fromEnvironment('GERAR_SCREENSHOTS');
const String _familia = 'NotoSansUI';

/// O teste usa a fonte Ahem (quadradinhos) por padrão; aqui carregamos a mesma
/// fonte do PDF para a captura ficar parecida com o app de verdade.
Future<void> _carregarFonte() async {
  final loader = FontLoader(_familia)
    ..addFont(rootBundle.load('assets/fonts/NotoSans-Regular.ttf'))
    ..addFont(rootBundle.load('assets/fonts/NotoSans-Bold.ttf'));
  await loader.load();
}

ThemeData _tema() {
  final base = construirTema();
  return base.copyWith(
    textTheme: base.textTheme.apply(fontFamily: _familia),
    primaryTextTheme: base.primaryTextTheme.apply(fontFamily: _familia),
    appBarTheme: base.appBarTheme.copyWith(
      titleTextStyle:
          base.appBarTheme.titleTextStyle?.copyWith(fontFamily: _familia),
    ),
  );
}

Widget _app() => MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: _tema(),
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => MediaQuery.withClampedTextScaling(
        minScaleFactor: 1,
        maxScaleFactor: 1.3,
        child: child!,
      ),
      home: const HomeScreen(),
    );

/// Deixa o banco (que roda de verdade) terminar antes de continuar.
Future<void> _assentar(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump();
  }
  await tester.pumpAndSettle();
}

Future<void> _semear() async {
  final repo = Repositorio.instancia;

  await repo.criarRelatorio(
    contratante: 'Conceição Construções',
    prestador: 'João Ávila',
    obra: 'Pintura da fachada',
    valorCentavos: 1250000,
    dataInicio: DateTime(2026, 3, 2),
  );

  final atual = await repo.criarRelatorio(
    contratante: 'Fearless Marketing LTDA',
    prestador: 'Denrleso Calvon',
    obra: 'Reforma do galpão',
    valorCentavos: 9434800,
    dataInicio: DateTime(2026, 6, 16),
  );

  final pagamentos = [
    (DateTime(2026, 6, 16), TipoPagamento.normal, 700000),
    (DateTime(2026, 6, 26), TipoPagamento.normal, 650000),
    (DateTime(2026, 7, 8), TipoPagamento.normal, 530000),
    (DateTime(2026, 8, 12), TipoPagamento.antecipado, 300000),
  ];

  for (final (data, tipo, valor) in pagamentos) {
    await repo.adicionarPagamento(
      Pagamento(
        relatorioId: atual.id!,
        tipo: tipo,
        valorCentavos: valor,
        data: data,
        criadoEm: DateTime(data.year, data.month, data.day, 9),
      ),
    );
  }
}

void main() {
  setUpAll(() async {
    sqfliteFfiInit();
    sqflite.databaseFactory = databaseFactoryFfi;
    Banco.caminhoPersonalizado = inMemoryDatabasePath;
    await _carregarFonte();
  });

  testWidgets(
    'captura a tela principal e os relatórios anteriores',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.runAsync(_semear);

      await tester.pumpWidget(_app());
      await _assentar(tester);

      // Checagem simples: se a fonte não tivesse sido carregada, o texto
      // sairia com a fonte de teste (cada letra com a largura exata do
      // tamanho da fonte) e a captura ficaria cheia de quadradinhos.
      final titulo = tester.getSize(find.text('CONTROLE DE PAGAMENTO'));
      debugPrint('largura do título: ${titulo.width.toStringAsFixed(1)}px');

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('../screenshots/app-inicio.png'),
      );

      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Relatórios anteriores'));
      await _assentar(tester);

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('../screenshots/app-relatorios.png'),
      );
    },
    skip: !gerarCapturas,
  );
}
