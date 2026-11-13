import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'ui/home_screen.dart';
import 'ui/tema.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AplicativoControle());
}

class AplicativoControle extends StatelessWidget {
  const AplicativoControle({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Controle de Pagamento',
      debugShowCheckedModeBanner: false,
      theme: construirTema(),
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
  }
}
