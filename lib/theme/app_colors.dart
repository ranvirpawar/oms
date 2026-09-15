import 'package:flutter/material.dart';
class AppColors {
  AppColors._(); // Private constructor to prevent instantiation

  // ==========================================================================
  // PRIMARY PALETTE — Trust Blue (brand, chrome, headers, primary actions)
  // Base reference: #185FA5
  // ==========================================================================
  static const Color primary = primary600;

  static const Color primary50  = Color(0xFFE6F1FB);
  static const Color primary100 = Color(0xFFB5D4F4);
  static const Color primary200 = Color(0xFF85B7EB);
  static const Color primary300 = Color(0xFF5EA0E4);
  static const Color primary400 = Color(0xFF378ADD);
  static const Color primary500 = Color(0xFF2875C1);
  static const Color primary600 = Color(0xFF185FA5); // Base primary
  static const Color primary700 = Color(0xFF125291);
  static const Color primary800 = Color(0xFF0C447C);
  static const Color primary900 = Color(0xFF042C53);

  // ==========================================================================
  // SECONDARY PALETTE — Deep Teal (positive actions, accept, success)
  // Base reference: #0F6E56
  // ==========================================================================
  static const Color secondary = secondary600;

  static const Color secondary50  = Color(0xFFE1F5EE);
  static const Color secondary100 = Color(0xFF9FE1CB);
  static const Color secondary200 = Color(0xFF5DCAA5);
  static const Color secondary300 = Color(0xFF3DB48D);
  static const Color secondary400 = Color(0xFF1D9E75);
  static const Color secondary500 = Color(0xFF168666);
  static const Color secondary600 = Color(0xFF0F6E56); // Base secondary
  static const Color secondary700 = Color(0xFF0C5F4C);
  static const Color secondary800 = Color(0xFF085041);
  static const Color secondary900 = Color(0xFF04342C);

  // ==========================================================================
  // ACCENT — reserved for rare emphasis only (chips, progress, illustration)
  // Not used for buttons/CTAs — keeps the brand pair (blue/teal) calm.
  // ==========================================================================
  static const Color accent = secondary400;
  static const Color accentContrast = primary300;

  // --------------------------------------------------------------------------
  // ACCENT SCALE — Warm Amber (migrated from AppColorsOld's emerald accent
  // scale). Recolored to amber instead of green: secondary is already teal/
  // green, so a green accent scale would clash with it. Amber sits opposite
  // blue on the wheel, giving a genuine warm counterpoint for illustration,
  // progress and rare-emphasis chips, and it doubles as the warning hue.
  // --------------------------------------------------------------------------
  static const Color accent50  = Color(0xFFE1F5EE);
  static const Color accent100 = Color(0xFF9FE1CB);
  static const Color accent200 = Color(0xFF5DCAA5);
  static const Color accent300 = Color(0xFF3DB48D);
  static const Color accent400 = Color(0xFF1D9E75);
  static const Color accent500 = Color(0xFF168666);
  static const Color accent600 = Color(0xFF0F6E56);
  static const Color accent700 = Color(0xFF0C5F4C);
  static const Color accent800 = Color(0xFF085041);
  static const Color accent900 = Color(0xFF04342C);
/*  static const Color accent50  = Color(0xFFFFFBEB);
  static const Color accent100 = Color(0xFFFEF3C7);
  static const Color accent200 = Color(0xFFFDE68A);
  static const Color accent300 = Color(0xFFFCD34D);
  static const Color accent400 = Color(0xFFFBBF24);
  static const Color accent500 = Color(0xFFF59E0B);
  static const Color accent600 = Color(0xFFD97706);
  static const Color accent700 = Color(0xFFB45309);
  static const Color accent800 = Color(0xFF92400E);
  static const Color accent900 = Color(0xFF78350F);*/

  // ==========================================================================
  // TERTIARY PALETTE — Violet (migrated from AppColorsOld's tertiary
  // lavender scale). Base matches eyeCare (#7C3AED) so the tertiary hue and
  // the existing "eye care" feature tag stay the same family. Violet sits
  // just past blue on the wheel — an analogous extension of primary that
  // gives a third cool hue without competing with teal.
  // ==========================================================================
  static const Color tertiary = tertiary600;

  static const Color tertiary50  = Color(0xFFF5F3FF);
  static const Color tertiary100 = Color(0xFFEDE9FE);
  static const Color tertiary200 = Color(0xFFDDD6FE);
  static const Color tertiary300 = Color(0xFFC4B5FD);
  static const Color tertiary400 = Color(0xFFA78BFA);
  static const Color tertiary500 = Color(0xFF8B5CF6);
  static const Color tertiary600 = Color(0xFF7C3AED); // Base tertiary
  static const Color tertiary700 = Color(0xFF6D28D9);
  static const Color tertiary800 = Color(0xFF5B21B6);
  static const Color tertiary900 = Color(0xFF4C1D95);

  // HMIS system brand mark — was AppColorsOld.accent900 (deep emerald).
  // Now points at the deepest tertiary violet to keep it a distinct third
  // identity, separate from primary/secondary, as originally intended.
  static const Color hmisPrimary = tertiary900;

  static const Gradient tertiaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [tertiary900, tertiary700],
    stops: [0.0, 1.0],
  );

  // ==========================================================================
  // NEUTRAL COLORS — Light theme
  // ==========================================================================
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceContainer = Color(0xFFF7FAFC);
  static const Color surfaceContainerHigh = Color(0xFFEBF1F7);
  static const Color background = Color(0xFFFBFCFE);
  static const Color backgroundSubtle = Color(0xFFF3F6FA);
  static const Color outline = Color(0xFFE1E6EC);
  static const Color outlineVariant = Color(0xFFF0F3F7);
  static const Color divider = Color(0xFFCFD6DE);
  static const Color border = Color(0xFFE7EBF0);
  static const Color borderStrong = Color(0xFFC3CCD6);

  // Legacy background aliases from AppColorsOld — mapped onto the existing
  // neutral scale above rather than new literals, so they stay in lock-step
  // with the rest of the theme.
  static const Color bgPage = backgroundSubtle;
  static const Color bgCard = surface;
  static const Color bgCardAlt = surfaceContainer;

  // ==========================================================================
  // NEUTRAL COLORS — Dark theme
  // ==========================================================================
  static const Color surfaceDark = Color(0xFF0A0E14);
  static const Color surfaceContainerDark = Color(0xFF131A24);
  static const Color surfaceContainerHighDark = Color(0xFF1B2530);
  static const Color backgroundDark = Color(0xFF060A10);
  static const Color backgroundSubtleDark = Color(0xFF0E141C);
  static const Color outlineDark = Color(0xFF2A3644);
  static const Color outlineVariantDark = Color(0xFF212B38);
  static const Color dividerDark = Color(0xFF3A4756);
  static const Color borderDark = Color(0xFF31404F);

  // ==========================================================================
  // TEXT COLORS — Light theme
  // ==========================================================================
  static const Color onSurface = Color(0xFF0B121A);
  static const Color onSurfaceVariant = Color(0xFF2A3644);
  static const Color onSurfaceSecondary = Color(0xFF44515F);
  static const Color onSurfaceTertiary = Color(0xFF64707D);
  static const Color onSurfaceDisabled = Color(0xFF97A2AC);

  static const Color textPrimary = onSurface;
  static const Color textSecondary = onSurfaceVariant;
  static const Color textTertiary = onSurfaceSecondary;
  static const Color textQuaternary = onSurfaceTertiary;
  static const Color textDisabled = onSurfaceDisabled;
  static const Color textInverse = Color(0xFFFFFFFF);
  static const Color textBrand = primary600;
  static const Color textLink = primary700;
  static const Color textLinkHover = primary800;

  // ==========================================================================
  // TEXT COLORS — Dark theme
  // ==========================================================================
  static const Color onSurfaceDark = Color(0xFFF7FAFC);
  static const Color onSurfaceVariantDark = Color(0xFFD6DEE6);
  static const Color onSurfaceSecondaryDark = Color(0xFFAAB6C2);
  static const Color onSurfaceTertiaryDark = Color(0xFF97A2AC);
  static const Color onSurfaceDisabledDark = Color(0xFF64707D);

  static const Color textPrimaryDark = onSurfaceDark;
  static const Color textSecondaryDark = onSurfaceVariantDark;
  static const Color textTertiaryDark = onSurfaceSecondaryDark;
  static const Color textQuaternaryDark = onSurfaceTertiaryDark;
  static const Color textDisabledDark = onSurfaceDisabledDark;
  static const Color textInverseDark = Color(0xFF0B121A);
  static const Color textBrandDark = primary300;
  static const Color textLinkDark = primary200;
  static const Color textLinkHoverDark = primary100;

  // ==========================================================================
  // FUNCTIONAL COLORS — tied to the new brand pair where it makes sense
  // ==========================================================================
  static const Color success = secondary600;           // deep teal — Accept, positive
  static const Color successContainer = secondary50;
  static const Color onSuccess = Color(0xFFFFFFFF);
  static const Color onSuccessContainer = secondary900;

  static const Color warning = Color(0xFFD97706);
  static const Color warningContainer = Color(0xFFFEF3C7);
  static const Color onWarning = Color(0xFFFFFFFF);
  static const Color onWarningContainer = Color(0xFF92400E);

  static const Color error = Color(0xFFDC2626);
  static const Color errorContainer = Color(0xFFFEE2E2);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color onErrorContainer = Color(0xFF7F1D1D);

  static const Color info = primary500;                // reuse primary for info — one hue, less noise
  static const Color infoContainer = primary50;
  static const Color onInfo = Color(0xFFFFFFFF);
  static const Color onInfoContainer = primary900;

  // Functional text colors — Light theme
  static const Color textSuccess = secondary700;
  static const Color textSuccessSecondary = secondary600;
  static const Color textWarning = Color(0xFFB45309);
  static const Color textWarningSecondary = Color(0xFFD97706);
  static const Color textError = Color(0xFFDC2626);
  static const Color textErrorSecondary = Color(0xFFEF4444);
  static const Color textInfo = primary700;
  static const Color textInfoSecondary = primary600;

  // Functional text colors — Dark theme (migrated from AppColorsOld,
  // rebased onto the new primary/secondary scales for success & info)
  static const Color textSuccessDark = secondary400;
  static const Color textSuccessSecondaryDark = secondary300;
  static const Color textWarningDark = Color(0xFFFBBF24);
  static const Color textWarningSecondaryDark = Color(0xFFFCD34D);
  static const Color textErrorDark = Color(0xFFF87171);
  static const Color textErrorSecondaryDark = Color(0xFFFCA5A5);
  static const Color textInfoDark = primary300;
  static const Color textInfoSecondaryDark = primary200;

  // Special-purpose text utilities (migrated from AppColorsOld). These are
  // intentionally hue-neutral / off-brand — highlight, code, and muted text
  // aren't meant to carry brand color, so they're kept as-is.
  static const Color textHighlight = Color(0xFFFEF08A);
  static const Color textHighlightDark = Color(0xFF365314);
  static const Color textCode = Color(0xFF7C2D12);
  static const Color textCodeDark = Color(0xFFFED7AA);
  static const Color textMuted = Color(0xFF9CA3AF);
  static const Color textMutedDark = Color(0xFF6B7280);

  // ==========================================================================
  // STATUS CHIPS (badges, tags) — light tint + matching border + dark text
  // ==========================================================================
  static const Color greenLight  = secondary50;
  static const Color greenText   = secondary700;
  static const Color greenBorder = secondary200;

  static const Color amberLight  = Color(0xFFFEF3C7);
  static const Color amberText   = Color(0xFFB45309);
  static const Color amberBorder = Color(0xFFFBBF24);

  static const Color redLight    = Color(0xFFFEE2E2);
  static const Color redText     = Color(0xFFDC2626);
  static const Color redBorder   = Color(0xFFFCA5A5);

  static const Color blue        = primary500;   // standalone blue, migrated from AppColorsOld
  static const Color blueLight   = primary50;
  static const Color blueText    = primary700;

  static const Color purple      = tertiary600;  // migrated from AppColorsOld — now shares tertiary's violet
  static const Color purpleLight = tertiary50;
  static const Color purpleText  = tertiary700;

  static const Color teal        = secondary600; // migrated from AppColorsOld — now just secondary, no separate green needed
  static const Color tealLight   = secondary50;
  static const Color tealText    = secondary700;
  static const Color tealBorder  = secondary200;
  static const Color tealTextOG  = secondary700; // migrated 1:1 equivalent of the old literal (#0F766E)

  static const Color grayLight   = Color(0xFFF1F5F9);
  static const Color grayText    = Color(0xFF475569);

  // Feature/category tags (used across module icons, tags, etc.)
  static const Color generalHealth = secondary700;
  static const Color eyeCare       = Color(0xFF7C3AED);
  static const Color vaccination   = Color(0xFFEA580C);
  static const Color dentalCare    = Color(0xFFDC2626);
  static const Color womensHealth  = Color(0xFFDB2777);

  // --------------------------------------------------------------------------
  // EMERALD UTILITY SCALE — migrated verbatim from AppColorsOld. Kept as a
  // plain named scale (not recolored) since it's a generic utility ramp
  // rather than a brand hue — brand "green" duties are already covered by
  // the secondary teal scale above.
  // --------------------------------------------------------------------------
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

  // ==========================================================================
  // CHART COLORS — distinct hues for at-a-glance scanning
  // ==========================================================================
  static const List<Color> chartColors = [
    primary600,               // registered   — blue
    secondary600,             // bag accepted — teal
    Color(0xFF7C3AED),        // handover     — purple
    Color(0xFFF59E0B),        // pending      — amber
    Color(0xFFDC2626),        // closed       — red
  ];

  // ==========================================================================
  // GRADIENTS — flat two-stop, same hue family (no clashing hues)
  // ==========================================================================
  static const Gradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary800, primary600],
    stops: [0.0, 1.0],
  );

  // Reversed-direction primary gradient, migrated from AppColorsOld
  // (old stops [0.0, 2.0] were invalid — a LinearGradient's stops must be
  // increasing values <= 1.0 — corrected to [0.0, 1.0] here).
  static const Gradient primaryGradientRev = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.topRight,
    colors: [primary900, primary700],
    stops: [0.0, 1.0],
  );

  static const Gradient secondaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [secondary700, secondary500],
    stops: [0.0, 1.0],
  );

  // Migrated from AppColorsOld, rebuilt from the new amber accent scale.
  static const Gradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accent700, accent500],
    stops: [0.0, 1.0],
  );

  static const Gradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary700, primary500, secondary500],
    stops: [0.0, 0.5, 1.0],
  );

  static const Gradient shimmerGradient = LinearGradient(
    begin: Alignment(-1.0, -0.3),
    end: Alignment(1.0, 0.3),
    colors: [outline, outlineVariant, outline],
    stops: [0.0, 0.5, 1.0],
  );

  // --------------------------------------------------------------------------
  // GLASS MORPHISM — migrated verbatim from AppColorsOld (translucent
  // overlays; not tied to brand hue).
  // --------------------------------------------------------------------------
  static const Color glassLight = Color(0x1AFFFFFF);
  static const Color glassDark = Color(0x1A000000);
  static const Color glassBlur = Color(0x0DFFFFFF);

  // ==========================================================================
  // ELEVATION SHADOWS
  // ==========================================================================
  static List<BoxShadow> get shadowXs => [
    BoxShadow(color: const Color(0xFF0B121A).withOpacity(0.05), blurRadius: 2, offset: const Offset(0, 1)),
  ];

  static List<BoxShadow> get shadowSm => [
    BoxShadow(color: const Color(0xFF0B121A).withOpacity(0.06), blurRadius: 4, offset: const Offset(0, 1)),
    BoxShadow(color: const Color(0xFF0B121A).withOpacity(0.10), blurRadius: 3, offset: const Offset(0, 1)),
  ];

  static List<BoxShadow> get shadowMd => [
    BoxShadow(color: const Color(0xFF0B121A).withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 4)),
    BoxShadow(color: const Color(0xFF0B121A).withOpacity(0.10), blurRadius: 3, offset: const Offset(0, 2)),
  ];

  static List<BoxShadow> get shadowLg => [
    BoxShadow(color: const Color(0xFF0B121A).withOpacity(0.08), blurRadius: 16, offset: const Offset(0, 10)),
    BoxShadow(color: const Color(0xFF0B121A).withOpacity(0.06), blurRadius: 6, offset: const Offset(0, 4)),
  ];

  static List<BoxShadow> get shadowXl => [
    BoxShadow(color: const Color(0xFF0B121A).withOpacity(0.08), blurRadius: 24, offset: const Offset(0, 20)),
    BoxShadow(color: const Color(0xFF0B121A).withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 8)),
  ];

  static List<BoxShadow> get primaryShadow => [
    BoxShadow(color: primary.withOpacity(0.25), blurRadius: 16, offset: const Offset(0, 8)),
  ];

  static List<BoxShadow> get secondaryShadow => [
    BoxShadow(color: secondary.withOpacity(0.25), blurRadius: 16, offset: const Offset(0, 8)),
  ];

  // ==========================================================================
  // UTILITIES / STATE COLORS
  // ==========================================================================
  static Color withOpacity(Color color, double opacity) => color.withOpacity(opacity);

  static Color blend(Color color1, Color color2, double factor) {
    return Color.lerp(color1, color2, factor) ?? color1;
  }

  static Color get primaryHover => primary700;
  static Color get primaryPressed => primary800;
  static Color get primaryFocus => primary.withOpacity(0.12);

  static Color get secondaryHover => secondary700;
  static Color get secondaryPressed => secondary800;
  static Color get secondaryFocus => secondary.withOpacity(0.12);

  static Color surfaceTint = primary;
  static Color get surfaceTintLight => primary.withOpacity(0.05);
  static Color get surfaceTintMedium => primary.withOpacity(0.08);
  static Color get surfaceTintStrong => primary.withOpacity(0.12);
}



class AppColorsOld {
  AppColorsOld._(); // Private constructor to prevent instantiation

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
    colors: [AppColorsOld.tertiary900, AppColorsOld.tertiary700],
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




