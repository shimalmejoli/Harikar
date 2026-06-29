// lib/core/app_info.dart
// ─────────────────────────────────────────────────────────────
// Runtime metadata about the running app build.
//
// Values come from pubspec.yaml's `version: X.Y.Z+B` line, read at
// startup via [package_info_plus]. Call [AppInfo.load] from `main()`
// BEFORE `runApp`, then read [version] / [buildNumber] synchronously
// from anywhere (drawer, about page, etc.).
//
// If [load] hasn't run yet (or failed), the static fallbacks below
// are returned — never null, never throws.
// ─────────────────────────────────────────────────────────────

import 'package:package_info_plus/package_info_plus.dart';

import 'app_logger.dart';

class AppInfo {
  AppInfo._();

  /// Marketing version from pubspec (the part before `+`). e.g. "1.0.1".
  static String version = '1.0.0';

  /// Build number from pubspec (the part after `+`). e.g. "3".
  static String buildNumber = '1';

  /// True once [load] has completed successfully.
  static bool _loaded = false;

  /// Load app metadata from the platform. Safe to call multiple times.
  static Future<void> load() async {
    if (_loaded) return;
    try {
      final info = await PackageInfo.fromPlatform();
      version = info.version;
      buildNumber = info.buildNumber;
      _loaded = true;
      AppLogger.info('AppInfo loaded — v$version+$buildNumber', tag: 'APP_INFO');
    } catch (e) {
      AppLogger.warning('AppInfo load failed: $e — using fallback values',
          tag: 'APP_INFO');
    }
  }

  /// "v1.0.1" — marketing version with leading "v".
  static String get versionLabel => 'v$version';

  /// "v1.0.1 (3)" — version + build, useful for debug/about screens.
  static String get fullVersionLabel => 'v$version ($buildNumber)';
}
