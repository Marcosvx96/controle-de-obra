import 'package:flutter/material.dart';

const Color azulEscuro = Color(0xFF0F3D5C);
const Color azulMedio = Color(0xFF17638C);
const Color verdePago = Color(0xFF1E7A46);
const Color laranjaSaldo = Color(0xFFB45309);
const Color vermelhoApagar = Color(0xFFB3261E);
const Color fundoClaro = Color(0xFFF1F4F7);
const Color textoForte = Color(0xFF16232E);
const Color textoFraco = Color(0xFF51616E);
const Color bordaSuave = Color(0xFFD8E0E6);

ThemeData construirTema() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: azulEscuro).copyWith(
      primary: azulEscuro,
      secondary: azulMedio,
      surface: Colors.white,
    ),
    scaffoldBackgroundColor: fundoClaro,
  );

  return base.copyWith(
    textTheme: base.textTheme
        .apply(bodyColor: textoForte, displayColor: textoForte)
        .copyWith(
          bodyLarge: const TextStyle(
            fontSize: 18,
            height: 1.35,
            color: textoForte,
          ),
          bodyMedium: const TextStyle(
            fontSize: 17,
            height: 1.35,
            color: textoForte,
          ),
          titleLarge: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: textoForte,
          ),
          titleMedium: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: textoForte,
          ),
        ),
    appBarTheme: const AppBarTheme(
      backgroundColor: azulEscuro,
      foregroundColor: Colors.white,
      centerTitle: false,
      toolbarHeight: 68,
      titleTextStyle: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        color: Colors.white,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      labelStyle: const TextStyle(fontSize: 17, color: textoFraco),
      hintStyle: const TextStyle(fontSize: 17, color: textoFraco),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: bordaSuave),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: bordaSuave),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: azulMedio, width: 2),
      ),
      errorStyle: const TextStyle(fontSize: 15),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: textoForte,
      contentTextStyle: TextStyle(fontSize: 17, color: Colors.white),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
