// lib/widgets/custom_drawer.dart
// ─────────────────────────────────────────────────────────────
// Modernized side drawer used across all screens.
//
// Design: keeps the brand purple→blue gradient header, but adds:
//  • Larger user card with avatar, name, phone, role badge.
//  • Section labels (HOME / ADMIN / GENERAL / ACCOUNT).
//  • Material-3 style "pill" highlight for each item, with bigger
//    touch targets and softer dividers.
//  • Refined version footer.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/app_constants.dart';
import '../core/app_info.dart';
import '../core/app_logger.dart';
import '../core/app_strings.dart';
import '../core/app_theme.dart';
import '../models/user_model.dart';
import '../main.dart';
import '../screens/AboutUsPage.dart';
import '../screens/FeedbackPage.dart';
import '../screens/feedback_screen.dart';
import '../screens/profile_screen.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserModel>(context);
    // Read from LocaleProvider (via the watching extension) so the drawer
    // rebuilds in the chosen language whenever the user switches.
    final isArabic = context.isArabic;

    return Drawer(
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppTheme.radiusXl),
          bottomLeft: Radius.circular(AppTheme.radiusXl),
        ),
      ),
      elevation: 12,
      child: Column(
        children: [
          _DrawerHeader(user: user, isArabic: isArabic),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 12),
              physics: const BouncingScrollPhysics(),
              children: _buildSections(context, user, isArabic),
            ),
          ),
          _DrawerFooter(),
        ],
      ),
    );
  }

  // ── Sections per role ─────────────────────────────────────────
  List<Widget> _buildSections(
      BuildContext context, UserModel user, bool isArabic) {
    final sections = <Widget>[];

    // Common: Home + Profile (when logged in)
    sections.add(_SectionLabel(S.drawerSectionHome.of(context)));
    sections.add(_DrawerItem(
      icon: Icons.home_rounded,
      label: S.drawerHome.of(context),
      onTap: () => Navigator.pushReplacementNamed(context, '/dashboard'),
    ));

    if (user.role == 'admin' || user.role == 'user') {
      sections.add(_DrawerItem(
        icon: Icons.person_rounded,
        label: S.drawerProfile.of(context),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProfileScreen(
                userName: user.name, phoneNumber: user.phoneNumber),
          ),
        ),
      ));
    }

    // Admin section
    if (user.role == 'admin') {
      sections.add(_SectionLabel(S.drawerSectionAdmin.of(context)));
      sections.add(_DrawerItem(
        icon: Icons.category_rounded,
        label: S.drawerAddCategory.of(context),
        onTap: () => Navigator.pushNamed(context, '/add_category'),
      ));
      sections.add(_DrawerItem(
        icon: Icons.subdirectory_arrow_right_rounded,
        label: S.drawerAddSubcategory.of(context),
        onTap: () => Navigator.pushNamed(context, '/add_subcategory'),
      ));
      sections.add(_DrawerItem(
        icon: Icons.people_rounded,
        label: S.drawerViewUsers.of(context),
        onTap: () => Navigator.pushNamed(context, '/view_users'),
      ));
      sections.add(_DrawerItem(
        icon: Icons.add_box_rounded,
        label: S.drawerInsertDetails.of(context),
        onTap: () => Navigator.pushNamed(context, '/insert_details'),
      ));
      sections.add(_DrawerItem(
        icon: Icons.list_rounded,
        label: S.drawerShowDetails.of(context),
        onTap: () => Navigator.pushNamed(context, '/show_details'),
      ));
      sections.add(_DrawerItem(
        icon: Icons.edit_rounded,
        label: S.drawerEditUser.of(context),
        onTap: () => Navigator.pushNamed(context, '/user2'),
      ));
      sections.add(_DrawerItem(
        icon: Icons.campaign_rounded,
        label: S.drawerEditAds.of(context),
        onTap: () => Navigator.pushNamed(context, '/ads'),
      ));
    }

    // Guest-only: register
    if (user.role.isEmpty || (user.role != 'admin' && user.role != 'user')) {
      sections.add(_SectionLabel(S.drawerSectionAccount.of(context)));
      sections.add(_DrawerItem(
        icon: Icons.app_registration_rounded,
        label: S.drawerRegister.of(context),
        onTap: () => Navigator.pushReplacementNamed(context, '/register'),
      ));
    }

    // General — feedback / about / language
    sections.add(_SectionLabel(S.drawerSectionGeneral.of(context)));
    sections.add(_DrawerItem(
      icon: Icons.feedback_rounded,
      label: S.drawerFeedback.of(context),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const FeedbackScreen()),
      ),
    ));

    if (user.role == 'admin') {
      sections.add(_DrawerItem(
        icon: Icons.rate_review_rounded,
        label: S.drawerFeedbackSection.of(context),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => FeedbackPage()),
        ),
      ));
    }

    sections.add(_DrawerItem(
      icon: Icons.info_rounded,
      label: S.drawerAbout.of(context),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => AboutUsPage()),
      ),
    ));

    sections.add(_DrawerItem(
      icon: Icons.language_rounded,
      label: S.drawerChangeLanguage.of(context),
      onTap: () => _showLanguageDialog(context),
    ));

    // Account / sign-in / out
    sections.add(_SectionLabel(S.drawerSectionAccount.of(context)));

    if (user.role == 'admin' || user.role == 'user') {
      sections.add(_DrawerItem(
        icon: Icons.logout_rounded,
        label: S.drawerLogout.of(context),
        color: AppTheme.error,
        onTap: () => _logout(context),
      ));
    } else {
      sections.add(_DrawerItem(
        icon: Icons.login_rounded,
        label: S.drawerLogin.of(context),
        onTap: () => Navigator.pushReplacementNamed(context, '/login'),
      ));
    }

    return sections;
  }

  // ── Account actions ───────────────────────────────────────────

  Future<void> _logout(BuildContext context) async {
    AppLogger.info('User logged out', tag: 'DRAWER');
    Provider.of<UserModel>(context, listen: false).clearUser();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (context.mounted) {
      Navigator.pushReplacementNamed(context, '/dashboard');
    }
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(S.drawerLanguageDialogTitle.of(context)),
        contentPadding: const EdgeInsets.symmetric(vertical: 8),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Text('🇮🇶', style: TextStyle(fontSize: 22)),
              title: const Text('کوردی',
                  style: TextStyle(fontFamily: 'NotoKufi')),
              onTap: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('selectedLanguage', 'ku');
                if (context.mounted) {
                  Provider.of<LocaleProvider>(context, listen: false)
                      .setLocale(const Locale('ku', 'IQ'));
                  Navigator.of(context)
                    ..pop()
                    ..pop();
                }
              },
            ),
            ListTile(
              leading: const Text('🇸🇦', style: TextStyle(fontSize: 22)),
              title: const Text('العربية',
                  style: TextStyle(fontFamily: 'NotoKufi')),
              onTap: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('selectedLanguage', 'ar');
                if (context.mounted) {
                  Provider.of<LocaleProvider>(context, listen: false)
                      .setLocale(const Locale('ar', ''));
                  Navigator.of(context)
                    ..pop()
                    ..pop();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Internal building blocks
// ─────────────────────────────────────────────────────────────

class _DrawerHeader extends StatelessWidget {
  final UserModel user;
  final bool isArabic;

  const _DrawerHeader({required this.user, required this.isArabic});

  @override
  Widget build(BuildContext context) {
    final hasUser = user.role.isNotEmpty;
    final greeting = hasUser
        ? user.name
        : S.drawerWelcome.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.of(context).padding.top + 20,
        20,
        24,
      ),
      decoration: const BoxDecoration(gradient: AppTheme.appBarGradient),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.22),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white54, width: 1.5),
            ),
            child: Icon(
              hasUser ? Icons.person_rounded : Icons.waving_hand_rounded,
              size: 34,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            greeting,
            style: const TextStyle(
              fontFamily: 'NotoKufi',
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (user.phoneNumber.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              user.phoneNumber,
              style: const TextStyle(
                fontFamily: 'NotoKufi',
                fontSize: 13,
                color: Colors.white70,
              ),
            ),
          ],
          if (hasUser) ...[
            const SizedBox(height: 10),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.22),
                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                border: Border.all(color: Colors.white38, width: 0.8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    user.role == 'admin'
                        ? Icons.shield_rounded
                        : Icons.verified_user_rounded,
                    size: 12,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    user.role == 'admin'
                        ? S.drawerRoleAdmin.of(context)
                        : S.drawerRoleUser.of(context),
                    style: const TextStyle(
                      fontFamily: 'NotoKufi',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
      child: Text(
        text.toUpperCase(),
        style: AppTheme.sectionLabel,
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final tint = color ?? AppTheme.primary;
    final textColor = color ?? AppTheme.textPrimary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          onTap: onTap,
          splashColor: tint.withOpacity(0.10),
          highlightColor: tint.withOpacity(0.06),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: tint.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: tint, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'NotoKufi',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DrawerFooter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppTheme.divider, width: 1)),
      ),
      child: Column(
        children: [
          Text(
            AppConstants.appName,
            style: const TextStyle(
              fontFamily: 'NotoKufi',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${AppInfo.versionLabel}  •  Heama Soft',
            style: TextStyle(
              fontFamily: 'NotoKufi',
              fontSize: 10,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}
