import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Heading text styles using Outfit font
  static TextStyle headingLarge = GoogleFonts.outfit(
    fontSize: 24.0,
    fontWeight: FontWeight.bold,
  );
  
  static TextStyle headingMedium = GoogleFonts.outfit(
    fontSize: 20.0,
    fontWeight: FontWeight.w600,
  );
  
  static TextStyle headingSmall = GoogleFonts.outfit(
    fontSize: 18.0,
    fontWeight: FontWeight.w500,
  );
  
  // Body text styles using Inter font
  static TextStyle bodyLarge = GoogleFonts.inter(
    fontSize: 16.0,
    fontWeight: FontWeight.normal,
  );
  
  static TextStyle bodyMedium = GoogleFonts.inter(
    fontSize: 14.0,
    fontWeight: FontWeight.normal,
  );
  
  static TextStyle bodySmall = GoogleFonts.inter(
    fontSize: 12.0,
    fontWeight: FontWeight.normal,
  );
  
  // Create a ThemeData that uses these text styles
  static ThemeData theme() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 136, 255, 249)),
      useMaterial3: true,
      textTheme: TextTheme(
        // Headings
        headlineLarge: headingLarge,
        headlineMedium: headingMedium,
        headlineSmall: headingSmall,
        titleLarge: headingMedium,
        
        // Body text
        bodyLarge: bodyLarge,
        bodyMedium: bodyMedium,
        bodySmall: bodySmall,
      ),
    );
  }
}