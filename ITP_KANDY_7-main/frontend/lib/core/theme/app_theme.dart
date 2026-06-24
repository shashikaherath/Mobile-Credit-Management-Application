// ------------------------------------------------------------------------------
// File: app_theme.dart
// Purpose: Deterministic Design System and Visual Identity.
// Rationale: Orchestrates the global aesthetic of the ShopBook application 
//   using Material 3 guidelines. Centered on the Poppins typography system 
//   and the Emerald Green brand palette to ensure a premium, modern, 
//   and cohesive user experience across all modules.
// ------------------------------------------------------------------------------
import 'package:flutter/material.dart'; // Core Flutter UI toolkit
import 'package:google_fonts/google_fonts.dart'; // Dynamic font loading for Poppins
import 'package:frontend/core/theme/app_colors.dart'; // Brand color tokens

class AppTheme {
  /*
   * Logic: Aesthetic Framework Compilation.
   * Rationale: Compiles all brand design tokens (colors, typography, shapes) 
   *   into a unified ThemeData object. Ensures strict adherence to the 
   *   Material 3 specification for component behavior and layout metrics.
   */
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true, // Strategy: Use latest M3 specs for modern component behavior
      brightness: Brightness.light, // Visual Tone: High-clarity light mode base
      primaryColor: AppColors.primary, // Master: Primary brand color hook
      scaffoldBackgroundColor: AppColors.background, // Canvas: Consistent off-white background

      // --- Color System Mapping ---
      // Distributes brand colors across the Material color scheme slots.
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary, // Interaction: Main brand green
        secondary: AppColors.accentGreen, // Highlight: Vibrant teal secondary
        surface: AppColors.surface, // Container: Pure white for elevated surfaces
        error: AppColors.error, // Semantic: User-facing error signals
      ),

      // --- Typography System ---
      // Rationale: Poppins provides a geometric, friendly, and highly readable look.
      textTheme: GoogleFonts.poppinsTextTheme(), // Apply Poppins to all standard text roles

      // --- Navigation Bar Styling ---
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background, // Integrity: Seamless merge with scaffold
        foregroundColor: AppColors.textDark, // Contrast: Dark icons on light background
        elevation: 0, // Aesthetic: Flat design for modern minimal look
        centerTitle: false, // UX: Left-aligned titles for native feel
        titleSpacing: 24, // Layout: Standard side margin for titles
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20, // Hierarchy: Clear primary screen headline
          fontWeight: FontWeight.w700, // Emphasis: Bold weight for focus
          color: AppColors.textDark, // Consistency: Always use deep slate
          letterSpacing: -0.5, // Polish: Tighter tracking for premium feel
        ),
      ),

      // --- Component: Primary Elevated Button ---
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary, // Action: Strong brand color fill
          foregroundColor: Colors.white, // Legibility: Crisp white text
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16), // Shape: Modern rounded corner profile
          ),
          elevation: 0, // Aesthetic: Shadow-less flat buttons
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24), // Tap Target: Ergonomic sizing
          textStyle: GoogleFonts.poppins(
            fontSize: 16, // Size: Clear call-to-action text
            fontWeight: FontWeight.w600, // Emphasis: Semi-bold for importance
          ),
        ),
      ),

      // --- Component: Secondary Outlined Button ---
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary, // Interaction: Brand identity border/text
          side: const BorderSide(color: AppColors.primary, width: 1.5), // Spec: Clear boundary
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16), // Alignment: Matches primary button
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24), // Uniformity: Standard action size
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // --- Component: Tertiary Text Button ---
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary, // Focus: Subtle interaction color
          textStyle: GoogleFonts.poppins(
            fontSize: 14, // Secondary: Smaller for lower hierarchy actions
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // --- Layout: Unified Input Field Styling ---
      inputDecorationTheme: InputDecorationTheme(
        filled: true, // Polish: Subtle fill for better field definition
        fillColor: AppColors.surface, // Clarity: High-contrast entry area
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16), // Shape: Rounded input style
          borderSide: const BorderSide(color: AppColors.divider), // Default: Subtle border
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16), // State: Unfocused neutral boundary
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16), // State: Active interaction signal
          borderSide: const BorderSide(color: AppColors.primary, width: 2), // Focus: Double width green
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20, // Spacing: Proper inner text breathing room
          vertical: 18,
        ),
        hintStyle: GoogleFonts.poppins(color: AppColors.textLight), // Guidance: Light placeholder text
        labelStyle: GoogleFonts.poppins(color: AppColors.textMedium), // Label: Readable slate secondary
      ),

      // --- Layout: Global Card System ---
      cardTheme: CardThemeData(
        color: AppColors.surface, // Container: Material surface color
        elevation: 0, // Aesthetic: Modern shadow-less cards
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20), // Character: Friendlier wide radius
          side: const BorderSide(color: AppColors.divider, width: 1), // Polish: One-pixel soft boundary
        ),
        margin: EdgeInsets.zero, // Control: Developer-controlled margins per screen
      ),

      // --- Component: Date Picker Style ---
      datePickerTheme: const DatePickerThemeData(
        dividerColor: Colors.transparent, // Polish: Remove the unsightly black line for a cleaner, modern look.
      ),
    );
  }
}

