import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
class AppColors {
  AppColors._(); // Private constructor to prevent instantiation

  // Primary palette - Soft Periwinkle Blue
  static const Color primary = primary700;
/*
  static const Color primary = Color(0xFF8C94FF); // rgba(140, 148, 255, 1)
*/
  static const Color primary50 = Color(0xFFF0F1FF);
  static const Color primary100 = Color(0xFFE1E4FF);
  static const Color primary200 = Color(0xFFCBD0FF);
  static const Color primary300 = Color(0xFFAAB2FF);
  static const Color primary400 = Color(0xFF9BA3FF);
  static const Color primary500 = Color(0xFF8C94FF); // Base primary
  static const Color primary600 = Color(0xFF7B83FF);
  static const Color primary700 = Color(0xFF6B72FF);
  static const Color primary800 = Color(0xFF5A61E8);
  static const Color primary900 = Color(0xFF4A4FD1);

  // Secondary palette - Warm Coral (Complementary contrast)
  static const Color secondary = Color(0xFFFF8A80);
  static const Color secondary50 = Color(0xFFFFF3F2);
  static const Color secondary100 = Color(0xFFFFE5E0);
  static const Color secondary200 = Color(0xFFFFCDD2);
  static const Color secondary300 = Color(0xFFFFAB91);
  static const Color secondary400 = Color(0xFFFF8A80);
  static const Color secondary500 = Color(0xFFFF7043); // Base secondary
  static const Color secondary600 = Color(0xFFFF5722);
  static const Color secondary700 = Color(0xFFE64A19);
  static const Color secondary800 = Color(0xFFD84315);
  static const Color secondary900 = Color(0xFFBF360C);

  // Accent palette - Vibrant Emerald (Triadic harmony)
  static const Color accent = Color(0xFF00E676);
  static const Color accent50 = Color(0xFFE8F8F5);
  static const Color accent100 = Color(0xFFB2F5EA);
  static const Color accent200 = Color(0xFF81F7E5);
  static const Color accent300 = Color(0xFF4FFFB0);
  static const Color accent400 = Color(0xFF1DE9B6);
  static const Color accent500 = Color(0xFF00E676); // Base accent
  static const Color accent600 = Color(0xFF00C853);
  static const Color accent700 = Color(0xFF00B248);
  static const Color accent800 = Color(0xFF009624);
  static const Color accent900 = Color(0xFF00701A);

  // Tertiary palette - Soft Lavender (Analogous)
  static const Color tertiary = Color(0xFFB19CD9);
  static const Color tertiary50 = Color(0xFFF8F5FF);
  static const Color tertiary100 = Color(0xFFEDE7F6);
  static const Color tertiary200 = Color(0xFFD1C4E9);
  static const Color tertiary300 = Color(0xFFB19CD9);
  static const Color tertiary400 = Color(0xFF9C88C4);
  static const Color tertiary500 = Color(0xFF8E75B0);
  static const Color tertiary600 = Color(0xFF7B68A2);
  static const Color tertiary700 = Color(0xFF6A5B93);
  static const Color tertiary800 = Color(0xFF5A4E7E);
  static const Color tertiary900 = Color(0xFF4A3F68);

  // Nhm Primary static const Color primary500 = Color(0xFF7030A0);
  static const Color hmisPrimary  = accent900;

  // tertiary gradient patterns
  static const Gradient tertiaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.tertiary900, AppColors.tertiary700],
    stops: [0.0, 1.0],
  );
  static const Color generalHealth = Color(0xFF059669);
  static const Color eyeCare = Color(0xFF7C3AED);
  static const Color vaccination = Color(0xFFEA580C);
  static const Color dentalCare = Color(0xFFDC2626);
  static const Color womensHealth = Color(0xFFDB2777);

  // Neutral colors - Light theme (Modern grays with slight blue tint)
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceContainer = Color(0xFFF8F9FF);
  static const Color surfaceContainerHigh = Color(0xFFEEF1FF);
  static const Color background = Color(0xFFFBFCFF);
  static const Color backgroundSubtle = Color(0xFFF5F7FF);
  static const Color outline = Color(0xFFE4E7EC);
  static const Color outlineVariant = Color(0xFFF2F4F7);
  static const Color divider = Color(0xFFD0D5DD);
  static const Color border = Color(0xFFEAECF0);

  // Neutral colors - Dark theme
  static const Color surfaceDark = Color(0xFF0D0E1A);
  static const Color surfaceContainerDark = Color(0xFF161828);
  static const Color surfaceContainerHighDark = Color(0xFF1F2137);
  static const Color backgroundDark = Color(0xFF080914);
  static const Color backgroundSubtleDark = Color(0xFF111325);
  static const Color outlineDark = Color(0xFF2D3142);
  static const Color outlineVariantDark = Color(0xFF252842);
  static const Color dividerDark = Color(0xFF3D4258);
  static const Color borderDark = Color(0xFF353B52);

  // Text colors - Light theme
  static const Color onSurface = Color(0xFF0A0B14);
  static const Color onSurfaceVariant = Color(0xFF2D3142);
  static const Color onSurfaceSecondary = Color(0xFF475467);
  static const Color onSurfaceTertiary = Color(0xFF667085);
  static const Color onSurfaceDisabled = Color(0xFF98A2B3);

  // Text colors - Dark theme
  static const Color onSurfaceDark = Color(0xFFF9FAFB);
  static const Color onSurfaceVariantDark = Color(0xFFD0D5DD);
  static const Color onSurfaceSecondaryDark = Color(0xFFADB5CC);
  static const Color onSurfaceTertiaryDark = Color(0xFF98A2B3);
  static const Color onSurfaceDisabledDark = Color(0xFF667085);

  // Functional colors - Modern and accessible
  static const Color success = Color(0xFF10B981);
  static const Color successContainer = Color(0xFFECFDF5);
  static const Color onSuccess = Color(0xFFFFFFFF);
  static const Color onSuccessContainer = Color(0xFF064E3B);

  static const Color warning = Color(0xFFF59E0B);
  static const Color warningContainer = Color(0xFFFEF3C7);
  static const Color onWarning = Color(0xFFFFFFFF);
  static const Color onWarningContainer = Color(0xFF92400E);

  static const Color error = Color(0xFFEF4444);
  static const Color errorContainer = Color(0xFFFEE2E2);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color onErrorContainer = Color(0xFF7F1D1D);

  static const Color info = Color(0xFF3B82F6);
  static const Color infoContainer = Color(0xFFEBF4FF);
  static const Color onInfo = Color(0xFFFFFFFF);
  static const Color onInfoContainer = Color(0xFF1E3A8A);



  // Background
  static const Color bgPage         = Color(0xFFF4F6FB); // fine as-is, keep airy
  static const Color bgCard         = Color(0xFFFFFFFF);
  static const Color bgCardAlt      = Color(0xFFF8FAFC);

// Borders
  static const Color borderStrong   = Color(0xFFCBD5E1); // more defined edge

// Status Colors — punchier text, tint stays light but less muddy
  static const Color greenLight     = Color(0xFFDCFCE7);
  static const Color greenText      = Color(0xFF15803D);
  static const Color greenBorder    = Color(0xFF86EFAC);

  static const Color amberLight     = Color(0xFFFEF3C7);
  static const Color amberText      = Color(0xFFB45309);
  static const Color amberBorder    = Color(0xFFFBBF24);

  static const Color redLight       = Color(0xFFFEE2E2);
  static const Color redText        = Color(0xFFDC2626);
  static const Color redBorder      = Color(0xFFFCA5A5);

  static const Color blue           = Color(0xFF2563EB);
  static const Color blueLight      = Color(0xFFDBEAFE);
  static const Color blueText       = Color(0xFF1D4ED8);

  static const Color purple         = Color(0xFF7C3AED);
  static const Color purpleLight    = Color(0xFFEDE9FE);
  static const Color purpleText     = Color(0xFF6D28D9);

  static const Color teal       = accent600;
  static const Color tealLight  = accent50;
  static const Color tealText   = accent800;
  static const Color tealBorder = accent300;
  static const Color tealTextOG    = Color(0xFF0F766E);

  static const Color grayLight      = Color(0xFFF1F5F9);
  static const Color grayText       = Color(0xFF475569);

// Chart Colors — high-saturation, distinct hues for at-a-glance scanning
  static const List<Color> chartColors = [
    Color(0xFF2563EB), // registered   — blue
    Color(0xFF16A34A), // bag accepted — green
    Color(0xFF7C3AED), // handover     — purple
    Color(0xFFF59E0B), // pending      — amber
    Color(0xFFDC2626), // closed       — red
  ];
  // Text colors - Light theme
  static const Color textPrimary = Color(0xFF0A0B14);           // Main headings, primary content
  static const Color textSecondary = Color(0xFF2D3142);         // Secondary content, subheadings
  static const Color textTertiary = Color(0xFF475467);          // Supporting text, captions
  static const Color textQuaternary = Color(0xFF667085);        // Placeholder text, metadata
  static const Color textDisabled = Color(0xFF98A2B3);          // Disabled states
  static const Color textInverse = Color(0xFFFFFFFF);           // White text on dark backgrounds
  static const Color textBrand = Color(0xFF8C94FF);             // Brand colored text
  static const Color textLink = Color(0xFF6B72FF);              // Links and interactive text
  static const Color textLinkHover = Color(0xFF5A61E8);         // Link hover state

  // Text colors - Dark theme
  static const Color textPrimaryDark = Color(0xFFF9FAFB);       // Main headings, primary content
  static const Color textSecondaryDark = Color(0xFFE4E7EC);     // Secondary content, subheadings
  static const Color textTertiaryDark = Color(0xFFD0D5DD);      // Supporting text, captions
  static const Color textQuaternaryDark = Color(0xFFADB5CC);    // Placeholder text, metadata
  static const Color textDisabledDark = Color(0xFF667085);      // Disabled states
  static const Color textInverseDark = Color(0xFF0A0B14);       // Dark text on light backgrounds
  static const Color textBrandDark = Color(0xFF9BA3FF);         // Brand colored text
  static const Color textLinkDark = Color(0xFFAAB2FF);          // Links and interactive text
  static const Color textLinkHoverDark = Color(0xFF8C94FF);     // Link hover state


  // Functional text colors - Light theme
  static const Color textSuccess = Color(0xFF047857);           // Success messages, positive states
  static const Color textSuccessSecondary = Color(0xFF059669);  // Secondary success text
  static const Color textWarning = Color(0xFFD97706);           // Warning messages, cautions
  static const Color textWarningSecondary = Color(0xFFF59E0B);  // Secondary warning text
  static const Color textError = Color(0xFFDC2626);             // Error messages, danger states
  static const Color textErrorSecondary = Color(0xFFEF4444);    // Secondary error text
  static const Color textInfo = Color(0xFF2563EB);              // Info messages, help text
  static const Color textInfoSecondary = Color(0xFF3B82F6);     // Secondary info text

  // Functional text colors - Dark theme
  static const Color textSuccessDark = Color(0xFF10B981);       // Success messages, positive states
  static const Color textSuccessSecondaryDark = Color(0xFF34D399); // Secondary success text
  static const Color textWarningDark = Color(0xFFF59E0B);       // Warning messages, cautions
  static const Color textWarningSecondaryDark = Color(0xFFFBBF24); // Secondary warning text
  static const Color textErrorDark = Color(0xFFEF4444);         // Error messages, danger states
  static const Color textErrorSecondaryDark = Color(0xFFF87171); // Secondary error text
  static const Color textInfoDark = Color(0xFF3B82F6);          // Info messages, help text
  static const Color textInfoSecondaryDark = Color(0xFF60A5FA); // Secondary info text

  // Special text colors
  static const Color textHighlight = Color(0xFFFEF08A);         // Highlighted/marked text
  static const Color textHighlightDark = Color(0xFF365314);     // Highlighted text on dark background
  static const Color textCode = Color(0xFF7C2D12);              // Code snippets, monospace
  static const Color textCodeDark = Color(0xFFFED7AA);          // Code snippets on dark background
  static const Color textMuted = Color(0xFF9CA3AF);             // Very subtle text
  static const Color textMutedDark = Color(0xFF6B7280);         // Very subtle text on dark

  static const Color emerald50  = Color(0xFFECFDF5);
  static const Color emerald100 = Color(0xFFD1FAE5);
  static const Color emerald200 = Color(0xFFA7F3D0);
  static const Color emerald300 = Color(0xFF6EE7B7);
  static const Color emerald400 = Color(0xFF34D399);
  static const Color emerald500 = Color(0xFF10B981);
  static const Color emerald600 = Color(0xFF059669);
  static const Color emerald700 = Color(0xFF047857);
  static const Color emerald800 = Color(0xFF065F46);
  static const Color emerald900 = Color(0xFF064E3B);

  // Gradients - Modern and sophisticated
  static const Gradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,

    colors:[AppColors.primary900, AppColors.primary700],
    stops: [0.0, 1.0],
  );static const Gradient primaryGradientRev = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.topRight,

    colors:[AppColors.primary900, AppColors.primary700],
    stops: [0.0, 2.0],
  );

  static const Gradient secondaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF8A80), Color(0xFFFF5722)],
    stops: [0.0, 1.0],
  );

  static const Gradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF00E676), Color(0xFF00B248)],
    stops: [0.0, 1.0],
  );

  static const Gradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF8C94FF), Color(0xFFB19CD9), Color(0xFF00E676)],
    stops: [0.0, 0.5, 1.0],
  );

  static const Gradient shimmerGradient = LinearGradient(
    begin: Alignment(-1.0, -0.3),
    end: Alignment(1.0, 0.3),
    colors: [
      Color(0xFFE4E7EC),
      Color(0xFFF2F4F7),
      Color(0xFFE4E7EC),
    ],
    stops: [0.0, 0.5, 1.0],
  );

  // Glass morphism effects
  static const Color glassLight = Color(0x1AFFFFFF);
  static const Color glassDark = Color(0x1A000000);
  static const Color glassBlur = Color(0x0DFFFFFF);

  // Elevation shadows - Modern and subtle
  static List<BoxShadow> get shadowXs => [
    BoxShadow(
      color: const Color(0xFF101828).withOpacity(0.05),
      blurRadius: 2,
      offset: const Offset(0, 1),
    ),
  ];

  static List<BoxShadow> get shadowSm => [
    BoxShadow(
      color: const Color(0xFF101828).withOpacity(0.06),
      blurRadius: 4,
      offset: const Offset(0, 1),
    ),
    BoxShadow(
      color: const Color(0xFF101828).withOpacity(0.10),
      blurRadius: 3,
      offset: const Offset(0, 1),
    ),
  ];

  static List<BoxShadow> get shadowMd => [
    BoxShadow(
      color: const Color(0xFF101828).withOpacity(0.06),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: const Color(0xFF101828).withOpacity(0.10),
      blurRadius: 3,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get shadowLg => [
    BoxShadow(
      color: const Color(0xFF101828).withOpacity(0.08),
      blurRadius: 16,
      offset: const Offset(0, 10),
    ),
    BoxShadow(
      color: const Color(0xFF101828).withOpacity(0.06),
      blurRadius: 6,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get shadowXl => [
    BoxShadow(
      color: const Color(0xFF101828).withOpacity(0.08),
      blurRadius: 24,
      offset: const Offset(0, 20),
    ),
    BoxShadow(
      color: const Color(0xFF101828).withOpacity(0.03),
      blurRadius: 8,
      offset: const Offset(0, 8),
    ),
  ];

  // Colored shadows for premium feel
  static List<BoxShadow> get primaryShadow => [
    BoxShadow(
      color: primary.withOpacity(0.25),
      blurRadius: 16,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> get secondaryShadow => [
    BoxShadow(
      color: secondary.withOpacity(0.25),
      blurRadius: 16,
      offset: const Offset(0, 8),
    ),
  ];

  // Utility methods
  static Color withOpacity(Color color, double opacity) => color.withOpacity(opacity);

  static Color blend(Color color1, Color color2, double factor) {
    return Color.lerp(color1, color2, factor) ?? color1;
  }

  // State colors for interactive elements
  static Color get primaryHover => const Color(0xFF7B83FF);
  static Color get primaryPressed => const Color(0xFF6B72FF);
  static Color get primaryFocus => primary.withOpacity(0.12);

  static Color get secondaryHover => const Color(0xFFFF7043);
  static Color get secondaryPressed => const Color(0xFFFF5722);
  static Color get secondaryFocus => secondary.withOpacity(0.12);

  // Surface tints for Material You compatibility
  static Color surfaceTint = primary;
  static Color get surfaceTintLight => primary.withOpacity(0.05);
  static Color get surfaceTintMedium => primary.withOpacity(0.08);
  static Color get surfaceTintStrong => primary.withOpacity(0.12);
}




class AppColors2 {
  AppColors2._();

  // ── Primary palette - Soft Periwinkle Blue ──────────────────────
  static const Color primary = primary700;
  static const Color primary50 = Color(0xFFF0F1FF);
  static const Color primary100 = Color(0xFFE1E4FF);
  static const Color primary200 = Color(0xFFCBD0FF);
  static const Color primary300 = Color(0xFFAAB2FF);
  static const Color primary400 = Color(0xFF9BA3FF);
  static const Color primary500 = Color(0xFF8C94FF);
  static const Color primary600 = Color(0xFF7B83FF);
  static const Color primary700 = Color(0xFF6B72FF);
  static const Color primary800 = Color(0xFF5A61E8);
  static const Color primary900 = Color(0xFF4A4FD1);

  // ── Secondary - Warm Coral ───────────────────────────────────────
  static const Color secondary = Color(0xFFFF8A80);
  static const Color secondary500 = Color(0xFFFF7043);
  static const Color secondary700 = Color(0xFFE64A19);

  // ── Neutral - Light ──────────────────────────────────────────────
  static const Color surface = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFFBFCFF);
  static const Color backgroundSubtle = Color(0xFFF5F7FF);
  static const Color outline = Color(0xFFE4E7EC);
  static const Color divider = Color(0xFFD0D5DD);

  // ── Neutral - Dark ───────────────────────────────────────────────
  static const Color surfaceDark = Color(0xFF0D0E1A);
  static const Color backgroundDark = Color(0xFF080914);
  static const Color backgroundSubtleDark = Color(0xFF111325);
  static const Color outlineDark = Color(0xFF2D3142);
  static const Color dividerDark = Color(0xFF3D4258);

  // ── Text - Light ─────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF0A0B14);
  static const Color textSecondary = Color(0xFF2D3142);

  // ── Text - Dark ──────────────────────────────────────────────────
  static const Color textPrimaryDark = Color(0xFFF9FAFB);
  static const Color textSecondaryDark = Color(0xFFE4E7EC);

  // ── Functional colors ────────────────────────────────────────────
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // FIX (Critical #1): errorContainer/onErrorContainer were both set to
  // `error`, producing 1:1 contrast and invisible text. Restored as a
  // proper soft-fill / dark-text pair.
  static const Color errorContainer = Color(0xFFFEE2E2);
  static const Color onErrorContainer = Color(0xFF7F1D1D);
  static const Color errorContainerDark = Color(0xFF491010);
  static const Color onErrorContainerDark = Color(0xFFEF4444);

  // ── Category colors (health app) ─────────────────────────────────
  // FIX (Critical #2): these previously had no dark-mode counterparts.
  // Use `categoryColor(context, ...)` below rather than the raw
  // constants directly so brightness is always respected.
  static const Color generalHealth = Color(0xFF059669);
  static const Color generalHealthDark = Color(0xFF34D399);
  static const Color eyeCare = Color(0xFF7C3AED);
  static const Color eyeCareDark = Color(0xFFA78BFA);
  static const Color vaccination = Color(0xFFEA580C);
  static const Color vaccinationDark = Color(0xFFFB923C);
  static const Color dentalCare = Color(0xFFDC2626);
  static const Color dentalCareDark = Color(0xFFF87171);
  static const Color womensHealth = Color(0xFFDB2777);
  static const Color womensHealthDark = Color(0xFFF472B6);

  /// Returns the brightness-correct variant of a category color instead of
  /// forcing callers to branch on Theme.of(context).brightness themselves.
  static Color categoryColorFor(BuildContext context, {
    required Color light,
    required Color dark,
  }) {
    return Theme.of(context).brightness == Brightness.dark ? dark : light;
  }

  // ── Chart colors ─────────────────────────────────────────────────
  static const List<Color> chartColors = [
    Color(0xFF2563EB),
    Color(0xFF16A34A),
    Color(0xFF7C3AED),
    Color(0xFFF59E0B),
    Color(0xFFDC2626),
  ];
  static const List<Color> chartColorsDark = [
    Color(0xFF60A5FA),
    Color(0xFF4ADE80),
    Color(0xFFA78BFA),
    Color(0xFFFBBF24),
    Color(0xFFF87171),
  ];
  static List<Color> chartColorsFor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? chartColorsDark : chartColors;

  // ── Interaction-state colors ────────────────────────────────────
  // FIX (Critical #3): previously static regardless of brightness, so
  // dark-mode presses were invisible. These are now brightness-aware
  // overlay colors, not standalone fills — apply with .withOpacity()
  // via the WidgetStateProperty helpers in AppTheme.
  static Color pressOverlay(BuildContext context) =>
      (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black)
          .withOpacity(0.10);

  static Color hoverOverlay(BuildContext context) =>
      (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black)
          .withOpacity(0.05);

  static Color focusOverlay(BuildContext context) =>
      (Theme.of(context).brightness == Brightness.dark ? primary300 : primary700)
          .withOpacity(0.18);
}