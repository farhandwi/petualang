import 'package:flutter/material.dart';

/// Centralised responsive breakpoints + helpers for tablet & desktop layouts.
///
/// Breakpoints follow common corporate web conventions so the app scales
/// gracefully from phones to widescreen monitors.
class Breakpoints {
  Breakpoints._();

  /// Phones in portrait (and small foldables).
  static const double mobile = 600;

  /// Tablets / small landscape phones.
  static const double tablet = 1024;

  /// Standard desktop / laptop.
  static const double desktop = 1440;

  /// Max readable width for centred content on very wide screens.
  static const double maxContentWidth = 1280;

  /// Max width for forms (login, edit profile, booking form, ...).
  static const double maxFormWidth = 560;

  /// Max width for narrow article / reading layouts.
  static const double maxReadingWidth = 760;
}

enum ScreenType { mobile, tablet, desktop, large }

extension ResponsiveContext on BuildContext {
  Size get _screen => MediaQuery.sizeOf(this);

  double get screenWidth => _screen.width;
  double get screenHeight => _screen.height;

  ScreenType get screenType {
    final w = screenWidth;
    if (w < Breakpoints.mobile) return ScreenType.mobile;
    if (w < Breakpoints.tablet) return ScreenType.tablet;
    if (w < Breakpoints.desktop) return ScreenType.desktop;
    return ScreenType.large;
  }

  bool get isMobile => screenType == ScreenType.mobile;
  bool get isTablet => screenType == ScreenType.tablet;
  bool get isDesktop =>
      screenType == ScreenType.desktop || screenType == ScreenType.large;
  bool get isLarge => screenType == ScreenType.large;

  /// Convenient short-circuit: tablet OR desktop.
  bool get isWide => !isMobile;

  /// Pick a value per screen size. `tablet` and `desktop`/`large` fall back
  /// to the next-smaller value when omitted.
  T responsive<T>({
    required T mobile,
    T? tablet,
    T? desktop,
    T? large,
  }) {
    switch (screenType) {
      case ScreenType.mobile:
        return mobile;
      case ScreenType.tablet:
        return tablet ?? mobile;
      case ScreenType.desktop:
        return desktop ?? tablet ?? mobile;
      case ScreenType.large:
        return large ?? desktop ?? tablet ?? mobile;
    }
  }

  /// Standard horizontal page padding that breathes on wide screens.
  EdgeInsets get pagePadding => EdgeInsets.symmetric(
        horizontal: responsive<double>(
          mobile: 16,
          tablet: 24,
          desktop: 32,
          large: 40,
        ),
        vertical: responsive<double>(mobile: 12, tablet: 16, desktop: 20),
      );

  /// Number of grid columns suitable for card lists (mountains, communities…).
  int gridColumns({
    int mobile = 1,
    int tablet = 2,
    int desktop = 3,
    int large = 4,
  }) =>
      responsive<int>(
        mobile: mobile,
        tablet: tablet,
        desktop: desktop,
        large: large,
      );

  /// Number of columns appropriate for compact cards (vendors, services…).
  int compactGridColumns() => gridColumns(
        mobile: 2,
        tablet: 3,
        desktop: 4,
        large: 5,
      );
}

/// Constrains its child to a max width and centres it on wide screens.
///
/// Use as the outermost child of a `Scaffold.body` so phone layouts are
/// untouched while desktop layouts stop stretching past readable widths.
class ContentConstrained extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;
  final Alignment alignment;

  const ContentConstrained({
    super.key,
    required this.child,
    this.maxWidth = Breakpoints.maxContentWidth,
    this.padding,
    this.alignment = Alignment.topCenter,
  });

  /// Preset for forms (login, register, edit profile, …).
  const ContentConstrained.form({
    super.key,
    required this.child,
    this.padding,
  })  : maxWidth = Breakpoints.maxFormWidth,
        alignment = Alignment.topCenter;

  /// Preset for article / detail screens.
  const ContentConstrained.reading({
    super.key,
    required this.child,
    this.padding,
  })  : maxWidth = Breakpoints.maxReadingWidth,
        alignment = Alignment.topCenter;

  @override
  Widget build(BuildContext context) {
    Widget content = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: child,
    );
    if (padding != null) {
      content = Padding(padding: padding!, child: content);
    }
    return Align(alignment: alignment, child: content);
  }
}

/// Builds a responsive grid with a fixed number of columns determined by
/// the current screen type. Children take equal width.
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final int? mobileColumns;
  final int? tabletColumns;
  final int? desktopColumns;
  final int? largeColumns;
  final double spacing;
  final double runSpacing;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.mobileColumns,
    this.tabletColumns,
    this.desktopColumns,
    this.largeColumns,
    this.spacing = 16,
    this.runSpacing = 16,
  });

  @override
  Widget build(BuildContext context) {
    final cols = context.gridColumns(
      mobile: mobileColumns ?? 1,
      tablet: tabletColumns ?? 2,
      desktop: desktopColumns ?? 3,
      large: largeColumns ?? 4,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalSpacing = spacing * (cols - 1);
        final itemWidth = (constraints.maxWidth - totalSpacing) / cols;
        return Wrap(
          spacing: spacing,
          runSpacing: runSpacing,
          children: [
            for (final child in children)
              SizedBox(width: itemWidth, child: child),
          ],
        );
      },
    );
  }
}
