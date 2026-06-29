// lib/widgets/app_scaffold.dart
// ─────────────────────────────────────────────────────────────
// Standardized scaffold for every screen.
//
// Wires together:
//  • Forced RTL Directionality (the app is locked to ar/ku).
//  • [BrandedAppBar] with consistent gradient + leading icon.
//  • [CustomDrawer] on the start side — in this RTL app, that
//    places the hamburger AND drawer on the RIGHT for every screen.
//
// Use instead of bare Scaffold + AppBar for consistency.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import 'branded_app_bar.dart';
import 'custom_drawer.dart';

class AppScaffold extends StatelessWidget {
  /// Plain text title for the AppBar. Mutually exclusive with [titleWidget].
  final String? title;

  /// Custom title widget (e.g. an in-AppBar search field).
  final Widget? titleWidget;

  /// Trailing AppBar actions. Wrap each in [BrandedAppBarAction] for
  /// the standard pill style.
  final List<Widget>? actions;

  /// Override the leading widget. Defaults to a back button (when the
  /// route can pop) or a hamburger (when [showDrawer] is true).
  final Widget? leading;

  /// Whether to attach the shared [CustomDrawer]. Defaults to true.
  /// Set to false for screens like login/splash.
  final bool showDrawer;

  /// When true, the AppBar leading is ALWAYS the hamburger menu —
  /// never the back button — even if the navigation stack can pop.
  /// Use for root/home pages like the dashboard so the user can't
  /// accidentally navigate "back" out of the app's home.
  final bool isHomePage;

  /// Page body.
  final Widget body;

  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Color? backgroundColor;
  final bool extendBodyBehindAppBar;
  final bool resizeToAvoidBottomInset;
  final PreferredSizeWidget? appBarBottom;

  const AppScaffold({
    Key? key,
    this.title,
    this.titleWidget,
    this.actions,
    this.leading,
    this.showDrawer = true,
    this.isHomePage = false,
    required this.body,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.backgroundColor,
    this.extendBodyBehindAppBar = false,
    this.resizeToAvoidBottomInset = true,
    this.appBarBottom,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: backgroundColor ?? AppTheme.background,
        extendBodyBehindAppBar: extendBodyBehindAppBar,
        resizeToAvoidBottomInset: resizeToAvoidBottomInset,
        appBar: BrandedAppBar(
          title: title,
          titleWidget: titleWidget,
          actions: actions,
          leading: leading,
          isHomePage: isHomePage,
          bottom: appBarBottom,
        ),
        // Always `drawer:` (start side) — in RTL this puts the
        // hamburger AND drawer on the RIGHT for every screen.
        drawer: showDrawer ? const CustomDrawer() : null,
        body: body,
        bottomNavigationBar: bottomNavigationBar,
        floatingActionButton: floatingActionButton,
        floatingActionButtonLocation: floatingActionButtonLocation,
      ),
    );
  }
}
