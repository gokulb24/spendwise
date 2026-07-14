import 'package:flutter/material.dart';

/// Brand seed — a calm finance teal/blue. Material 3 derives the whole scheme
/// from this when the device has no dynamic color.
const Color kBrandSeed = Color(0xFF2E6F95);

/// Semantic colors (income/expense/warning) that adapt to light & dark.
/// Exposed as a [ThemeExtension] so widgets read them from the active theme.
@immutable
class AppSemantic extends ThemeExtension<AppSemantic> {
  final Color positive; // income / under budget / savings
  final Color negative; // expense / over budget
  final Color warning; // nearing budget
  final Color positiveContainer;
  final Color negativeContainer;
  final Color warningContainer;

  const AppSemantic({
    required this.positive,
    required this.negative,
    required this.warning,
    required this.positiveContainer,
    required this.negativeContainer,
    required this.warningContainer,
  });

  static const light = AppSemantic(
    positive: Color(0xFF2E7D32),
    negative: Color(0xFFC62828),
    warning: Color(0xFF9A6B00),
    positiveContainer: Color(0xFFE6F4EA),
    negativeContainer: Color(0xFFFDE2E1),
    warningContainer: Color(0xFFFDF3D6),
  );

  static const dark = AppSemantic(
    positive: Color(0xFF7CD98A),
    negative: Color(0xFFFF8A80),
    warning: Color(0xFFFFCA5F),
    positiveContainer: Color(0xFF17361E),
    negativeContainer: Color(0xFF3A1513),
    warningContainer: Color(0xFF3A2E10),
  );

  @override
  AppSemantic copyWith({
    Color? positive,
    Color? negative,
    Color? warning,
    Color? positiveContainer,
    Color? negativeContainer,
    Color? warningContainer,
  }) =>
      AppSemantic(
        positive: positive ?? this.positive,
        negative: negative ?? this.negative,
        warning: warning ?? this.warning,
        positiveContainer: positiveContainer ?? this.positiveContainer,
        negativeContainer: negativeContainer ?? this.negativeContainer,
        warningContainer: warningContainer ?? this.warningContainer,
      );

  @override
  AppSemantic lerp(ThemeExtension<AppSemantic>? other, double t) {
    if (other is! AppSemantic) return this;
    return AppSemantic(
      positive: Color.lerp(positive, other.positive, t)!,
      negative: Color.lerp(negative, other.negative, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      positiveContainer: Color.lerp(positiveContainer, other.positiveContainer, t)!,
      negativeContainer: Color.lerp(negativeContainer, other.negativeContainer, t)!,
      warningContainer: Color.lerp(warningContainer, other.warningContainer, t)!,
    );
  }
}

/// Convenience accessors used throughout the UI.
extension AppThemeX on BuildContext {
  ColorScheme get scheme => Theme.of(this).colorScheme;
  TextTheme get texts => Theme.of(this).textTheme;
  AppSemantic get semantic =>
      Theme.of(this).extension<AppSemantic>() ?? AppSemantic.light;
}

ThemeData buildAppTheme(ColorScheme scheme) {
  final isDark = scheme.brightness == Brightness.dark;
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    extensions: [isDark ? AppSemantic.dark : AppSemantic.light],
    splashFactory: InkSparkle.splashFactory,
    cardTheme: CardThemeData(
      elevation: 0,
      color: scheme.surfaceContainerLow,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: EdgeInsets.zero,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 2,
      centerTitle: false,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: scheme.surfaceContainer,
      indicatorColor: scheme.secondaryContainer,
      elevation: 3,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      height: 72,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(64, 50),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(64, 50),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
      isDense: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: scheme.primary, width: 2),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      side: BorderSide(color: scheme.outlineVariant),
    ),
    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      showDragHandle: true,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    dividerTheme: DividerThemeData(
      color: scheme.outlineVariant,
      space: 1,
      thickness: 1,
    ),
  );
}
