import 'package:flutter/material.dart';

const kPrimary = Color(0xFF22C55E); // أخضر للسائق
const kBg      = Color(0xFF0D0F1A);
const kCard    = Color(0xFF1A1C2E);
const kNav     = Color(0xFF13152A);
const kBorder  = Color(0xFF2A2D45);
const kMuted   = Color(0xFF9B9DB5);
const kOrange  = Color(0xFFE8622A);

ThemeData buildTheme() => ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: kBg,
  colorScheme: ColorScheme.dark(primary: kPrimary, surface: kCard),
  appBarTheme: const AppBarTheme(
    backgroundColor: kBg, elevation: 0, centerTitle: true,
    titleTextStyle: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
    iconTheme: IconThemeData(color: Colors.white),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: kPrimary, foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      minimumSize: const Size(double.infinity, 52),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true, fillColor: kCard,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: kBorder)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: kBorder)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: kPrimary, width: 1.5)),
    hintStyle: const TextStyle(color: kMuted),
  ),
);
