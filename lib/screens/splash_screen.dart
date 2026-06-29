// lib/screens/splash_screen.dart
// ─────────────────────────────────────────────────────────────
// Shows on EVERY app launch / restart.
// Flow:
//   1. Logo + text animation always plays (~1.5s)
//   2. Language picker is ALWAYS shown — user taps Kurdish or
//      Arabic to enter the app. The previously-chosen language
//      is highlighted as the default; on first launch, Kurdish
//      is pre-highlighted.
// ─────────────────────────────────────────────────────────────

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/app_logger.dart';
import '../core/app_theme.dart';
import '../main.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // ── Animation controllers ────────────────────────────────
  late final AnimationController _bgController;
  late final AnimationController _logoController;
  late final AnimationController _textController;
  late final AnimationController _langController;
  late final AnimationController _dotsController;

  // ── Animations ────────────────────────────────────────────
  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _textOpacity;
  late final Animation<Offset> _textSlide;
  late final Animation<double> _taglineOpacity;
  late final Animation<double> _langOpacity;
  late final Animation<Offset> _langSlide;
  late final Animation<double> _ring1Scale;
  late final Animation<double> _ring2Scale;
  late final Animation<double> _floatOpacity;

  bool _showLanguagePicker = false;
  bool _navigating = false; // prevent double-navigation
  // Default-highlighted language in the picker. Kurdish on first
  // launch, otherwise whatever the user picked last time.
  String _defaultLang = 'ku';

  @override
  void initState() {
    super.initState();
    AppLogger.info('SplashScreen init', tag: 'SPLASH');
    _setupAnimations();
    _runSequence();
  }

  // ── Setup all animations ─────────────────────────────────

  void _setupAnimations() {
    // Background rings — slow continuous pulse
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _ring1Scale = Tween<double>(begin: 1.0, end: 1.12).animate(
        CurvedAnimation(parent: _bgController, curve: Curves.easeInOut));

    _ring2Scale = Tween<double>(begin: 1.05, end: 0.95).animate(CurvedAnimation(
        parent: _bgController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeInOut)));

    // Logo — spring pop-in
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );
    _logoScale = Tween<double>(begin: 0.3, end: 1.0).animate(
        CurvedAnimation(parent: _logoController, curve: Curves.easeOutBack));
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut)));
    _floatOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.6, 1.0, curve: Curves.easeOut)));

    // Text — fade + slide up
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _textController, curve: Curves.easeOut));
    _textSlide = Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero)
        .animate(
            CurvedAnimation(parent: _textController, curve: Curves.easeOut));
    _taglineOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
            parent: _textController,
            curve: const Interval(0.5, 1.0, curve: Curves.easeOut)));

    // Language buttons — slide up
    _langController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _langOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _langController, curve: Curves.easeOut));
    _langSlide = Tween<Offset>(begin: const Offset(0, 0.6), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _langController, curve: Curves.easeOutCubic));

    // Loading dots — staggered blink
    _dotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  // ── Main sequence ────────────────────────────────────────

  Future<void> _runSequence() async {
    // Step 1: logo springs in
    await Future.delayed(const Duration(milliseconds: 250));
    if (!mounted) return;
    _logoController.forward();

    // Step 2: text fades up
    await Future.delayed(const Duration(milliseconds: 550));
    if (!mounted) return;
    _textController.forward();

    // Step 3: wait minimum splash time so user sees the animation
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;

    // Step 4: read previously-saved language (if any) and pre-apply it
    // so the picker title etc. render in the right language. The user
    // STILL must tap to confirm — we always show the picker.
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('selectedLanguage');
    final defaultLang =
        (saved != null && saved.isNotEmpty) ? saved : 'ku';
    AppLogger.info('Saved language: ${saved ?? "none"} — default: $defaultLang',
        tag: 'SPLASH');

    if (!mounted) return;

    // Apply the default language eagerly so any provider listeners
    // (like the dashboard) are already in sync once the user taps.
    await Provider.of<LocaleProvider>(context, listen: false).setLocale(
      defaultLang == 'ar' ? const Locale('ar', '') : const Locale('ku', 'IQ'),
    );

    if (!mounted) return;
    setState(() {
      _defaultLang = defaultLang;
      _showLanguagePicker = true;
    });
    _langController.forward();
  }

  // ── Language selection ───────────────────────────────────

  Future<void> _setLanguage(String code) async {
    if (_navigating) return;
    _navigating = true;
    AppLogger.info('Language selected: $code', tag: 'SPLASH');

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedLanguage', code);

    if (!mounted) return;
    await Provider.of<LocaleProvider>(context, listen: false).setLocale(
        code == 'ar' ? const Locale('ar', '') : const Locale('ku', 'IQ'));

    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/dashboard');
  }

  @override
  void dispose() {
    _bgController.dispose();
    _logoController.dispose();
    _textController.dispose();
    _langController.dispose();
    _dotsController.dispose();
    super.dispose();
  }

  // ── BUILD ────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppTheme.primary,
      body: Stack(
        children: [
          // Layer 1 — animated background rings
          _buildBackgroundRings(size),

          // Layer 2 — floating decoration shapes
          FadeTransition(
            opacity: _floatOpacity,
            child: _buildFloatingShapes(size),
          ),

          // Layer 3 — main content
          // Use Stack so the center content is truly centered on the full
          // screen and the branding sits absolutely at the bottom.
          Positioned.fill(
            child: SafeArea(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // ── Centered content ─────────────────────
                  Center(
                    child: SingleChildScrollView(
                      physics: const NeverScrollableScrollPhysics(),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Logo
                          ScaleTransition(
                            scale: _logoScale,
                            child: FadeTransition(
                              opacity: _logoOpacity,
                              child: _buildLogo(),
                            ),
                          ),
                          const SizedBox(height: 32),

                          // App name
                          SlideTransition(
                            position: _textSlide,
                            child: FadeTransition(
                              opacity: _textOpacity,
                              child: _buildAppName(),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Tagline + divider
                          FadeTransition(
                            opacity: _taglineOpacity,
                            child: _buildTagline(),
                          ),
                          const SizedBox(height: 52),

                          // Language picker OR loading dots
                          if (_showLanguagePicker)
                            SlideTransition(
                              position: _langSlide,
                              child: FadeTransition(
                                opacity: _langOpacity,
                                child: _buildLanguagePicker(),
                              ),
                            )
                          else
                            FadeTransition(
                              opacity: _textOpacity,
                              child: _buildLoadingDots(),
                            ),
                        ],
                      ),
                    ),
                  ),

                  // ── Bottom branding — absolutely positioned ──
                  Positioned(
                    bottom: 20,
                    left: 0,
                    right: 0,
                    child: FadeTransition(
                      opacity: _taglineOpacity,
                      child: Text(
                        'Heama Soft © 2025',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'NotoKufi',
                          fontSize: 11,
                          color: Colors.white.withOpacity(0.22),
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Background rings ─────────────────────────────────────

  Widget _buildBackgroundRings(Size size) {
    return Stack(children: [
      // Top-right large ring
      Positioned(
        top: -size.width * 0.28,
        right: -size.width * 0.18,
        child: AnimatedBuilder(
          animation: _ring1Scale,
          builder: (_, __) => Transform.scale(
            scale: _ring1Scale.value,
            child: Container(
              width: size.width * 0.88,
              height: size.width * 0.88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border:
                    Border.all(color: Colors.white.withOpacity(0.08), width: 1),
              ),
            ),
          ),
        ),
      ),
      // Bottom-left ring
      Positioned(
        bottom: -size.width * 0.22,
        left: -size.width * 0.14,
        child: AnimatedBuilder(
          animation: _ring2Scale,
          builder: (_, __) => Transform.scale(
            scale: _ring2Scale.value,
            child: Container(
              width: size.width * 0.72,
              height: size.width * 0.72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border:
                    Border.all(color: Colors.white.withOpacity(0.07), width: 1),
              ),
            ),
          ),
        ),
      ),
      // Accent glow top-right
      Positioned(
        top: -size.width * 0.04,
        right: -size.width * 0.06,
        child: Container(
          width: size.width * 0.52,
          height: size.width * 0.52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.accent.withOpacity(0.13),
          ),
        ),
      ),
      // Accent glow bottom-left
      Positioned(
        bottom: size.height * 0.12,
        left: -size.width * 0.08,
        child: Container(
          width: size.width * 0.38,
          height: size.width * 0.38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.04),
          ),
        ),
      ),
    ]);
  }

  // ── Floating shapes ──────────────────────────────────────

  Widget _buildFloatingShapes(Size size) {
    return Stack(children: [
      Positioned(
        top: size.height * 0.11,
        left: 26,
        child: Transform.rotate(
          angle: math.pi / 7,
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(10),
              border:
                  Border.all(color: Colors.white.withOpacity(0.10), width: 1),
            ),
          ),
        ),
      ),
      Positioned(
        top: size.height * 0.14,
        right: 30,
        child: Transform.rotate(
          angle: -math.pi / 9,
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: AppTheme.accent.withOpacity(0.20),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
      ),
      Positioned(
        top: size.height * 0.43,
        left: 20,
        child: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.12),
          ),
        ),
      ),
      Positioned(
        bottom: size.height * 0.20,
        right: 22,
        child: Transform.rotate(
          angle: math.pi / 5,
          child: Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(5),
            ),
          ),
        ),
      ),
    ]);
  }

  // ── Logo card ────────────────────────────────────────────

  Widget _buildLogo() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.13),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.22), width: 1.5),
      ),
      child: Center(
        child: Container(
          width: 62,
          height: 62,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(
              'assets/logo.png',
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Center(
                child:
                    Icon(Icons.work_rounded, size: 34, color: AppTheme.primary),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── App name ─────────────────────────────────────────────

  Widget _buildAppName() {
    return const Text(
      'هاریکار',
      style: TextStyle(
        fontFamily: 'NotoKufi',
        fontSize: 38,
        fontWeight: FontWeight.w900,
        color: Colors.white,
        letterSpacing: 1.8,
        height: 1.1,
      ),
    );
  }

  // ── Tagline + divider ────────────────────────────────────

  Widget _buildTagline() {
    return Column(children: [
      Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 40, height: 1, color: Colors.white.withOpacity(0.22)),
        const SizedBox(width: 8),
        Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.42),
          ),
        ),
        const SizedBox(width: 8),
        Container(width: 40, height: 1, color: Colors.white.withOpacity(0.22)),
      ]),
      const SizedBox(height: 12),
      Text(
        'ئاسانکاری و خێرای دکاری دا',
        style: TextStyle(
          fontFamily: 'NotoKufi',
          fontSize: 14,
          color: Colors.white.withOpacity(0.58),
          letterSpacing: 0.3,
          height: 1.5,
        ),
      ),
    ]);
  }

  // ── Language picker ──────────────────────────────────────

  Widget _buildLanguagePicker() {
    // Bilingual prompt — both languages, since user hasn't picked yet.
    return Column(children: [
      Text(
        'زمانێ خۆ هەلبژێرە  •  اختر اللغة',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'NotoKufi',
          fontSize: 13,
          color: Colors.white.withOpacity(0.55),
        ),
      ),
      const SizedBox(height: 18),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _langButton('کوردی', 'ku'),
          const SizedBox(width: 16),
          _langButton('العربية', 'ar'),
        ],
      ),
    ]);
  }

  Widget _langButton(String label, String code) {
    final bool isDefault = _defaultLang == code;

    return GestureDetector(
      onTap: () => _setLanguage(code),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 13),
        decoration: BoxDecoration(
          color:
              isDefault ? Colors.white : Colors.white.withOpacity(0.10),
          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          border: Border.all(
            color: isDefault ? Colors.white : Colors.white.withOpacity(0.35),
            width: 1.5,
          ),
          boxShadow: isDefault
              ? [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.30),
                    blurRadius: 14,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isDefault) ...[
              const Icon(Icons.check_circle_rounded,
                  size: 16, color: AppTheme.primary),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontFamily: 'NotoKufi',
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isDefault ? AppTheme.primary : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Loading dots ─────────────────────────────────────────

  Widget _buildLoadingDots() {
    return AnimatedBuilder(
      animation: _dotsController,
      builder: (_, __) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final phase = (_dotsController.value - i / 3.0 + 1.0) % 1.0;
            final opacity = math.sin(phase * math.pi).clamp(0.15, 1.0);
            final scale = 0.7 + 0.3 * math.sin(phase * math.pi);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Transform.scale(
                scale: scale,
                child: Opacity(
                  opacity: opacity,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
