// lib/widgets/update_dialog.dart
// ─────────────────────────────────────────────────────────────
// "A new version is available" prompt.
//
// Two ways out, both cancel-friendly:
//   • "نوێکردنەوە / تحديث الآن"  → opens the store listing
//   • "دواتر / لاحقاً" (or tapping outside) → closes the dialog
//
// Dismissing is not remembered anywhere, so the next app run checks
// again and shows this prompt again while the update is still pending.
// ─────────────────────────────────────────────────────────────

import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../core/app_strings.dart';
import '../core/app_theme.dart';
import '../services/update_service.dart';

/// Shows the update prompt. Returns true when the user chose to update.
Future<bool> showUpdateDialog(
  BuildContext context,
  StoreUpdate update,
) async {
  final chose = await showDialog<bool>(
    context: context,
    // Cancelable — tapping the backdrop is the same as "later".
    barrierDismissible: true,
    builder: (ctx) => _UpdateDialog(update: update),
  );
  return chose ?? false;
}

class _UpdateDialog extends StatelessWidget {
  final StoreUpdate update;
  const _UpdateDialog({required this.update, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.system_update_rounded,
                  color: AppTheme.primary, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                S.updateAvailableTitle.of(context),
                style: const TextStyle(
                  fontFamily: 'NotoKufi',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              S.updateAvailableMessage.of(context),
              style: const TextStyle(
                fontFamily: 'NotoKufi',
                fontSize: 13,
                height: 1.5,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 14),
            // Installed → store version. Digits only, so it reads the
            // same in both languages.
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                border: Border.all(color: AppTheme.divider),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'v${update.installedVersion}',
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 12,
                      color: AppTheme.textMuted,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(Icons.arrow_forward_rounded,
                        size: 14, color: AppTheme.textMuted),
                  ),
                  Text(
                    'v${update.storeVersion}',
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              S.updatePrompt.of(context),
              style: const TextStyle(
                fontFamily: 'NotoKufi',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              S.updateButtonLater.of(context),
              style: const TextStyle(
                fontFamily: 'NotoKufi',
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context, true);
              UpdateService.instance.openStore(update);
            },
            icon: const Icon(Icons.download_rounded, size: 16),
            label: Text(
              S.updateButtonNow.of(context),
              style: const TextStyle(
                fontFamily: 'NotoKufi',
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 42),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
