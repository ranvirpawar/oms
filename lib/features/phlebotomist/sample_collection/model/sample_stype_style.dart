import 'package:flutter/material.dart';
import 'package:lifenity_connect/constants/app_assets.dart';

import '../../../../theme/app_colors.dart';

// NOTE: once your sample-type SVGs are ready, wire them in via
// SvgPicture.asset(style.iconAsset, colorFilter: ColorFilter.mode(style.color, BlendMode.srcIn))
// inside `sampleTypeIcon()` below. The lookup keys/API won't need to change —
// only the render call at the bottom of this file.

class SampleTypeStyle {
  final String iconAsset;
  final IconData fallbackIcon;
  final Color color;

  const SampleTypeStyle({
    required this.iconAsset,
    required this.fallbackIcon,
    required this.color,
  });
}

class SampleTypeStyles {
  SampleTypeStyles._();

  static const _default = SampleTypeStyle(
    iconAsset: AppAssets.testTube,
    fallbackIcon: Icons.science_rounded,
    color: AppColors.primary,
  );

  // Add / rename keys here as your real sample-type names come in from the API.
  // Matching is case-insensitive and does a "contains" check, so
  // "Venous Blood" or "Blood (EDTA)" will both match the "blood" entry.
  static const Map<String, SampleTypeStyle> _byType = {
    'blood': SampleTypeStyle(
      iconAsset: AppAssets.testTube,
      fallbackIcon: Icons.bloodtype_rounded,
      color: Color(0xFFE11D48),
    ),
    'urine': SampleTypeStyle(
      iconAsset: 'assets/icons/sample_types/urine.svg',
      fallbackIcon: Icons.water_drop_rounded,
      color: Color(0xFFF59E0B),
    ),
    'stool': SampleTypeStyle(
      iconAsset: 'assets/icons/sample_types/stool.svg',
      fallbackIcon: Icons.grain_rounded,
      color: Color(0xFF8B5E34),
    ),
    'swab': SampleTypeStyle(
      iconAsset: 'assets/icons/sample_types/swab.svg',
      fallbackIcon: Icons.medical_services_rounded,
      color: Color(0xFF2563EB),
    ),
    'saliva': SampleTypeStyle(
      iconAsset: 'assets/icons/sample_types/saliva.svg',
      fallbackIcon: Icons.bubble_chart_rounded,
      color: Color(0xFF0EA5E9),
    ),
    'sputum': SampleTypeStyle(
      iconAsset: 'assets/icons/sample_types/sputum.svg',
      fallbackIcon: Icons.air_rounded,
      color: Color(0xFF14B8A6),
    ),
    'csf': SampleTypeStyle(
      iconAsset: 'assets/icons/sample_types/csf.svg',
      fallbackIcon: Icons.opacity_rounded,
      color: Color(0xFF7C3AED),
    ),
  };

  static SampleTypeStyle forType(String sampleType) {
    final key = sampleType.trim().toLowerCase();
    for (final entry in _byType.entries) {
      if (key.contains(entry.key)) return entry.value;
    }
    return _default;
  }
}

/// Renders the icon for a sample type. Swap the body for SvgPicture.asset
/// once real assets are available — see note at top of file.
Widget sampleTypeIcon(String sampleType, {double size = 18}) {
  final style = SampleTypeStyles.forType(sampleType);
  return Icon(style.fallbackIcon, size: size, color: style.color);
}