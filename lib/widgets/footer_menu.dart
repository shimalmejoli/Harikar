// lib/widgets/footer_menu.dart

import 'package:flutter/material.dart';

import '../core/app_strings.dart';
import '../core/app_theme.dart';
import '../screens/AboutUsPage.dart';

class FooterMenu extends StatelessWidget {
  final int selectedIndex;

  const FooterMenu({
    Key? key,
    this.selectedIndex = -1,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppTheme.radiusLg)),
        boxShadow: AppTheme.bottomNavShadow,
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(children: [
            _navItem(
              context: context,
              index: 0,
              icon: Icons.home_rounded,
              label: S.footerHome.of(context),
              onTap: () =>
                  Navigator.pushReplacementNamed(context, '/dashboard'),
            ),
            _navItem(
              context: context,
              index: 1,
              icon: Icons.person_add_rounded,
              label: S.footerRegister.of(context),
              onTap: () => Navigator.pushReplacementNamed(context, '/register'),
            ),
            _navItem(
              context: context,
              index: 2,
              icon: Icons.info_rounded,
              label: S.footerAbout.of(context),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AboutUsPage()),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _navItem({
    required BuildContext context,
    required int index,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final bool active = selectedIndex == index;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ── Pill highlight ──────────────────────────────
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: active
                    ? AppTheme.accent.withOpacity(0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
              ),
              child: Icon(
                icon,
                size: 24,
                color: active ? AppTheme.accent : Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 2),
            // ── Label ────────────────────────────────────────
            Text(
              label,
              style: TextStyle(
                fontFamily: 'NotoKufi',
                fontSize: 10,
                fontWeight: active ? FontWeight.bold : FontWeight.normal,
                color: active ? AppTheme.accent : Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 2),
            // ── Active dot ───────────────────────────────────
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: active ? 4 : 0,
              height: active ? 4 : 0,
              decoration: const BoxDecoration(
                color: AppTheme.accent,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
