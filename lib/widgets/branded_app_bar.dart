// lib/widgets/branded_app_bar.dart
// ─────────────────────────────────────────────────────────────
// Standardized AppBar used across every screen.
//
// Design principles:
//  • Always uses the brand gradient background.
//  • Title centered, white, NotoKufi heading style.
//  • Leading position (right side in this RTL app) is RESERVED
//    for the hamburger whenever the parent Scaffold has a drawer
//    — so the menu button is in the same place on every screen.
//  • Back button moves to the trailing actions area (left side
//    in RTL) when both a drawer AND a popable route exist, so
//    the user can still navigate back without losing the menu.
//  • Pages without a drawer fall back to a leading back button.
//  • Optional actions appear after the back button.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

import '../core/app_theme.dart';

class BrandedAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// Plain text title. Mutually exclusive with [titleWidget].
  final String? title;

  /// Custom title widget (e.g. an in-AppBar search field).
  /// If provided, overrides [title].
  final Widget? titleWidget;

  /// Optional override for the leading widget.
  final Widget? leading;

  /// Trailing actions. The standardized back button is automatically
  /// prepended on non-home pages that have a drawer + popable route.
  /// Wrap each in [BrandedAppBarAction] for the standard pill style.
  final List<Widget>? actions;

  /// Hide the leading widget entirely (e.g. login/splash screens).
  final bool automaticallyImplyLeading;

  /// When true, no back button is shown anywhere — the page is the
  /// app's home and the user shouldn't be offered a way out via "back".
  /// Use for root/home pages like the dashboard.
  final bool isHomePage;

  /// Optional bottom widget (e.g. TabBar).
  final PreferredSizeWidget? bottom;

  const BrandedAppBar({
    Key? key,
    this.title,
    this.titleWidget,
    this.leading,
    this.actions,
    this.automaticallyImplyLeading = true,
    this.isHomePage = false,
    this.bottom,
  })  : assert(title == null || titleWidget == null,
            'Provide either title OR titleWidget, not both.'),
        super(key: key);

  @override
  Size get preferredSize => Size.fromHeight(
        AppTheme.appBarHeight + (bottom?.preferredSize.height ?? 0),
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.appBarGradient,
        boxShadow: AppTheme.appBarShadow,
      ),
      child: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        leading: automaticallyImplyLeading
            ? (leading ?? const _LeadingButton())
            : leading,
        title: titleWidget ??
            (title != null
                ? Text(
                    title!,
                    style: AppTheme.headingLarge,
                    overflow: TextOverflow.ellipsis,
                  )
                : null),
        centerTitle: true,
        actions: [
          if (!isHomePage) const _ActionBackButton(),
          ...?actions,
        ],
        bottom: bottom,
        iconTheme: const IconThemeData(color: Colors.white, size: 22),
        actionsIconTheme: const IconThemeData(color: Colors.white, size: 22),
      ),
    );
  }
}

/// Leading button: hamburger when the Scaffold has a drawer (so the
/// menu is always in the same place); otherwise a back button when
/// the route can pop; otherwise nothing.
class _LeadingButton extends StatelessWidget {
  const _LeadingButton();

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (ctx) {
        final hasDrawer = Scaffold.maybeOf(ctx)?.hasDrawer ?? false;
        final canPop = Navigator.of(ctx).canPop();

        if (hasDrawer) {
          return _IconPill(
            icon: Icons.menu_rounded,
            tooltip: MaterialLocalizations.of(ctx).openAppDrawerTooltip,
            onTap: () => Scaffold.of(ctx).openDrawer(),
          );
        }
        if (canPop) {
          return _IconPill(
            icon: Icons.arrow_back_ios_new_rounded,
            tooltip: MaterialLocalizations.of(ctx).backButtonTooltip,
            onTap: () => Navigator.of(ctx).maybePop(),
            forceLtr: true,
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

/// Action-area back button: rendered only when the leading slot is
/// taken by the hamburger AND the route can pop. In this RTL app,
/// `actions:` ends up on the LEFT side of the AppBar — exactly where
/// the user expects the back button on a non-home page.
class _ActionBackButton extends StatelessWidget {
  const _ActionBackButton();

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (ctx) {
        final hasDrawer = Scaffold.maybeOf(ctx)?.hasDrawer ?? false;
        final canPop = Navigator.of(ctx).canPop();

        if (!(hasDrawer && canPop)) return const SizedBox.shrink();

        return BrandedAppBarAction(
          icon: Icons.arrow_back_ios_new_rounded,
          tooltip: MaterialLocalizations.of(ctx).backButtonTooltip,
          onPressed: () => Navigator.of(ctx).maybePop(),
          forceLtr: true,
        );
      },
    );
  }
}

/// Trailing-action button with the standard pill style.
/// Use this in [BrandedAppBar.actions] for visual consistency.
class BrandedAppBarAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;

  /// When true, the icon is rendered with a forced LTR text direction
  /// so it doesn't auto-flip in RTL — useful for back arrows where the
  /// arrow's visual direction should match the button's screen position
  /// rather than the language's reading direction.
  final bool forceLtr;

  const BrandedAppBarAction({
    Key? key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.forceLtr = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6, left: 6),
      child: _IconPill(
        icon: icon,
        onTap: onPressed,
        tooltip: tooltip,
        forceLtr: forceLtr,
      ),
    );
  }
}

/// Internal — the rounded square white-on-gradient icon button used
/// for both leading and action icons.
class _IconPill extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;
  final bool forceLtr;

  const _IconPill({
    required this.icon,
    required this.onTap,
    this.tooltip,
    this.forceLtr = false,
  });

  @override
  Widget build(BuildContext context) {
    final button = Padding(
      padding: const EdgeInsets.all(8),
      child: Material(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          onTap: onTap,
          child: SizedBox(
            width: 36,
            height: 36,
            child: Icon(
              icon,
              color: Colors.white,
              size: 20,
              textDirection: forceLtr ? TextDirection.ltr : null,
            ),
          ),
        ),
      ),
    );

    if (tooltip == null) return button;
    return Tooltip(message: tooltip!, child: button);
  }
}
