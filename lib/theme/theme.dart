import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Define common colors based on your specifications
  static const Color primaryColor = Color(0xFF99CF70); // Green color you requested
  static const Color primaryDarkColor = Color(0xFF85B762); // Slightly darker shade for hover/press states
  static const Color accentColor = Color(0xFFBBE3A3); // Lighter variant for accents
  static const Color errorColor = Color(0xFFE53935); // Keeping the red for errors
  
  // Light theme colors
  static const Color _lightTextPrimaryColor = Color(0xFF161616); // Dark text in light mode
  static const Color _lightTextSecondaryColor = Color(0xFF555555); // Secondary text in light mode
  static const Color _lightBackgroundColor = Color(0xFFE2E7E0); // Light background you requested
  static const Color _lightCardColor = Colors.white;
  static const Color _lightDividerColor = Color(0xFFDDDDDD);
  
  // Dark theme colors
  static const Color _darkTextPrimaryColor = Color(0xFFE2E7E0); // Light text in dark mode
  static const Color _darkTextSecondaryColor = Color(0xFFAAAAAA); // Secondary text in dark mode
  static const Color _darkBackgroundColor = Color(0xFF161616); // Dark background you requested
  static const Color _darkCardColor = Color(0xFF212121); // Slightly lighter than background for cards
  static const Color _darkDividerColor = Color(0xFF424242);

  // Define text themes
  static TextTheme _buildTextTheme(TextTheme base, Color textColor, Color secondaryTextColor) {
    return base.copyWith(
      // Headings - Using Outfit font
      displayLarge: GoogleFonts.outfit(
        textStyle: base.displayLarge?.copyWith(color: textColor),
        fontSize: 32,
        fontWeight: FontWeight.bold,
      ),
      displayMedium: GoogleFonts.outfit(
        textStyle: base.displayMedium?.copyWith(color: textColor),
        fontSize: 28,
        fontWeight: FontWeight.bold,
      ),
      displaySmall: GoogleFonts.outfit(
        textStyle: base.displaySmall?.copyWith(color: textColor),
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
      headlineLarge: GoogleFonts.outfit(
        textStyle: base.headlineLarge?.copyWith(color: textColor),
        fontSize: 24,
        fontWeight: FontWeight.w700,
      ),
      headlineMedium: GoogleFonts.outfit(
        textStyle: base.headlineMedium?.copyWith(color: textColor),
        fontSize: 22,
        fontWeight: FontWeight.w600,
      ),
      headlineSmall: GoogleFonts.outfit(
        textStyle: base.headlineSmall?.copyWith(color: textColor),
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: GoogleFonts.outfit(
        textStyle: base.titleLarge?.copyWith(color: textColor),
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: GoogleFonts.outfit(
        textStyle: base.titleMedium?.copyWith(color: textColor),
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      titleSmall: GoogleFonts.outfit(
        textStyle: base.titleSmall?.copyWith(color: textColor),
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),

      // Body - Using Inter font
      bodyLarge: GoogleFonts.inter(
        textStyle: base.bodyLarge?.copyWith(color: textColor),
        fontSize: 16,
        fontWeight: FontWeight.normal,
      ),
      bodyMedium: GoogleFonts.inter(
        textStyle: base.bodyMedium?.copyWith(color: textColor),
        fontSize: 14,
        fontWeight: FontWeight.normal,
      ),
      bodySmall: GoogleFonts.inter(
        textStyle: base.bodySmall?.copyWith(color: secondaryTextColor),
        fontSize: 12,
        fontWeight: FontWeight.normal,
      ),
      labelLarge: GoogleFonts.inter(
        textStyle: base.labelLarge?.copyWith(color: textColor),
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      labelMedium: GoogleFonts.inter(
        textStyle: base.labelMedium?.copyWith(color: textColor),
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      labelSmall: GoogleFonts.inter(
        textStyle: base.labelSmall?.copyWith(color: secondaryTextColor),
        fontSize: 10,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  // Light theme
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.light(
      primary: primaryColor,
      secondary: accentColor,
      error: errorColor,
      onPrimary: Colors.white,
      onSecondary: _lightTextPrimaryColor,
      onError: Colors.white,
      background: _lightBackgroundColor,
      onBackground: _lightTextPrimaryColor,
      surface: _lightCardColor,
      onSurface: _lightTextPrimaryColor,
    ),
    scaffoldBackgroundColor: _lightBackgroundColor,
    cardColor: _lightCardColor,
    dividerColor: _lightDividerColor,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: _lightTextPrimaryColor,
      elevation: 0,
      centerTitle: true,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      iconTheme: IconThemeData(color: _lightTextPrimaryColor),
      titleTextStyle: GoogleFonts.outfit(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: _lightTextPrimaryColor,
      ),
    ),
    iconTheme: IconThemeData(
      color: _lightTextSecondaryColor,
    ),
    textTheme: _buildTextTheme(
      ThemeData.light().textTheme,
      _lightTextPrimaryColor,
      _lightTextSecondaryColor,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: primaryColor,
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: GoogleFonts.inter(
          fontWeight: FontWeight.w500,
          fontSize: 16,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        textStyle: GoogleFonts.inter(
          fontWeight: FontWeight.w500,
          fontSize: 16,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        side: const BorderSide(color: primaryColor, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: GoogleFonts.inter(
          fontWeight: FontWeight.w500,
          fontSize: 16,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _lightDividerColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _lightDividerColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: errorColor, width: 1),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      hintStyle: GoogleFonts.inter(
        color: _lightTextSecondaryColor,
        fontSize: 14,
      ),
      labelStyle: GoogleFonts.inter(
        color: _lightTextSecondaryColor,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Colors.grey[200],
      disabledColor: Colors.grey[300],
      selectedColor: primaryColor.withOpacity(0.2),
      secondarySelectedColor: primaryColor.withOpacity(0.2),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      labelStyle: GoogleFonts.inter(
        fontSize: 14,
        color: _lightTextPrimaryColor,
      ),
      secondaryLabelStyle: GoogleFonts.inter(
        fontSize: 14,
        color: primaryColor,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    bottomAppBarTheme: const BottomAppBarTheme(
      color: Colors.white,
      elevation: 8,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 6,
      shape: const CircleBorder(),
    ),
  );

  // Dark theme
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.dark(
      primary: primaryColor,
      secondary: accentColor,
      error: errorColor,
      onPrimary: _lightTextPrimaryColor, // Dark text on primary buttons 
      onSecondary: _lightTextPrimaryColor,
      onError: _lightTextPrimaryColor,
      background: _darkBackgroundColor,
      onBackground: _darkTextPrimaryColor,
      surface: _darkCardColor,
      onSurface: _darkTextPrimaryColor,
    ),
    scaffoldBackgroundColor: _darkBackgroundColor,
    cardColor: _darkCardColor,
    dividerColor: _darkDividerColor,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: _darkTextPrimaryColor,
      elevation: 0,
      centerTitle: true,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      iconTheme: IconThemeData(color: _darkTextPrimaryColor),
      titleTextStyle: GoogleFonts.outfit(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: _darkTextPrimaryColor,
      ),
    ),
    iconTheme: IconThemeData(
      color: _darkTextSecondaryColor,
    ),
    textTheme: _buildTextTheme(
      ThemeData.dark().textTheme,
      _darkTextPrimaryColor,
      _darkTextSecondaryColor,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: _lightTextPrimaryColor, // Dark text on light buttons
        backgroundColor: primaryColor,
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: GoogleFonts.inter(
          fontWeight: FontWeight.w500,
          fontSize: 16,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: accentColor,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        textStyle: GoogleFonts.inter(
          fontWeight: FontWeight.w500,
          fontSize: 16,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: accentColor,
        side: BorderSide(color: accentColor, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: GoogleFonts.inter(
          fontWeight: FontWeight.w500,
          fontSize: 16,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Color(0xFF2A2A2A),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: _darkDividerColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: _darkDividerColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: accentColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: errorColor, width: 1),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      hintStyle: GoogleFonts.inter(
        color: _darkTextSecondaryColor,
        fontSize: 14,
      ),
      labelStyle: GoogleFonts.inter(
        color: _darkTextSecondaryColor,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Colors.grey[800],
      disabledColor: Colors.grey[700],
      selectedColor: primaryColor.withOpacity(0.3),
      secondarySelectedColor: primaryColor.withOpacity(0.3),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      labelStyle: GoogleFonts.inter(
        fontSize: 14,
        color: _darkTextPrimaryColor,
      ),
      secondaryLabelStyle: GoogleFonts.inter(
        fontSize: 14,
        color: accentColor,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    bottomAppBarTheme: BottomAppBarTheme(
      color: _darkCardColor,
      elevation: 8,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: primaryColor,
      foregroundColor: _lightTextPrimaryColor, // Dark text on primary color
      elevation: 6,
      shape: const CircleBorder(),
    ),
  );
}

class ThemeNotifier extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }
}