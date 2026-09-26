/// RYVE Design System — Spacing Constants
///
/// All spacing follows an 8-point grid with a 4px base.
/// Use these constants exclusively — never hardcode spacing values.
abstract final class AppSpacing {
  /// 4px — micro gap, icon padding
  static const double xs = 4.0;

  /// 8px — tight spacing, inline gaps
  static const double sm = 8.0;

  /// 12px — between related items
  static const double md12 = 12.0;

  /// 16px — standard section padding
  static const double md = 16.0;

  /// 20px — comfortable gap
  static const double md20 = 20.0;

  /// 24px — generous section spacing
  static const double lg = 24.0;

  /// 32px — between major sections
  static const double xl = 32.0;

  /// 40px — hero section padding
  static const double xl40 = 40.0;

  /// 48px — screen-level top padding
  static const double xxl = 48.0;

  /// 64px — large decorative spacing
  static const double xxxl = 64.0;

  // ─── Screen Edge Padding ─────────────────────────────────────────────────
  /// Horizontal screen edge padding
  static const double screenH = 20.0;

  /// Vertical screen top padding (below status bar)
  static const double screenV = 16.0;

  // ─── Border Radii ────────────────────────────────────────────────────────
  /// Small radius — chips, badges
  static const double radiusSm = 8.0;

  /// Default radius — input fields, list items
  static const double radiusMd = 12.0;

  /// Card radius
  static const double radiusLg = 16.0;

  /// Bottom sheet top radius
  static const double radiusXl = 24.0;

  /// Full pill radius
  static const double radiusPill = 100.0;

  // ─── Bottom Navigation ───────────────────────────────────────────────────
  /// Bottom nav height
  static const double bottomNavHeight = 60.0;

  /// Bottom nav icon size
  static const double bottomNavIconSize = 22.0;

  // ─── Touch Targets ───────────────────────────────────────────────────────
  /// Minimum touch target per accessibility guidelines
  static const double minTouchTarget = 44.0;

  // ─── Icon Sizes ──────────────────────────────────────────────────────────
  static const double iconXs = 14.0;
  static const double iconSm = 16.0;
  static const double iconMd = 20.0;
  static const double iconLg = 24.0;
  static const double iconXl = 32.0;

  // ─── Category Icon Container ─────────────────────────────────────────────
  static const double categoryIconSize = 44.0;
  static const double transactionIconSize = 40.0;
}
