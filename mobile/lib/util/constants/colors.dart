import 'package:flutter/material.dart';

class TColors {
  TColors._();

  // App basic Colors...
  static Color primary = Color.fromRGBO(252, 242, 219, 1);
  static Color secondary = Color.fromRGBO(248, 221, 160, 1);
  // static Color secondary = const Color.fromARGB(255, 254, 195, 112);
  static Color clickIcon = Colors.blue;
  static Color borderColor = Colors.blue;
  static Color icon = Color(0xff3a7bd5);
  // static Color accent = const Color(0xFFb0c7ff);
  // static Color accent = Colors.blue.shade50;
  static Color appBarPrimary =
      Color.fromRGBO(252, 242, 219, 1); // appBar primary color
  static Color appBarSecondary = Color.fromRGBO(248, 221, 160, 1);
  // static const Color borderColor = Color(0xFFE0E0E0);
  // static const Color primary = Color(0xFF1976D2);
  static const Color background = Color(0xFFF5F5F5);
  // static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color accent = Color(0xFF0288D1);

  // Gradient Colors...
  // static Gradient linearGradient = const LinearGradient(
  //   begin: Alignment(0.0, 0.0),
  //   end: Alignment(0.707, -0.707),
  //   colors: [
  //     Color(0xffff9a9e),
  //     Color(0xfffad0c4),
  //     Color(0xfffad0c4),
  //   ],
  // );

  // Text Colors...
  static Color headerText = Colors.blue.shade900;
  static Color textPrimary = const Color(0xFF333333);
  static Color textWhite = Colors.white;

  // Background Colors...
  static Color light = const Color(0xFFF6F6F6);
  static Color dark = const Color(0xFF272727);
  static Color primaryBackground = const Color(0xFFF3F5FF);

  // Background Container Colors
  static Color lightContainer = const Color(0xFFF6F6F6);
  static Color darkContainer = Colors.white.withOpacity(0.1);

  // Button Colors...
  static Color buttonPrimary =
      Color.fromRGBO(63, 112, 155, 1); // Button primary color
  static Color buttonHover = Color.fromRGBO(3, 148, 255, 1);
  static Color submitButton = Colors.green;
  static Color searchButton = buttonHover;
  static Color buttonSecondary = Colors.blue;
  static Color cancelButton = Colors.red;
  static Color buttonDisabled = const Color(0xFFC4C4C4);

  // Border Colors...
  static Color borderPrimary = const Color(0xFFD9D9D9);
  static Color borderSecondary = const Color(0xFFE6E6E6);

  // Error and Validation Colors...
  static Color submit = Colors.blue;
  static Color delete = Colors.red;
  static Color error = const Color(0xFFD32F2F);
  static Color success = const Color(0xFF388E3C);
  static Color warning = const Color(0xFFF57C00);
  static Color info = const Color(0xFF1976D2);

  // Neutral Shades...
  static Color black = const Color(0xFF232323);
  static Color darkerGrey = const Color(0xFF4F4F4F);
  static Color darkGrey = const Color(0xFF939393);
  static Color grey = const Color(0xFFE0E0E0);
  static Color softGrey = const Color(0xFFF4F4F4);
  static Color lightGrey = const Color(0xFFF9F9F9);
  static Color white = const Color(0xFFFFFFFF);
}
