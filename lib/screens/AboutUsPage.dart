// lib/screens/AboutUsPage.dart

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/app_constants.dart';
import '../core/app_info.dart';
import '../core/app_strings.dart';
import '../core/app_theme.dart';
import '../main.dart' show LocaleContext;
import '../widgets/app_scaffold.dart';

class AboutUsPage extends StatelessWidget {
  const AboutUsPage({Key? key}) : super(key: key);

  /// Tapping "Heama Soft" in the credits footer opens this URL.
  static const String _developerUrl = 'https://qrcode.heama-soft.com/';

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: S.aboutTitle.of(context),
      footerIndex: 2,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeroCard(context),
            const SizedBox(height: 18),
            _buildContactCard(context),
            const SizedBox(height: 14),
            _buildAdvertiseCard(context),
            const SizedBox(height: 18),
            _buildCreditsFooter(context),
          ],
        ),
      ),
    );
  }

  // ── Hero ───────────────────────────────────────────────────

  Widget _buildHeroCard(BuildContext context) {
    final desc = S.aboutHeroDescription.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: AppTheme.appBarGradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: AppTheme.appBarShadow,
      ),
      child: Column(
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.16),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white38, width: 1.5),
            ),
            child: Center(
              child: Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/logo.png',
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Center(
                      child: Icon(Icons.work_rounded,
                          size: 30, color: AppTheme.primary),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            S.aboutBrand.of(context),
            style: AppTheme.headingLarge.copyWith(
              fontSize: 26,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.20),
              borderRadius: BorderRadius.circular(AppTheme.radiusFull),
              border: Border.all(color: Colors.white38, width: 0.8),
            ),
            child: Text(
              AppInfo.versionLabel,
              style: const TextStyle(
                fontFamily: 'NotoKufi',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            desc,
            style: AppTheme.captionWhite.copyWith(
              fontSize: 13,
              height: 1.7,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ── Contact card ───────────────────────────────────────────

  Widget _buildContactCard(BuildContext context) {
    return _whiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionHeader(
            icon: Icons.contact_phone_rounded,
            title: S.aboutContactTitle.of(context),
          ),
          const SizedBox(height: 14),
          // Phone number in a "tappable card" treatment
          GestureDetector(
            onTap: () => launchUrl(
                Uri(scheme: 'tel', path: AppConstants.contactPhone)),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                gradient: AppTheme.appBarGradient,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                boxShadow: AppTheme.softShadow,
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.22),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.phone_rounded,
                        color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          S.aboutContactCardLabel.of(context),
                          style: AppTheme.captionWhite.copyWith(fontSize: 11),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          AppConstants.contactPhone,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded,
                      color: Colors.white70, size: 14),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Action row: Call + WhatsApp
          Row(
            children: [
              Expanded(
                child: _miniContactButton(
                  icon: Icons.phone_rounded,
                  label: S.callLabel.of(context),
                  bg: AppTheme.primary.withOpacity(0.10),
                  fg: AppTheme.primary,
                  onTap: () => launchUrl(
                      Uri(scheme: 'tel', path: AppConstants.contactPhone)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _miniContactButton(
                  icon: FontAwesomeIcons.whatsapp,
                  label: 'WhatsApp',
                  bg: const Color(0xFF25D366).withOpacity(0.10),
                  fg: const Color(0xFF25D366),
                  onTap: () => launchUrl(
                    Uri.parse(
                        'https://wa.me/${AppConstants.whatsAppNumber}'),
                    mode: LaunchMode.externalApplication,
                  ),
                  faIcon: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Advertise card ─────────────────────────────────────────

  Widget _buildAdvertiseCard(BuildContext context) {
    final isArabic = context.isArabic;
    return _whiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionHeader(
            icon: Icons.campaign_rounded,
            title: S.aboutAdvertiseTitle.of(context),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: AppTheme.adGradient,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE91E63).withOpacity(0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.22),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  child: const Icon(Icons.storefront_rounded,
                      color: Colors.white, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    S.aboutAdvertiseDescription.of(context),
                    style: AppTheme.captionWhite.copyWith(
                      fontSize: 12,
                      height: 1.6,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: AppTheme.buttonHeight,
            child: ElevatedButton.icon(
              onPressed: () => launchUrl(
                  Uri(scheme: 'tel', path: AppConstants.contactPhone)),
              icon: const Icon(Icons.phone_rounded, size: 18),
              label: Text(
                isArabic
                    ? 'اتصل للإعلان · ${AppConstants.contactPhone}'
                    : 'پەیوەندی بۆ ڕیکلام · ${AppConstants.contactPhone}',
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Credits footer ────────────────────────────────────────

  Widget _buildCreditsFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.divider, width: 1),
      ),
      child: Column(
        children: [
          Text(
            S.aboutCreditsTitle.of(context),
            style: AppTheme.bodySmall.copyWith(
              fontSize: 12,
              color: AppTheme.textMuted,
            ),
          ),
          const SizedBox(height: 6),
          // Tappable brand name — opens the developer's site.
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              onTap: () => launchUrl(
                Uri.parse(_developerUrl),
                mode: LaunchMode.externalApplication,
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Heama Soft',
                      style: TextStyle(
                        fontFamily: 'NotoKufi',
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                        letterSpacing: 0.5,
                        decoration: TextDecoration.underline,
                        decorationColor: AppTheme.primary,
                        decorationThickness: 1.4,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.open_in_new_rounded,
                      size: 13,
                      color: AppTheme.primary.withOpacity(0.7),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Reusable bits ──────────────────────────────────────────

  Widget _whiteCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: AppTheme.softShadow,
      ),
      child: child,
    );
  }

  Widget _sectionHeader({required IconData icon, required String title}) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppTheme.primary.withOpacity(0.10),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppTheme.primary, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(title, style: AppTheme.headingSmall),
        ),
      ],
    );
  }

  Widget _miniContactButton({
    required IconData icon,
    required String label,
    required Color bg,
    required Color fg,
    required VoidCallback onTap,
    bool faIcon = false,
  }) {
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 11),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (faIcon)
                FaIcon(icon, color: fg, size: 16)
              else
                Icon(icon, color: fg, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'NotoKufi',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
