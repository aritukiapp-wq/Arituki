/// Define los temas de la aplicación, tanto claro como oscuro.
///
/// Esta clase centraliza la configuración visual de la aplicación. Contiene
/// definiciones estáticas para `lightTheme` y `darkTheme`, personalizando
/// colores, estilos de texto, temas de componentes como `Card`, `Dialog`,
/// `Chip`, `AppBar`, etc.
///
/// También incluye constantes para padding, radios de borde y otros valores
/// de UI para mantener la consistencia en toda la aplicación.
library;
import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  // --- Constants ---
  static const double kVerticalPadding = 8.0;
  static const double kCardImageBorderRadius = 8.0;
  static const double kCardPadding = 12.0;
  static const EdgeInsets kListViewPadding = EdgeInsets.only(top: 8.0, bottom: 16.0);
  static const EdgeInsets kListViewPaddingWithFab = EdgeInsets.only(top: 8.0, bottom: 80.0);
  static const double kSearchInputFontSize = 14.0;
  static const double kSearchIconSize = 20.0;
  static const double kChipSpacing = 8.0;

  // --- Shared Theme Components ---
  static const _listTileTheme = ListTileThemeData(
    titleTextStyle: TextStyle(
      fontWeight: FontWeight.bold,
    ),
  );

  // --- Light Theme ---
  static ThemeData get lightTheme {
    final theme = ThemeData.light();
    return theme.copyWith(
      scaffoldBackgroundColor: Colors.grey[100],
      colorScheme: theme.colorScheme.copyWith(
        primary: Colors.blue,
        onPrimary: Colors.white,
        secondary: Colors.blueAccent,
        onSecondary: Colors.white,
      ),
      cardTheme: CardThemeData(
        elevation: 2.0,
        color: Colors.white,
        margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        elevation: 4.0,
        backgroundColor: Colors.white,
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
        contentTextStyle: const TextStyle(
          fontSize: 16,
          color: Colors.black54,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.grey[200],
        labelStyle: const TextStyle(
          color: Colors.black87,
          fontWeight: FontWeight.normal,
        ),
        selectedColor: Colors.blue,
        secondaryLabelStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
        showCheckmark: false,
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey[200],
        contentPadding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 12.0),
        hintStyle: TextStyle(color: Colors.grey[600]),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(color: Colors.blue, width: 2.0),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        prefixIconColor: Colors.grey[600],
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 2.0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      listTileTheme: _listTileTheme,
    );
  }

  // --- Dark Theme ---
  static ThemeData get darkTheme {
    final theme = ThemeData.dark();
    return theme.copyWith(
      scaffoldBackgroundColor: const Color(0xFF121212),
      colorScheme: theme.colorScheme.copyWith(
        primary: Colors.lightBlueAccent[200],
        onPrimary: Colors.black,
        secondary: Colors.tealAccent[200],
        onSecondary: Colors.black,
        surface: const Color(0xFF1E1E1E),
        onSurface: Colors.white,
      ),
      cardTheme: CardThemeData(
        elevation: 4.0,
        color: const Color(0xFF1E1E1E),
        margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        elevation: 8.0,
        backgroundColor: const Color(0xFF1E1E1E),
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        contentTextStyle: TextStyle(
          fontSize: 16,
          color: Colors.grey[300],
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.grey[800],
        labelStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.normal,
        ),
        selectedColor: Colors.lightBlueAccent[200],
        secondaryLabelStyle: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),
        showCheckmark: false,
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey[850],
        contentPadding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 12.0),
        hintStyle: TextStyle(color: Colors.grey[600]),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: Colors.grey[700]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: Colors.lightBlueAccent[200]!, width: 2.0),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: Colors.grey[700]!),
        ),
        prefixIconColor: Colors.grey[400],
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
        elevation: 2.0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      listTileTheme: _listTileTheme,
    );
  }
}
