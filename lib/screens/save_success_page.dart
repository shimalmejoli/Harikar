// lib/screens/save_success_page.dart

import 'package:flutter/material.dart';

import '../core/app_strings.dart';
import '../core/app_theme.dart';
import '../widgets/app_scaffold.dart';

class SaveSuccessPage extends StatelessWidget {
  const SaveSuccessPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: S.saveSuccessAppBarTitle.of(context),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),

            // ── Big success icon ──
            Center(
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  color: AppTheme.success.withOpacity(0.10),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: AppTheme.success.withOpacity(0.30), width: 2),
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  size: 78,
                  color: AppTheme.success,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Title ──
            Text(
              S.saveSuccessTitle.of(context),
              style: AppTheme.headingMedium.copyWith(
                fontSize: 20,
                color: AppTheme.success,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),

            // ── Body card (success-tinted) ──
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppTheme.success.withOpacity(0.06),
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                border: Border.all(
                    color: AppTheme.success.withOpacity(0.25), width: 1),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.success.withOpacity(0.18),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.info_outline_rounded,
                        color: AppTheme.success, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      S.saveSuccessBody.of(context),
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.textSecondary,
                        height: 1.6,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // ── Primary CTA ──
            SizedBox(
              height: AppTheme.buttonHeight,
              child: ElevatedButton.icon(
                onPressed: () =>
                    Navigator.pushReplacementNamed(context, '/dashboard'),
                icon: const Icon(Icons.home_rounded, size: 18),
                label: Text(S.saveSuccessButton.of(context)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
