import 'package:flutter/material.dart';
import 'colors.dart';

/// Unified App Theme Constants
/// This file defines consistent styling throughout the app
/// All screens should use these constants for a cohesive look

class AppSpacing {
  // Padding
  static const double paddingXS = 4.0;
  static const double paddingSM = 8.0;
  static const double paddingMD = 12.0;
  static const double paddingLG = 16.0;
  static const double paddingXL = 20.0;
  static const double paddingXXL = 24.0;

  // Screen padding
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(horizontal: 20);
  static const EdgeInsets screenPaddingAll = EdgeInsets.all(20);
}

class AppRadius {
  static const double radiusXS = 4.0;
  static const double radiusSM = 8.0;
  static const double radiusMD = 12.0;
  static const double radiusLG = 16.0;
  static const double radiusXL = 20.0;
  static const double radiusXXL = 24.0;

  // Border Radius shortcuts
  static BorderRadius get borderRadiusSM => BorderRadius.circular(radiusSM);
  static BorderRadius get borderRadiusMD => BorderRadius.circular(radiusMD);
  static BorderRadius get borderRadiusLG => BorderRadius.circular(radiusLG);
  static BorderRadius get borderRadiusXL => BorderRadius.circular(radiusXL);
  static BorderRadius get borderRadiusXXL => BorderRadius.circular(radiusXXL);

  // Sheet radius
  static BorderRadius get sheetRadius =>
      const BorderRadius.vertical(top: Radius.circular(20));
}

class AppTextStyles {
  // Headers
  static const TextStyle screenTitle = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 24,
    fontWeight: FontWeight.bold,
    letterSpacing: 1.5,
  );

  static const TextStyle sectionHeader = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 18,
    fontWeight: FontWeight.bold,
  );

  static TextStyle get screenSubtitle => TextStyle(
    color: Colors.grey.shade500,
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );

  // Body text
  static const TextStyle bodyLarge = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 16,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle bodyMedium = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 14,
    fontWeight: FontWeight.normal,
  );

  static const TextStyle bodySmall = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 13,
    fontWeight: FontWeight.normal,
  );

  // Labels
  static TextStyle get labelLarge => TextStyle(
    color: Colors.grey.shade500,
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );

  static TextStyle get labelMedium => TextStyle(
    color: Colors.grey.shade500,
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );

  static TextStyle get labelSmall => TextStyle(
    color: Colors.grey.shade600,
    fontSize: 11,
    fontWeight: FontWeight.w500,
  );

  // Section labels (like "DEADLINES", "GOALS", etc.)
  static TextStyle get sectionLabel => TextStyle(
    color: Colors.grey.shade500,
    fontSize: 12,
    fontWeight: FontWeight.bold,
    letterSpacing: 1.5,
  );

  // Card titles
  static const TextStyle cardTitle = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 15,
    fontWeight: FontWeight.w600,
  );

  static TextStyle get cardSubtitle =>
      TextStyle(color: Colors.grey.shade500, fontSize: 12);

  // Dialog/Sheet titles
  static const TextStyle dialogTitle = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 18,
    fontWeight: FontWeight.bold,
  );

  // Button text
  static const TextStyle buttonPrimary = TextStyle(
    fontWeight: FontWeight.bold,
    letterSpacing: 1,
    fontSize: 14,
  );

  static TextStyle get buttonSecondary => TextStyle(
    color: Colors.grey.shade500,
    fontWeight: FontWeight.w600,
    fontSize: 12,
  );

  // Chip/Tag text
  static const TextStyle chipText = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
  );

  // Time/Duration display
  static TextStyle timerDisplay(Color color) => TextStyle(
    color: color,
    fontSize: 44,
    fontWeight: FontWeight.w200,
    fontFeatures: const [FontFeature.tabularFigures()],
    letterSpacing: 2,
  );
}

class AppDecorations {
  // Card decoration
  static BoxDecoration card({
    Color? borderColor,
    bool hasShadow = false,
    Color? shadowColor,
  }) {
    return BoxDecoration(
      color: Colors.grey.shade900,
      borderRadius: AppRadius.borderRadiusMD,
      border: Border.all(color: borderColor ?? Colors.white.withOpacity(0.05)),
      boxShadow: hasShadow
          ? [
              BoxShadow(
                color: shadowColor ?? Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ]
          : null,
    );
  }

  // Gradient card
  static BoxDecoration gradientCard({Color? accentColor}) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Colors.grey.shade900, Colors.grey.shade900.withOpacity(0.8)],
      ),
      borderRadius: AppRadius.borderRadiusLG,
      border: Border.all(
        color: accentColor?.withOpacity(0.2) ?? Colors.white.withOpacity(0.05),
      ),
    );
  }

  // Input field decoration
  static InputDecoration inputDecoration(String hint, {IconData? prefixIcon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade600),
      filled: true,
      fillColor: Colors.grey.shade800,
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, color: Colors.grey.shade600)
          : null,
      border: OutlineInputBorder(
        borderRadius: AppRadius.borderRadiusMD,
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  // Sheet/Modal decoration
  static BoxDecoration sheetDecoration() {
    return BoxDecoration(
      color: Colors.grey.shade900,
      borderRadius: AppRadius.sheetRadius,
    );
  }

  // Chip decoration
  static BoxDecoration chipDecoration({
    required bool isSelected,
    Color? selectedColor,
  }) {
    final color = selectedColor ?? AppColors.accent;
    return BoxDecoration(
      color: isSelected ? color.withOpacity(0.15) : Colors.grey.shade800,
      borderRadius: AppRadius.borderRadiusSM,
      border: Border.all(color: isSelected ? color : Colors.grey.shade700),
    );
  }

  // Color selector dot
  static BoxDecoration colorDot(Color color, bool isSelected) {
    return BoxDecoration(
      color: color,
      shape: BoxShape.circle,
      border: isSelected ? Border.all(color: Colors.white, width: 2) : null,
      boxShadow: isSelected
          ? [BoxShadow(color: color.withOpacity(0.4), blurRadius: 8)]
          : null,
    );
  }
}

class AppButtons {
  // Primary button style
  static ButtonStyle primaryButton() {
    return ElevatedButton.styleFrom(
      backgroundColor: AppColors.accent,
      foregroundColor: Colors.black,
      padding: const EdgeInsets.symmetric(vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.borderRadiusMD),
    );
  }

  // Secondary button style
  static ButtonStyle secondaryButton() {
    return ElevatedButton.styleFrom(
      backgroundColor: Colors.grey.shade800,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.borderRadiusMD),
    );
  }

  // Danger button style
  static ButtonStyle dangerButton() {
    return ElevatedButton.styleFrom(
      backgroundColor: Colors.red.shade700,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.borderRadiusMD),
    );
  }
}

// Helper extensions
extension ColorOpacity on Color {
  Color get subtle => withOpacity(0.15);
  Color get medium => withOpacity(0.3);
  Color get strong => withOpacity(0.6);
}
