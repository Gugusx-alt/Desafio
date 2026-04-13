import 'package:flutter/material.dart';
import 'package:feedbacks/login_screen.dart';
import 'package:feedbacks/pallet.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static TextStyle _ts(
    Color color,
    double size,
    FontWeight weight, {
    double? letterSpacing,
    double? height,
  }) {
    return TextStyle(
      color: color,
      fontSize: size,
      fontWeight: weight,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Feedbacks',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: backgroundColor,

        colorScheme: const ColorScheme.dark(
          primary: primaryColor,
          onPrimary: backgroundColor,
          secondary: primaryDim,
          surface: surfaceColor,
          onSurface: textPrimary,
          outline: borderColor,
          error: statusCancelled,
        ),

        textTheme: TextTheme(
          displayLarge:  _ts(textPrimary,   32, FontWeight.w700),
          displayMedium: _ts(textPrimary,   26, FontWeight.w600),
          headlineLarge: _ts(textPrimary,   22, FontWeight.w600),
          headlineMedium:_ts(textPrimary,   18, FontWeight.w500),
          titleLarge:    _ts(textPrimary,   16, FontWeight.w600),
          titleMedium:   _ts(textPrimary,   14, FontWeight.w500),
          bodyLarge:     _ts(textPrimary,   15, FontWeight.w400, height: 1.5),
          bodyMedium:    _ts(textSecondary, 13, FontWeight.w400, height: 1.5),
          bodySmall:     _ts(textMuted,     11, FontWeight.w400),
          labelLarge:    _ts(textPrimary,   14, FontWeight.w600, letterSpacing: 0.2),
          labelMedium:   _ts(textSecondary, 12, FontWeight.w500),
          labelSmall:    _ts(textMuted,     10, FontWeight.w400, letterSpacing: 0.3),
        ),

        appBarTheme: AppBarTheme(
          backgroundColor: surfaceColor,
          foregroundColor: textPrimary,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: _ts(textPrimary, 17, FontWeight.w600, letterSpacing: -0.2),
          iconTheme: const IconThemeData(color: textSecondary, size: 20),
          actionsIconTheme: const IconThemeData(color: textSecondary, size: 20),
          shape: const Border(bottom: BorderSide(color: borderColor, width: 1)),
        ),

        cardTheme: CardThemeData(
          color: surfaceColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusL),
            side: const BorderSide(color: borderColor),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        ),

        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surfaceElevated,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusM),
            borderSide: const BorderSide(color: borderColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusM),
            borderSide: const BorderSide(color: borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusM),
            borderSide: const BorderSide(color: primaryColor, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusM),
            borderSide: const BorderSide(color: statusCancelled),
          ),
          hintStyle: _ts(textMuted,      13, FontWeight.w400),
          labelStyle: _ts(textSecondary, 13, FontWeight.w400),
          floatingLabelStyle: _ts(primaryColor, 12, FontWeight.w500),
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: backgroundColor,
            elevation: 0,
            minimumSize: const Size.fromHeight(46),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radiusM),
            ),
            textStyle: _ts(backgroundColor, 14, FontWeight.w600, letterSpacing: 0.1),
          ),
        ),

        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: primaryColor,
            textStyle: _ts(primaryColor, 13, FontWeight.w500),
          ),
        ),

        chipTheme: ChipThemeData(
          backgroundColor: surfaceElevated,
          selectedColor: primarySurface,
          side: const BorderSide(color: borderColor),
          labelStyle: _ts(textSecondary, 12, FontWeight.w400),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusS),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        ),

        navigationRailTheme: const NavigationRailThemeData(
          backgroundColor: surfaceColor,
          selectedIconTheme: IconThemeData(color: primaryColor, size: 22),
          unselectedIconTheme: IconThemeData(color: textMuted, size: 22),
          selectedLabelTextStyle: TextStyle(
            color: primaryColor, fontSize: 11, fontWeight: FontWeight.w600,
          ),
          unselectedLabelTextStyle: TextStyle(color: textMuted, fontSize: 11),
          indicatorColor: primarySurface,
        ),

        dividerTheme: const DividerThemeData(
          color: borderColor,
          thickness: 1,
          space: 1,
        ),

        snackBarTheme: SnackBarThemeData(
          backgroundColor: surfaceElevated,
          contentTextStyle: _ts(textPrimary, 13, FontWeight.w400),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusM),
            side: const BorderSide(color: borderColor),
          ),
          behavior: SnackBarBehavior.floating,
        ),

        dialogTheme: DialogThemeData(
          backgroundColor: surfaceColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusL),
            side: const BorderSide(color: borderColor),
          ),
          titleTextStyle:   _ts(textPrimary,   17, FontWeight.w600),
          contentTextStyle: _ts(textSecondary, 13, FontWeight.w400, height: 1.5),
        ),

        tabBarTheme: const TabBarThemeData(
          labelColor: primaryColor,
          unselectedLabelColor: textMuted,
          indicatorColor: primaryColor,
          dividerColor: borderColor,
          indicatorSize: TabBarIndicatorSize.label,
        ),

        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}