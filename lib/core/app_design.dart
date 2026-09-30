import 'package:flutter/material.dart';

/// Central visual language for Schmackofatz.
///
/// Keep feature screens free from ad-hoc visual constants where possible.
/// The app should feel like one product, not twenty widgets negotiating a
/// peace treaty over border radii.
abstract final class AppDesign {
  // Brand palette
  static const primary = Color(0xFF2F8F63);
  static const primaryDark = Color(0xFF1F6948);
  static const primarySoft = Color(0xFFE5F4EB);
  static const accent = Color(0xFFFF7B5C);
  static const accentDark = Color(0xFFC95439);
  static const accentSoft = Color(0xFFFFE9E1);
  static const lilac = Color(0xFFD9C4EA);
  static const lilacSoft = Color(0xFFF1EAF7);

  static const background = Color(0xFFFFFBF7);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceSoft = Color(0xFFF7F2EC);
  static const surfaceMuted = Color(0xFFF1ECE6);
  static const sand = Color(0xFFE6DDD3);
  static const divider = Color(0xFFE7DED5);

  static const text = Color(0xFF202923);
  static const secondaryText = Color(0xFF68736D);
  static const mutedText = Color(0xFF8A938E);
  static const success = Color(0xFF2F8F63);
  static const warning = Color(0xFFE59B3F);
  static const error = Color(0xFFD95B54);

  // Compatibility aliases for existing feature screens during migration.
  static const peach = accent;
  static const peachSurface = accentSoft;
  static const secondarySurface = primarySoft;
  static const softSurface = surfaceSoft;

  // Spacing tokens
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const xxl = 24.0;
  static const xxxl = 32.0;
  static const huge = 48.0;

  // Shape tokens
  static const radiusSm = 10.0;
  static const radiusMd = 14.0;
  static const radiusLg = 18.0;
  static const radiusXl = 24.0;
  static const radiusHero = 28.0;
  static const radiusPill = 999.0;

  static const fast = Duration(milliseconds: 160);
  static const normal = Duration(milliseconds: 240);
  static const slow = Duration(milliseconds: 340);

  static ThemeData theme() {
    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
      surface: surface,
    ).copyWith(
      primary: primary,
      onPrimary: Colors.white,
      primaryContainer: primarySoft,
      onPrimaryContainer: const Color(0xFF174B33),
      secondary: accent,
      onSecondary: Colors.white,
      secondaryContainer: accentSoft,
      onSecondaryContainer: const Color(0xFF6E2B1A),
      tertiary: lilac,
      onTertiary: const Color(0xFF3D2948),
      surface: surface,
      surfaceContainerLowest: background,
      surfaceContainerLow: const Color(0xFFFFFDFB),
      surfaceContainer: surfaceSoft,
      surfaceContainerHigh: surfaceMuted,
      outline: divider,
      outlineVariant: divider,
      onSurface: text,
      onSurfaceVariant: secondaryText,
      error: error,
      onError: Colors.white,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      fontFamily: 'Inter',
      visualDensity: VisualDensity.standard,
      splashFactory: InkSparkle.splashFactory,
    );

    return base.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: text,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        toolbarHeight: 64,
        titleSpacing: 20,
        titleTextStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: 22,
          height: 1.15,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
          color: text,
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 36, height: 1.04, fontWeight: FontWeight.w700, color: text, letterSpacing: -1.3),
        displayMedium: TextStyle(fontSize: 32, height: 1.06, fontWeight: FontWeight.w700, color: text, letterSpacing: -1.0),
        displaySmall: TextStyle(fontSize: 28, height: 1.08, fontWeight: FontWeight.w700, color: text, letterSpacing: -0.7),
        headlineLarge: TextStyle(fontSize: 26, height: 1.10, fontWeight: FontWeight.w700, color: text, letterSpacing: -0.6),
        headlineMedium: TextStyle(fontSize: 23, height: 1.15, fontWeight: FontWeight.w700, color: text, letterSpacing: -0.4),
        headlineSmall: TextStyle(fontSize: 20, height: 1.18, fontWeight: FontWeight.w700, color: text),
        titleLarge: TextStyle(fontSize: 18, height: 1.2, fontWeight: FontWeight.w700, color: text),
        titleMedium: TextStyle(fontSize: 16, height: 1.25, fontWeight: FontWeight.w600, color: text),
        titleSmall: TextStyle(fontSize: 14, height: 1.25, fontWeight: FontWeight.w600, color: text),
        bodyLarge: TextStyle(fontSize: 16, height: 1.48, fontWeight: FontWeight.w400, color: text),
        bodyMedium: TextStyle(fontSize: 14, height: 1.42, fontWeight: FontWeight.w400, color: secondaryText),
        bodySmall: TextStyle(fontSize: 12, height: 1.35, fontWeight: FontWeight.w400, color: mutedText),
        labelLarge: TextStyle(fontSize: 14, height: 1.15, fontWeight: FontWeight.w600, color: text),
        labelMedium: TextStyle(fontSize: 12, height: 1.15, fontWeight: FontWeight.w600, color: secondaryText, letterSpacing: .1),
        labelSmall: TextStyle(fontSize: 11, height: 1.1, fontWeight: FontWeight.w600, color: secondaryText, letterSpacing: .2),
      ),
      cardTheme: const CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(radiusXl))),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: lg, vertical: 16),
        border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(radiusLg)), borderSide: BorderSide.none),
        enabledBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(radiusLg)), borderSide: BorderSide(color: divider)),
        focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(radiusLg)), borderSide: BorderSide(color: primary, width: 1.6)),
        errorBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(radiusLg)), borderSide: BorderSide(color: error)),
        focusedErrorBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(radiusLg)), borderSide: BorderSide(color: error, width: 1.6)),
        labelStyle: const TextStyle(color: secondaryText),
        hintStyle: const TextStyle(color: mutedText),
        prefixIconColor: secondaryText,
        suffixIconColor: secondaryText,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(44, 50),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(44, 50),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
          side: const BorderSide(color: divider),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(44, 44),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusSm)),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(44, 44),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surface,
        selectedColor: primarySoft,
        disabledColor: surfaceMuted,
        side: const BorderSide(color: divider),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusPill)),
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: text),
        secondaryLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: primaryDark),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 78,
        indicatorColor: primarySoft,
        indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusPill)),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
              fontSize: 11,
              fontWeight: states.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
              color: states.contains(WidgetState.selected) ? primaryDark : secondaryText,
            )),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF25302A),
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusHero)),
        titleTextStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: text),
        contentTextStyle: const TextStyle(fontSize: 15, height: 1.45, color: secondaryText),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: sand,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(radiusHero))),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusLg)),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(strokeWidth: 3),
      dividerTheme: const DividerThemeData(color: divider, space: 1, thickness: 1),

      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
        side: const BorderSide(color: sand, width: 1.5),
        fillColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? primary : surface),
        checkColor: WidgetStateProperty.all(Colors.white),
      ),
    );
  }
}

class BrandMark extends StatelessWidget {
  final bool compact;
  const BrandMark({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(compact ? 10 : 12),
          child: Image.asset(
            'assets/branding/app_icon.png',
            width: compact ? 32 : 38,
            height: compact ? 32 : 38,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.high,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'Schmackofatz',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: compact ? 18 : 21,
                letterSpacing: -0.5,
              ),
        ),
      ],
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? action;
  const SectionHeader({super.key, required this.title, this.subtitle, this.action});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(subtitle!, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ],
          ),
        ),
        if (action != null) action!,
      ],
    );
  }
}

class AppSurface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final bool bordered;
  const AppSurface({super.key, required this.child, this.padding = const EdgeInsets.all(AppDesign.lg), this.color, this.bordered = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? AppDesign.surface,
        borderRadius: BorderRadius.circular(AppDesign.radiusXl),
        border: bordered ? Border.all(color: AppDesign.divider) : null,
        boxShadow: bordered ? null : const [BoxShadow(color: Color(0x12000000), blurRadius: 24, offset: Offset(0, 10))],
      ),
      child: child,
    );
  }
}

class MetaPill extends StatelessWidget {
  final IconData icon;
  final String label;
  const MetaPill({super.key, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(color: AppDesign.surfaceSoft, borderRadius: BorderRadius.circular(AppDesign.radiusPill)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 16, color: AppDesign.secondaryText),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppDesign.text)),
      ]),
    );
  }
}

class AppBadge extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? foregroundColor;
  const AppBadge({super.key, required this.label, this.icon, this.backgroundColor, this.foregroundColor});

  @override
  Widget build(BuildContext context) {
    final foreground = foregroundColor ?? AppDesign.primaryDark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: backgroundColor ?? AppDesign.primarySoft, borderRadius: BorderRadius.circular(AppDesign.radiusPill)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[Icon(icon, size: 14, color: foreground), const SizedBox(width: 5)],
        Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: foreground)),
      ]),
    );
  }
}
