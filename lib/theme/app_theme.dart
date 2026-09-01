// app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';


class AppTheme {
  AppTheme._(); // Private constructor to prevent instantiation

  /// Initializes theme-related settings at app startup
  static Future<void> initialize() async {
    // Set system UI overlay style based on our theme
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );

    // Preload fonts to prevent jank during first render
    await GoogleFonts.pendingFonts([
      GoogleFonts.inter(),
      GoogleFonts.inter(fontWeight: FontWeight.w500),
      GoogleFonts.inter(fontWeight: FontWeight.w600),
      GoogleFonts.inter(fontWeight: FontWeight.w700),
    ]);
  }

  // Get an adaptive brightness based on current platform and settings
  static Brightness _getAdaptiveBrightness(BuildContext context) {
    return MediaQuery.platformBrightnessOf(context);
  }

  // Determine if dark mode should be active
  static bool isDarkMode(BuildContext context) {
    return _getAdaptiveBrightness(context) == Brightness.dark;
  }

  // Get the appropriate text color based on theme brightness
  static Color getTextColor(BuildContext context) {
    return isDarkMode(context) ? AppColors.textPrimaryDark : AppColors.textPrimary;
  }

  /// Light theme configuration
  static ThemeData get lightTheme {
    final ColorScheme colorScheme = const ColorScheme(
      primary: AppColors.primary,
      onPrimary: Colors.white,
      primaryContainer: AppColors.primary100,
      onPrimaryContainer: AppColors.primary900,
      secondary: AppColors.secondary,
      onSecondary: Colors.white,
      secondaryContainer: AppColors.secondary100,
      onSecondaryContainer: AppColors.secondary900,
      tertiary: AppColors.accent,
      onTertiary: Colors.white,
      tertiaryContainer: AppColors.accent100,
      onTertiaryContainer: AppColors.accent900,
      error: AppColors.error,
      onError: Colors.white,
      errorContainer: AppColors.error,
      onErrorContainer: AppColors.error,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      surfaceContainerHighest: AppColors.backgroundSubtle,
      onSurfaceVariant: AppColors.textSecondary,
      outline: AppColors.outline,
      outlineVariant: AppColors.divider,
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: AppColors.textPrimary,
      onInverseSurface: AppColors.surface,
      inversePrimary: AppColors.primary100,
      brightness: Brightness.light,
    );

    return _baseTheme(colorScheme);
  }

  /// Dark theme configuration
  static ThemeData get darkTheme {
    final ColorScheme colorScheme = const ColorScheme(
      primary: AppColors.primary300,  // Lighter shade for better visibility
      onPrimary: Colors.white,
      primaryContainer: AppColors.primary800,
      onPrimaryContainer: AppColors.primary100,
      secondary: AppColors.secondary300,  // Lighter shade for better visibility
      onSecondary: Colors.white,
      secondaryContainer: AppColors.secondary800,
      onSecondaryContainer: AppColors.secondary100,
      tertiary: AppColors.accent300,  // Lighter shade for better visibility
      onTertiary: Colors.black,
      tertiaryContainer: AppColors.accent800,
      onTertiaryContainer: AppColors.accent100,
      error: AppColors.error,
      onError: Colors.white,
      errorContainer: Color(0xFF491010),
      onErrorContainer: AppColors.error,
      surface: AppColors.surfaceDark,
      onSurface: AppColors.textPrimaryDark,
      surfaceContainerHighest: AppColors.backgroundSubtleDark,
      onSurfaceVariant: AppColors.textSecondaryDark,
      outline: AppColors.outlineDark,
      outlineVariant: AppColors.dividerDark,
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: AppColors.textPrimaryDark,
      onInverseSurface: AppColors.surfaceDark,
      inversePrimary: AppColors.primary300,
      brightness: Brightness.dark,
    );

    return _baseTheme(colorScheme);
  }

  /// Base theme that defines common properties for both light and dark themes
  static ThemeData _baseTheme(ColorScheme colorScheme) {
    final bool isDark = colorScheme.brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,

      // Text theme using inter font
      textTheme: GoogleFonts.interTextTheme().copyWith(
        displayLarge: _textStyle(size: 32, weight: FontWeight.bold, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary),
        displayMedium: _textStyle(size: 28, weight: FontWeight.bold, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary),
        displaySmall: _textStyle(size: 24, weight: FontWeight.bold, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary),
        headlineLarge: _textStyle(size: 22, weight: FontWeight.w600, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary),
        headlineMedium: _textStyle(size: 20, weight: FontWeight.w600, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary),
        headlineSmall: _textStyle(size: 18, weight: FontWeight.w600, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary),
        titleLarge: _textStyle(size: 16, weight: FontWeight.w600, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary),
        titleMedium: _textStyle(size: 16, weight: FontWeight.w500, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary),
        titleSmall: _textStyle(size: 14, weight: FontWeight.w500, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary),
        bodyLarge: _textStyle(size: 16, weight: FontWeight.normal, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary),
        bodyMedium: _textStyle(size: 14, weight: FontWeight.normal, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary),
        bodySmall: _textStyle(size: 12, weight: FontWeight.normal, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary),
        labelLarge: _textStyle(size: 14, weight: FontWeight.w500, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary),
        labelMedium: _textStyle(size: 12, weight: FontWeight.w500, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary),
        labelSmall: _textStyle(size: 11, weight: FontWeight.w500, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary),
      ),

      // Icon theme
      iconTheme: IconThemeData(
        color: isDark ? AppColors.primary300 : AppColors.primary,
      ),

      // Button themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(

          foregroundColor: Colors.white,
          backgroundColor: isDark ? AppColors.primary300 : AppColors.primary,
          elevation: 0,

          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          shape: RoundedRectangleBorder(

            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: _textStyle(
            size: 16,
            weight: FontWeight.w600,
          ),
          minimumSize: const Size(double.infinity, 56),
        ),
      ),



      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: isDark ? AppColors.primary300 : AppColors.primary,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: _textStyle(
            size: 16,
            weight: FontWeight.w600,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: isDark ? AppColors.primary300 : AppColors.primary,
          side: BorderSide(color: isDark ? AppColors.outlineDark : AppColors.outline),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: _textStyle(
            size: 16,
            weight: FontWeight.w600,
          ),
          minimumSize: const Size(double.infinity, 56),
        ),
      ),

      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.backgroundSubtleDark : AppColors.surface,
        hintStyle: _textStyle(
          size: 16,
          weight: FontWeight.normal,
          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
        ),
        contentPadding: const EdgeInsets.all(16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isDark ? AppColors.outlineDark : AppColors.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isDark ? AppColors.outlineDark : AppColors.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isDark ? AppColors.primary300 : AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
      ),

      // Card theme
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: (isDark ? AppColors.outlineDark : AppColors.outline).withOpacity(0.5),
          ),
        ),
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        surfaceTintColor: Colors.transparent,
        clipBehavior: Clip.antiAlias,
      ),

      // App bar theme
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      ),

      // Form field themes
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return isDark ? AppColors.primary300 : AppColors.primary;
          }
          return null;
        }),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),

      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return isDark ? AppColors.primary300 : AppColors.primary;
          }
          return isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
        }),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return isDark ? AppColors.primary300 : AppColors.primary;
          }
          return null;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return (isDark ? AppColors.primary300 : AppColors.primary).withOpacity(0.5);
          }
          return null;
        }),
      ),

      // Sheet and dialog themes
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        modalElevation: 2,
        showDragHandle: true,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        elevation: isDark ? 3 : 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actionsPadding: const EdgeInsets.all(16),
      ),

      // Progress indicator theme
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: isDark ? AppColors.primary300 : AppColors.primary,
        circularTrackColor: isDark ? AppColors.primary900 : AppColors.primary100,
        linearTrackColor: isDark ? AppColors.primary900 : AppColors.primary100,
      ),

      // Tooltip theme
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.grey[800],
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: TextStyle(
          color: isDark ? AppColors.textPrimaryDark : Colors.white,
          fontSize: 12,
        ),
      ),

      // Snackbar theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.grey[800],
        contentTextStyle: TextStyle(
          color: isDark ? AppColors.textPrimaryDark : Colors.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // Slider theme
      sliderTheme: SliderThemeData(
        activeTrackColor: isDark ? AppColors.primary300 : AppColors.primary,
        inactiveTrackColor: (isDark ? AppColors.primary300 : AppColors.primary).withOpacity(0.3),
        thumbColor: isDark ? AppColors.primary300 : AppColors.primary,
        overlayColor: (isDark ? AppColors.primary300 : AppColors.primary).withOpacity(0.1),
        trackHeight: 4,
      ),

      // Tab bar theme
      tabBarTheme: TabBarThemeData(
        labelColor: isDark ? AppColors.primary300 : AppColors.primary,
        unselectedLabelColor: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
        indicatorColor: isDark ? AppColors.primary300 : AppColors.primary,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
      ),
    );
  }

  /// Helper method to create text styles (now with letter spacing)
  static TextStyle _textStyle({
    required double size,
    required FontWeight weight,
    Color? color,
    double? height,
    TextDecoration? decoration,
    double? letterSpacing,
  }) {
    return GoogleFonts.inter(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height ?? 1.5,
      decoration: decoration,
      letterSpacing: letterSpacing ?? (size > 20 ? -0.5 : 0),
    );
  }

  /// Text styles for direct use in the app
  static AppTextStyles get text => AppTextStyles();
}

/// Class for easily accessible text styles throughout the app
/// Class for easily accessible text styles throughout the app
class AppTextStyles {
  // ─────────────────────────────────────────────────────────────
  // Dynamic Text Styles (Material 3 style)
  // ─────────────────────────────────────────────────────────────
  TextStyle displayLarge({Color? color}) => _getTextStyle(32, FontWeight.bold, color);
  TextStyle displayMedium({Color? color}) => _getTextStyle(28, FontWeight.bold, color);
  TextStyle displaySmall({Color? color}) => _getTextStyle(24, FontWeight.bold, color);

  TextStyle headlineLarge({Color? color}) => _getTextStyle(22, FontWeight.w600, color);
  TextStyle headlineMedium({Color? color}) => _getTextStyle(20, FontWeight.w600, color);
  TextStyle headlineSmall({Color? color}) => _getTextStyle(18, FontWeight.w600, color);

  TextStyle titleLarge({Color? color}) => _getTextStyle(16, FontWeight.w600, color);
  TextStyle titleMedium({Color? color}) => _getTextStyle(16, FontWeight.w500, color);
  TextStyle titleSmall({Color? color}) => _getTextStyle(14, FontWeight.w500, color);

  TextStyle bodyLarge({Color? color}) => _getTextStyle(16, FontWeight.normal, color, height: 1.6);
  TextStyle bodyMedium({Color? color}) => _getTextStyle(14, FontWeight.normal, color, height: 1.6);
  TextStyle bodySmall({Color? color}) => _getTextStyle(12, FontWeight.normal, color, height: 1.5);

  TextStyle labelLarge({Color? color}) => _getTextStyle(14, FontWeight.w500, color);
  TextStyle labelMedium({Color? color}) => _getTextStyle(12, FontWeight.w500, color);
  TextStyle labelSmall({Color? color}) => _getTextStyle(11, FontWeight.w500, color);

  // ─────────────────────────────────────────────────────────────
  // Static Common Styles (from AppTextStyles2)
  // ─────────────────────────────────────────────────────────────
  static const TextStyle heading = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: -0.3,
  );

  static const TextStyle sectionTitle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle statNumber = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.1,
  );

  static const TextStyle statLabel = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.2,
  );

  static const TextStyle statSub = TextStyle(
    fontSize: 10,
    color: AppColors.textTertiary,
  );

  static const TextStyle body = TextStyle(
    fontSize: 13,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodySecondary = TextStyle(
    fontSize: 12,
    color: AppColors.textSecondary,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 11,
    color: AppColors.textTertiary,
  );

  // ─────────────────────────────────────────────────────────────
  // Helper Method
  // ─────────────────────────────────────────────────────────────
  TextStyle _getTextStyle(
      double size,
      FontWeight weight,
      Color? color, {
        double? height,
      }) {
    return AppTheme._textStyle(
      size: size,
      weight: weight,
      color: color,
      height: height,
      letterSpacing: size > 20 ? -0.5 : 0,
    );
  }
}

/// Extensions for Theme access
extension ThemeExtension on BuildContext {
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => Theme.of(this).textTheme;
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  bool get isDarkMode => AppTheme.isDarkMode(this);
  Color get textColor => AppTheme.getTextColor(this);
}

