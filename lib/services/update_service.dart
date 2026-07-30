// lib/services/update_service.dart
// ─────────────────────────────────────────────────────────────
// "A new version is available" check against the real stores.
//
//   Android → the app's Google Play listing (the published version is
//             embedded in the page's data blob).
//   iOS     → the official iTunes Lookup API for the bundle id.
//
// Both lookups are best-effort: any network error, layout change or
// unpublished listing simply means "no update found" — the app never
// blocks, never throws and never shows an error to the user for this.
//
// The prompt is shown AT MOST ONCE per app run ([promptedThisLaunch]),
// and nothing is persisted: if the user taps "later", the next cold
// start checks again and asks again while the update is still there.
// ─────────────────────────────────────────────────────────────

import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb, visibleForTesting;
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../core/app_constants.dart';
import '../core/app_info.dart';
import '../core/app_logger.dart';

/// A newer release found on the store the app was installed from.
class StoreUpdate {
  /// Version published on the store, e.g. "1.0.6".
  final String storeVersion;

  /// Version currently running on the device, e.g. "1.0.5".
  final String installedVersion;

  /// Web listing URL — used as the fallback when the native store
  /// scheme (market:// | itms-apps://) can't be opened.
  final String storeUrl;

  /// Deep link that opens the store app directly, when available.
  final String? nativeStoreUrl;

  const StoreUpdate({
    required this.storeVersion,
    required this.installedVersion,
    required this.storeUrl,
    this.nativeStoreUrl,
  });
}

class UpdateService {
  UpdateService._();
  static final UpdateService instance = UpdateService._();

  /// True once the dialog has been shown during this app run. Lives in
  /// memory only, so it resets on every cold start — that is what makes
  /// "remind me on the next run" work without any stored state.
  bool _promptedThisLaunch = false;
  bool get promptedThisLaunch => _promptedThisLaunch;
  void markPrompted() => _promptedThisLaunch = true;

  /// Returns the pending update, or null when the app is up to date,
  /// the platform has no store, or the lookup failed.
  Future<StoreUpdate?> checkForUpdate() async {
    // Only mobile has a store to compare against.
    if (kIsWeb) return null;
    try {
      if (Platform.isAndroid) return await _checkPlayStore();
      if (Platform.isIOS) return await _checkAppStore();
    } catch (e) {
      AppLogger.warning('Update check failed: $e', tag: 'UPDATE');
    }
    return null;
  }

  /// Opens the store page so the user can install the new version.
  /// Tries the native store app first, then the web listing.
  Future<void> openStore(StoreUpdate update) async {
    final candidates = [
      if (update.nativeStoreUrl != null) update.nativeStoreUrl!,
      update.storeUrl,
    ];
    for (final url in candidates) {
      final uri = Uri.parse(url);
      try {
        if (await canLaunchUrl(uri)) {
          AppLogger.info('Opening store: $url', tag: 'UPDATE');
          final ok =
              await launchUrl(uri, mode: LaunchMode.externalApplication);
          if (ok) return;
        }
      } catch (e) {
        AppLogger.warning('Could not open $url: $e', tag: 'UPDATE');
      }
    }
    AppLogger.error('No store URL could be opened', tag: 'UPDATE');
  }

  // ── Google Play ────────────────────────────────────────────

  Future<StoreUpdate?> _checkPlayStore() async {
    // hl/gl are pinned so the response shape doesn't depend on the
    // device locale; the version blob is language-independent anyway.
    final uri = Uri.parse('${AppConstants.playStoreUrl}&hl=en&gl=US');
    final r = await http
        .get(uri, headers: const {'Accept-Language': 'en-US,en;q=0.9'})
        .timeout(AppConstants.updateCheckTimeout);

    if (r.statusCode != 200) {
      AppLogger.warning('Play Store lookup HTTP ${r.statusCode}',
          tag: 'UPDATE');
      return null;
    }

    final storeVersion = extractPlayStoreVersion(r.body);
    if (storeVersion == null) {
      AppLogger.warning('Play Store version not found in listing',
          tag: 'UPDATE');
      return null;
    }

    return _compare(
      storeVersion: storeVersion,
      storeUrl: AppConstants.playStoreUrl,
      nativeStoreUrl: AppConstants.playStoreNativeUrl,
    );
  }

  /// Play embeds the published version in an inline JS data blob:
  ///
  ///     ..."141":[[["1.0.5"]],[[[35]]...
  ///
  /// Field 141 is the version cell; the looser bracket pattern is kept
  /// as a fallback in case Google renumbers the fields again.
  @visibleForTesting
  String? extractPlayStoreVersion(String html) {
    final patterns = [
      RegExp(r'"141":\s*\[\[\["([0-9]+(?:\.[0-9]+)*)"\]\]'),
      RegExp(r'\[\[\["([0-9]+(?:\.[0-9]+){1,3})"\]\]'),
    ];
    for (final p in patterns) {
      final m = p.firstMatch(html);
      final v = m?.group(1);
      if (v != null && v.isNotEmpty) return v;
    }
    return null;
  }

  // ── App Store ──────────────────────────────────────────────

  Future<StoreUpdate?> _checkAppStore() async {
    // The lookup is storefront-scoped: an app published only in Iraq is
    // invisible from the default (US) storefront, so try both. While the
    // iOS build is not on the App Store yet, every storefront returns
    // resultCount 0 and the check quietly finds nothing.
    for (final country in AppConstants.appStoreCountries) {
      final uri = Uri.parse(
          '${AppConstants.appStoreLookupUrl}?bundleId=${AppConstants.appStoreBundleId}'
          '&country=$country'
          '&_t=${DateTime.now().millisecondsSinceEpoch}');
      final r = await http.get(uri).timeout(AppConstants.updateCheckTimeout);
      if (r.statusCode != 200) continue;

      final body = json.decode(r.body);
      if (body is! Map) continue;
      final results = body['results'] as List? ?? const [];
      if (results.isEmpty) continue;

      final first = results.first as Map;
      final storeVersion = first['version']?.toString();
      if (storeVersion == null || storeVersion.isEmpty) continue;

      final trackId = first['trackId']?.toString();
      return _compare(
        storeVersion: storeVersion,
        storeUrl: first['trackViewUrl']?.toString() ??
            'https://apps.apple.com/app/id$trackId',
        nativeStoreUrl:
            trackId == null ? null : 'itms-apps://apps.apple.com/app/id$trackId',
      );
    }
    AppLogger.info('App Store listing not found — skipping update check',
        tag: 'UPDATE');
    return null;
  }

  // ── Version comparison ─────────────────────────────────────

  StoreUpdate? _compare({
    required String storeVersion,
    required String storeUrl,
    String? nativeStoreUrl,
  }) {
    final installed = AppInfo.version;
    final newer = isNewerVersion(storeVersion, installed);
    AppLogger.info(
        'Update check — store: $storeVersion installed: $installed '
        '→ ${newer ? 'update available' : 'up to date'}',
        tag: 'UPDATE');
    if (!newer) return null;

    return StoreUpdate(
      storeVersion: storeVersion,
      installedVersion: installed,
      storeUrl: storeUrl,
      nativeStoreUrl: nativeStoreUrl,
    );
  }

  /// True when [candidate] is strictly higher than [current], comparing
  /// segment by segment so "1.0.10" correctly beats "1.0.9" and a
  /// shorter "1.1" beats "1.0.9". Build suffixes are ignored.
  static bool isNewerVersion(String candidate, String current) {
    final a = _segments(candidate);
    final b = _segments(current);
    final len = a.length > b.length ? a.length : b.length;
    for (var i = 0; i < len; i++) {
      final x = i < a.length ? a[i] : 0;
      final y = i < b.length ? b[i] : 0;
      if (x != y) return x > y;
    }
    return false;
  }

  static List<int> _segments(String version) => version
      .split('+')
      .first
      .split('.')
      .map((s) => int.tryParse(s.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0)
      .toList();
}
