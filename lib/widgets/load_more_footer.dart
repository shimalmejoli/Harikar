// lib/widgets/load_more_footer.dart
// ─────────────────────────────────────────────────────────────
// Trailing item for infinite-scroll lists.
//
// Renders either a spinner (more rows are on the way) or a quiet
// "everything is loaded" line. Add it as the LAST item of a
// ListView.builder:
//
//   itemCount: items.length + 1,
//   itemBuilder: (_, i) => i == items.length
//       ? LoadMoreFooter(isLoading: _isLoadingMore, hasMore: _hasMore)
//       : _buildCard(items[i]),
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

import '../core/app_strings.dart';
import '../core/app_theme.dart';

class LoadMoreFooter extends StatelessWidget {
  /// A page request is currently in flight.
  final bool isLoading;

  /// The server (or the local buffer) still has rows left.
  final bool hasMore;

  /// Hide the "all loaded" line — useful for very short lists where
  /// the message adds noise.
  final bool showEndMessage;

  const LoadMoreFooter({
    required this.isLoading,
    required this.hasMore,
    this.showEndMessage = true,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppTheme.accent,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              S.listLoadingMore.of(context),
              style: const TextStyle(
                fontFamily: 'NotoKufi',
                fontSize: 11,
                color: AppTheme.textMuted,
              ),
            ),
          ],
        ),
      );
    }

    // More rows exist but the scroll hasn't reached the trigger yet —
    // keep a little breathing room so the last card isn't flush with
    // the screen edge.
    if (hasMore) return const SizedBox(height: 24);

    if (!showEndMessage) return const SizedBox(height: 16);

    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 22),
      child: Center(
        child: Text(
          S.listAllLoaded.of(context),
          style: const TextStyle(
            fontFamily: 'NotoKufi',
            fontSize: 10,
            color: AppTheme.textMuted,
          ),
        ),
      ),
    );
  }
}
