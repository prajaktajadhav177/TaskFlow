import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Colors
  static const Color primary = Color(0xFF6C63FF);
  static const Color primaryDark = Color(0xFF4A42CC);
  static const Color secondary = Color(0xFF00D2FF);
  static const Color accent = Color(0xFFFF6B6B);
  static const Color success = Color(0xFF06D6A0);
  static const Color warning = Color(0xFFFFD166);
  static const Color error = Color(0xFFEF476F);

  static const Color bgDark = Color(0xFF0D0D1A);
  static const Color bgCard = Color(0xFF1A1A2E);
  static const Color bgCardLight = Color(0xFF16213E);
  static const Color surface = Color(0xFF0F3460);

  static const Color textPrimary = Color(0xFFF0F0FF);
  static const Color textSecondary = Color(0xFF8B8BA7);
  static const Color textMuted = Color(0xFF4A4A6A);

  static const Color divider = Color(0xFF1E1E3A);

  // Task Status Colors
  static const Color statusTodo = Color(0xFF8B8BA7);
  static const Color statusInProgress = Color(0xFF6C63FF);
  static const Color statusReview = Color(0xFFFFD166);
  static const Color statusDone = Color(0xFF06D6A0);
  static const Color statusOverdue = Color(0xFFEF476F);

  // Priority Colors
  static const Color priorityLow = Color(0xFF06D6A0);
  static const Color priorityMedium = Color(0xFFFFD166);
  static const Color priorityHigh = Color(0xFFFF6B6B);
  static const Color priorityCritical = Color(0xFFEF476F);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgDark,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: secondary,
        surface: bgCard,
        error: error,
      ),
      textTheme: GoogleFonts.spaceGroteskTextTheme(
        ThemeData.dark().textTheme,
      ).copyWith(
        displayLarge: GoogleFonts.syne(
          color: textPrimary,
          fontSize: 32,
          fontWeight: FontWeight.w800,
        ),
        displayMedium: GoogleFonts.syne(
          color: textPrimary,
          fontSize: 26,
          fontWeight: FontWeight.w700,
        ),
        headlineLarge: GoogleFonts.syne(
          color: textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
        headlineMedium: GoogleFonts.syne(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: GoogleFonts.spaceGrotesk(
          color: textPrimary,
          fontSize: 16,
        ),
        bodyMedium: GoogleFonts.spaceGrotesk(
          color: textSecondary,
          fontSize: 14,
        ),
        labelLarge: GoogleFonts.spaceGrotesk(
          color: textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bgDark,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.syne(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: const IconThemeData(color: textPrimary),
      ),
      cardTheme: CardThemeData(
        color: bgCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: divider, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.spaceGrotesk(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: bgCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: error),
        ),
        labelStyle: const TextStyle(color: textSecondary),
        hintStyle: const TextStyle(color: textMuted),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: bgCardLight,
        selectedColor: primary.withOpacity(0.3),
        labelStyle: GoogleFonts.spaceGrotesk(
          color: textSecondary,
          fontSize: 12,
        ),
        side: const BorderSide(color: divider),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: bgCard,
        selectedItemColor: primary,
        unselectedItemColor: textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      dividerTheme: const DividerThemeData(
        color: divider,
        thickness: 1,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}

class AppConstants {
  static const String appName = 'TaskFlow';

  // Firestore Collections
  static const String usersCollection = 'users';
  static const String projectsCollection = 'projects';
  static const String tasksCollection = 'tasks';
  static const String commentsCollection = 'comments';
  static const String notificationsCollection = 'notifications';

  // Roles
  static const String roleAdmin = 'admin';
  static const String roleMember = 'member';

  // Task Status
  static const String statusTodo = 'todo';
  static const String statusInProgress = 'in_progress';
  static const String statusReview = 'review';
  static const String statusDone = 'done';

  // Priority
  static const String priorityLow = 'low';
  static const String priorityMedium = 'medium';
  static const String priorityHigh = 'high';
  static const String priorityCritical = 'critical';
}