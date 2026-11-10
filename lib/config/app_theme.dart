import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mercyocean/config/app_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --------------------------------------------------
//  COLOR TOKENS
// --------------------------------------------------

class AppColors {
  AppColors._();

  // — Gold Accent (shared) ———————
  static const Color gold = Color(0xFFC9A247);
  static const Color goldLight = Color(0xFFD4AF5A);
  static const Color goldDark = Color(0xFFAA8830);
  static const Color goldSurface = Color(0xFFF5E6C0);

  // — Light Mode ———————
  static const Color lightBackground = Color(0xFFF5EFE4);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightNavBar = Color(0xFFFFFFFF);
  static const Color lightText = Color(0xFF2C2416);
  static const Color lightSubText = Color(0xFF6B5C3E);
  static const Color lightDivider = Color(0xFFE0D4BC);
  static const Color lightIconInactive = Color(0xFF9E8C6E);

  // ── Dark Mode ────────────────────────────────
  static const Color darkBackground = Color(0xFF080C14);
  static const Color darkSurface = Color(0xFF0F1420);
  static const Color darkNavBar = Color(0xFF0A0E18);
  static const Color darkText = Color(0xFFF0E6CC);
  static const Color darkSubText = Color(0xFFAA9870);
  static const Color darkDivider = Color(0xFF1E2535);
  static const Color darkIconInactive = Color(0xFF5A6070);

  // ── Light Mode Card Palette ───────────────────
  // Each card has a gradient pair [base, highlight]
  static const List<List<Color>> lightCardGradients = [
    [Color(0xFFE8D5A8), Color(0xFFF2E8C4)], // Golden Chain  – warm sand
    [Color(0xFFAACFC8), Color(0xFFC4E0DA)], // Weekly Dhikr  – sage teal
    [Color(0xFFC8B8DC), Color(0xFFDACEED)], // Salat         – soft lavender
    [Color(0xFFB8CCE0), Color(0xFFCCDCEE)], // Dalail        – powder blue
    [Color(0xFFB8C8B0), Color(0xFFCCDAC4)], // Daily Awrad   – sage green
    [Color(0xFFB8C0D0), Color(0xFFCCD0E0)], // Monthly Awrad – steel blue
    [Color(0xFFE8C8A0), Color(0xFFF2DABC)], // Quran         – warm peach
    [Color(0xFFC8B8D8), Color(0xFFDACAE8)], // Books         – mauve
    [Color(0xFFC0BAD8), Color(0xFFD2CCEC)], // Qiblah        – periwinkle
    [Color(0xFFE8B8B0), Color(0xFFF2CCC6)], // Nasheeds      – dusty rose
    [Color(0xFFE8C8A8), Color(0xFFF2DAC0)], // Duas          – warm ivory
  ];

  // ── Dark Mode Card Palette ────────────────────
  static const List<List<Color>> darkCardGradients = [
    [Color(0xFF2E1E0E), Color(0xFF3E2A14)], // Golden Chain  – dark amber
    [Color(0xFF0C2820), Color(0xFF14382C)], // Weekly Dhikr  – dark teal
    [Color(0xFF1E1430), Color(0xFF281A40)], // Salat         – dark indigo
    [Color(0xFF0E1E30), Color(0xFF142840)], // Dalail        – dark navy
    [Color(0xFF0C1E24), Color(0xFF122832)], // Daily Awrad   – dark slate
    [Color(0xFF121828), Color(0xFF182034)], // Monthly Awrad – dark blue-grey
    [Color(0xFF201408), Color(0xFF2C1C0C)], // Quran         – dark brown
    [Color(0xFF141028), Color(0xFF1C1636)], // Books         – dark purple
    [Color(0xFF081E18), Color(0xFF0E2820)], // Qiblah        – dark forest
    [Color(0xFF200808), Color(0xFF2C1010)], // Nasheeds      – dark maroon
    [Color(0xFF0A1A14), Color(0xFF12241E)], // Duas          – dark emerald
  ];

  // ── Icon Colors on Cards ──────────────────────
  static const List<Color> lightCardIconColors = [
    Color(0xFF5A4020), // sand card
    Color(0xFF1E5048), // teal card
    Color(0xFF4A3060), // lavender card
    Color(0xFF2A4060), // blue card
    Color(0xFF304828), // green card
    Color(0xFF2E3A50), // steel card
    Color(0xFF5A3810), // peach card
    Color(0xFF402850), // mauve card
    Color(0xFF383060), // periwinkle card
    Color(0xFF5A2820), // rose card
    Color(0xFF5A3820), // ivory card
  ];

  static const List<Color> darkCardIconColors = [
    Color(0xFFC9A247), // gold on all dark cards
    Color(0xFF8ECAB8),
    Color(0xFFAA90D0),
    Color(0xFF7AAAC8),
    Color(0xFF80B898),
    Color(0xFF8898B8),
    Color(0xFFC9A247),
    Color(0xFF9880C8),
    Color(0xFF70C0A8),
    Color(0xFFC88888),
    Color(0xFF80C0A0),
  ];
}

// ─────────────────────────────────────────────
//  TEXT STYLES
// ─────────────────────────────────────────────

class AppTextStyles {
  AppTextStyles._();

  static const String _primaryFont = 'Poppins';
  static const String _secondaryFont = 'Nunito'; // Clean rounded sans-serif

  static TextTheme lightTextTheme = TextTheme(
    displayLarge: TextStyle(
      fontFamily: _primaryFont,
      fontSize: 32,
      fontWeight: FontWeight.w700,
      color: AppColors.lightText,
      letterSpacing: -0.5,
    ),
    displayMedium: TextStyle(
      fontFamily: _primaryFont,
      fontSize: 26,
      fontWeight: FontWeight.w600,
      color: AppColors.lightText,
    ),
    titleLarge: TextStyle(
      fontFamily: _secondaryFont,
      fontSize: 18,
      fontWeight: FontWeight.w700,
      color: AppColors.lightText,
      letterSpacing: 0.2,
    ),
    titleMedium: TextStyle(
      fontFamily: _secondaryFont,
      fontSize: 15,
      fontWeight: FontWeight.w600,
      color: AppColors.lightText,
    ),
    titleSmall: TextStyle(
      fontFamily: _secondaryFont,
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: AppColors.lightText,
    ),
    bodyLarge: TextStyle(
      fontFamily: _secondaryFont,
      fontSize: 15,
      fontWeight: FontWeight.w400,
      color: AppColors.lightText,
      height: 1.6,
    ),
    bodyMedium: TextStyle(
      fontFamily: _secondaryFont,
      fontSize: 13,
      fontWeight: FontWeight.w400,
      color: AppColors.lightSubText,
      height: 1.5,
    ),
    labelLarge: TextStyle(
      fontFamily: _secondaryFont,
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: AppColors.lightText,
      letterSpacing: 0.3,
    ),
    labelSmall: TextStyle(
      fontFamily: _secondaryFont,
      fontSize: 10,
      fontWeight: FontWeight.w500,
      color: AppColors.lightSubText,
      letterSpacing: 0.4,
    ),
  );

  static TextTheme darkTextTheme = TextTheme(
    displayLarge: TextStyle(
      fontFamily: _primaryFont,
      fontSize: 32,
      fontWeight: FontWeight.w700,
      color: AppColors.darkText,
      letterSpacing: -0.5,
    ),
    displayMedium: TextStyle(
      fontFamily: _primaryFont,
      fontSize: 26,
      fontWeight: FontWeight.w600,
      color: AppColors.darkText,
    ),
    titleLarge: TextStyle(
      fontFamily: _secondaryFont,
      fontSize: 18,
      fontWeight: FontWeight.w700,
      color: AppColors.darkText,
      letterSpacing: 0.2,
    ),
    titleMedium: TextStyle(
      fontFamily: _secondaryFont,
      fontSize: 15,
      fontWeight: FontWeight.w600,
      color: AppColors.darkText,
    ),
    titleSmall: TextStyle(
      fontFamily: _secondaryFont,
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: AppColors.darkText,
    ),
    bodyLarge: TextStyle(
      fontFamily: _secondaryFont,
      fontSize: 15,
      fontWeight: FontWeight.w400,
      color: AppColors.darkText,
      height: 1.6,
    ),
    bodyMedium: TextStyle(
      fontFamily: _secondaryFont,
      fontSize: 13,
      fontWeight: FontWeight.w400,
      color: AppColors.darkSubText,
      height: 1.5,
    ),
    labelLarge: TextStyle(
      fontFamily: _secondaryFont,
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: AppColors.darkText,
      letterSpacing: 0.3,
    ),
    labelSmall: TextStyle(
      fontFamily: _secondaryFont,
      fontSize: 10,
      fontWeight: FontWeight.w500,
      color: AppColors.darkSubText,
      letterSpacing: 0.4,
    ),
  );
}

void toggleTheme() async {
  final prefs = await SharedPreferences.getInstance();
  if (themeNotifier.value == ThemeMode.dark) {
    themeNotifier.value = ThemeMode.light;
    await prefs.setBool('isDarkMode', false);
  } else {
    themeNotifier.value = ThemeMode.dark;
    await prefs.setBool('isDarkMode', true);
  }
}


bool get isDarkMode => themeNotifier.value == ThemeMode.dark;

// ─────────────────────────────────────────────
//  MAIN THEME CLASS
// ─────────────────────────────────────────────

class AppTheme {
  AppTheme._();

  // ── Shared Shape / Radius ─────────────────────
  static const double cardRadius = 18.0;
  static const double buttonRadius = 14.0;
  static const double bottomNavRadius = 24.0;
  static const double fabRadius = 36.0;

  // ─────────────────────────────────────────────
  //  LIGHT THEME
  // ─────────────────────────────────────────────
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    fontFamily: 'Poppins',
    // ── Color Scheme ──────────────────────────
    colorScheme: const ColorScheme.light(
      primary: AppColors.gold,
      onPrimary: Colors.white,
      primaryContainer: AppColors.goldSurface,
      onPrimaryContainer: AppColors.lightText,
      secondary: AppColors.goldLight,
      onSecondary: Colors.white,
      surface: AppColors.lightSurface,
      onSurface: AppColors.lightText,
      surfaceContainerHighest: Color(0xFFEDE5D4),
      outline: AppColors.lightDivider,
      outlineVariant: Color(0xFFD4C8B0),
      error: Color(0xFFB00020),
    ),

    scaffoldBackgroundColor: AppColors.lightBackground,
    canvasColor: AppColors.lightBackground,

    // ── Typography ────────────────────────────
    textTheme: AppTextStyles.lightTextTheme,
    primaryTextTheme: AppTextStyles.lightTextTheme,

    // ── AppBar ───────────────────────────────
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.lightBackground,
      foregroundColor: AppColors.lightText,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: AppColors.lightText,
      ),
      iconTheme: IconThemeData(color: AppColors.lightText, size: 22),
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    ),

    // ── Bottom Navigation Bar ─────────────────
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.lightNavBar,
      selectedItemColor: AppColors.gold,
      unselectedItemColor: AppColors.lightIconInactive,
      elevation: 12,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: TextStyle(
        fontFamily: 'Nunito',
        fontSize: 10,
        fontWeight: FontWeight.w700,
      ),
      unselectedLabelStyle: TextStyle(
        fontFamily: 'Nunito',
        fontSize: 10,
        fontWeight: FontWeight.w500,
      ),
    ),

    // ── Navigation Bar (Material 3) ───────────
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.lightNavBar,
      indicatorColor: AppColors.goldSurface,
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: AppColors.gold, size: 22);
        }
        return const IconThemeData(
          color: AppColors.lightIconInactive,
          size: 22,
        );
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const TextStyle(
            fontFamily: 'Nunito',
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppColors.gold,
          );
        }
        return const TextStyle(
          fontFamily: 'Nunito',
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: AppColors.lightIconInactive,
        );
      }),
      elevation: 10,
      shadowColor: Color(0x33000000),
    ),

    // ── Card ─────────────────────────────────
    cardTheme: CardThemeData(
      color: AppColors.lightSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(cardRadius),
      ),
      margin: const EdgeInsets.all(0),
    ),

    // ── Icon ─────────────────────────────────
    iconTheme: const IconThemeData(color: AppColors.lightText, size: 22),

    // ── FloatingActionButton ─────────────────
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColors.gold,
      foregroundColor: Colors.white,
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(fabRadius),
      ),
    ),

    // ── Elevated Button ───────────────────────
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.gold,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(buttonRadius),
        ),
        textStyle: const TextStyle(
          fontFamily: 'Nunito',
          fontSize: 14,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    ),

    // ── Text Button ───────────────────────────
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.gold,
        textStyle: const TextStyle(
          fontFamily: 'Nunito',
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    // ── Input Decoration ──────────────────────
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFEDE5D4),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.gold, width: 1.5),
      ),
      hintStyle: const TextStyle(
        fontFamily: 'Nunito',
        fontSize: 14,
        color: AppColors.lightSubText,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),

    // ── Divider ───────────────────────────────
    dividerTheme: const DividerThemeData(
      color: AppColors.lightDivider,
      thickness: 1,
      space: 1,
    ),

    // ── List Tile ─────────────────────────────
    listTileTheme: const ListTileThemeData(
      iconColor: AppColors.lightSubText,
      textColor: AppColors.lightText,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    ),

    // ── Chip ─────────────────────────────────
    chipTheme: ChipThemeData(
      backgroundColor: const Color(0xFFEDE5D4),
      selectedColor: AppColors.goldSurface,
      labelStyle: const TextStyle(
        fontFamily: 'Nunito',
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.lightText,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    ),

    // ── Dialog ───────────────────────────────
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.lightSurface,
      elevation: 16,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titleTextStyle: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: AppColors.lightText,
      ),
    ),

    // ── Switch ───────────────────────────────
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return AppColors.gold;
        return Colors.white;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return AppColors.goldSurface;
        return AppColors.lightDivider;
      }),
    ),

    // ── Progress Indicator ────────────────────
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.gold,
      linearTrackColor: AppColors.goldSurface,
    ),
  );

  // ─────────────────────────────────────────────
  //  DARK THEME
  // ─────────────────────────────────────────────
  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,

    // ── Color Scheme ──────────────────────────
    colorScheme: const ColorScheme.dark(
      primary: AppColors.gold,
      onPrimary: AppColors.darkBackground,
      primaryContainer: Color(0xFF2A1E08),
      onPrimaryContainer: AppColors.gold,
      secondary: AppColors.goldLight,
      onSecondary: AppColors.darkBackground,
      surface: AppColors.darkSurface,
      onSurface: AppColors.darkText,
      surfaceContainerHighest: Color(0xFF141A28),
      outline: AppColors.darkDivider,
      outlineVariant: Color(0xFF1A2030),
      error: Color(0xFFCF6679),
    ),

    scaffoldBackgroundColor: AppColors.darkBackground,
    canvasColor: AppColors.darkBackground,

    // ── Typography ────────────────────────────
    textTheme: AppTextStyles.darkTextTheme,
    primaryTextTheme: AppTextStyles.darkTextTheme,

    // ── AppBar ───────────────────────────────
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.darkBackground,
      foregroundColor: AppColors.darkText,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: AppColors.darkText,
      ),
      iconTheme: IconThemeData(color: AppColors.darkText, size: 22),
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    ),

    // ── Bottom Navigation Bar ─────────────────
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.darkNavBar,
      selectedItemColor: AppColors.gold,
      unselectedItemColor: AppColors.darkIconInactive,
      elevation: 20,
      type: BottomNavigationBarType.shifting,
      selectedLabelStyle: TextStyle(
        fontFamily: 'Nunito',
        fontSize: 15,
        fontWeight: FontWeight.w700,
      ),
      unselectedLabelStyle: TextStyle(
        fontFamily: 'Nunito',
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
    ),

    // ── Navigation Bar (Material 3) ───────────
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.darkNavBar,
      indicatorColor: const Color(0xFF2A1E08),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: AppColors.gold, size: 22);
        }
        return const IconThemeData(color: AppColors.darkIconInactive, size: 22);
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const TextStyle(
            fontFamily: 'Nunito',
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppColors.gold,
          );
        }
        return const TextStyle(
          fontFamily: 'Nunito',
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: AppColors.darkIconInactive,
        );
      }),
      elevation: 10,
      shadowColor: Colors.black54,
    ),

    // ── Card ─────────────────────────────────
    cardTheme: CardThemeData(
      color: AppColors.darkSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(cardRadius),
      ),
      margin: const EdgeInsets.all(0),
    ),

    // ── Icon ─────────────────────────────────
    iconTheme: const IconThemeData(color: AppColors.darkText, size: 22),

    // ── FloatingActionButton ─────────────────
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColors.gold,
      foregroundColor: AppColors.darkBackground,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(fabRadius),
      ),
    ),

    // ── Elevated Button ───────────────────────
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.gold,
        foregroundColor: AppColors.darkBackground,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(buttonRadius),
        ),
        textStyle: const TextStyle(
          fontFamily: 'Nunito',
          fontSize: 14,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    ),

    // ── Text Button ───────────────────────────
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.gold,
        textStyle: const TextStyle(
          fontFamily: 'Nunito',
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    // ── Input Decoration ──────────────────────
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF141A28),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.gold, width: 1.5),
      ),
      hintStyle: const TextStyle(
        fontFamily: 'Nunito',
        fontSize: 14,
        color: AppColors.darkSubText,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),

    // ── Divider ───────────────────────────────
    dividerTheme: const DividerThemeData(
      color: AppColors.darkDivider,
      thickness: 1,
      space: 1,
    ),

    // ── List Tile ─────────────────────────────
    listTileTheme: const ListTileThemeData(
      iconColor: AppColors.darkSubText,
      textColor: AppColors.darkText,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    ),

    // ── Chip ─────────────────────────────────
    chipTheme: ChipThemeData(
      backgroundColor: const Color(0xFF141A28),
      selectedColor: const Color(0xFF2A1E08),
      labelStyle: const TextStyle(
        fontFamily: 'Nunito',
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.darkText,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    ),

    // ── Dialog ───────────────────────────────
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.darkSurface,
      elevation: 20,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titleTextStyle: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: AppColors.darkText,
      ),
    ),

    // ── Switch ───────────────────────────────
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return AppColors.gold;
        return AppColors.darkIconInactive;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const Color(0xFF2A1E08);
        }
        return AppColors.darkDivider;
      }),
    ),

    // ── Progress Indicator ────────────────────
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.gold,
      linearTrackColor: Color(0xFF2A1E08),
    ),
  );
}

// ─────────────────────────────────────────────
//  GRADIENT HELPERS
// ─────────────────────────────────────────────

class AppGradients {
  AppGradients._();

  /// Gold shimmer gradient for FAB / logo / premium accents
  static const LinearGradient goldShimmer = LinearGradient(
    colors: [Color(0xFFD4AF5A), Color(0xFFC9A247), Color(0xFFAA8830)],
    stops: [0.0, 0.5, 1.0],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Returns a card gradient by index for light or dark mode
  static LinearGradient cardGradient({
    required int index,
    required bool isDark,
  }) {
    final gradients = isDark
        ? AppColors.darkCardGradients
        : AppColors.lightCardGradients;

    final safeIndex = index % gradients.length;
    return LinearGradient(
      colors: gradients[safeIndex],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  /// Light background parchment gradient
  static const LinearGradient lightBackground = LinearGradient(
    colors: [Color(0xFFF8F2E6), Color(0xFFF0E8D4)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  /// Dark background deep-space gradient
  static const LinearGradient darkBackground = LinearGradient(
    colors: [Color(0xFF080C14), Color(0xFF0C1220), Color(0xFF080C14)],
    stops: [0.0, 0.5, 1.0],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}

// ─────────────────────────────────────────────
//  SHADOW HELPERS
// ─────────────────────────────────────────────

class AppShadows {
  AppShadows._();

  static List<BoxShadow> cardShadowLight = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.06),
      blurRadius: 12,
      offset: const Offset(0, 4),
      spreadRadius: -2,
    ),
  ];

  static List<BoxShadow> cardShadowDark = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.4),
      blurRadius: 16,
      offset: const Offset(0, 6),
      spreadRadius: -4,
    ),
  ];

  static List<BoxShadow> goldGlow = [
    BoxShadow(
      color: AppColors.gold.withValues(alpha: 0.35),
      blurRadius: 20,
      spreadRadius: -4,
      offset: Offset.zero,
    ),
  ];

  static List<BoxShadow> navBarShadowLight = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      blurRadius: 20,
      offset: const Offset(0, -4),
    ),
  ];

  static List<BoxShadow> navBarShadowDark = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.5),
      blurRadius: 24,
      offset: const Offset(0, -4),
    ),
  ];
}

// ─────────────────────────────────────────────
//  CARD WIDGET USAGE
// ─────────────────────────────────────────────
//
//  Container(
//    decoration: BoxDecoration(
//      gradient: AppGradients.cardGradient(
//        index: cardIndex,
//        isDark: Theme.of(context).brightness == Brightness.dark,
//      ),
//      borderRadius: BorderRadius.circular(AppTheme.cardRadius),
//      boxShadow: Theme.of(context).brightness == Brightness.dark
//          ? AppShadows.cardShadowDark
//          : AppShadows.cardShadowLight,
//    ),
//    child: ...,
//  )
