// lib/core/app_logger.dart
// ─────────────────────────────────────────────────────────────
// Structured logger with tags, levels, and Hostinger-specific
// connection debug output. Replaces simple_logger.dart.
// In release mode logs are suppressed automatically.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/foundation.dart';

enum _Level { info, warning, error, network, cache }

class AppLogger {
  AppLogger._();

  static const String _tag = 'LEGARYAN';

  // ── Public API ──────────────────────────────────────────────

  /// General info log
  static void info(String message, {String? tag}) =>
      _log(_Level.info, message, tag: tag);

  /// Warning — something unexpected but not fatal
  static void warning(String message, {String? tag}) =>
      _log(_Level.warning, message, tag: tag);

  /// Error — something failed
  static void error(String message,
      {Object? exception, StackTrace? stack, String? tag}) {
    _log(_Level.error, message, tag: tag);
    if (exception != null)
      _log(_Level.error, '  Exception: $exception', tag: tag);
    if (stack != null && !kReleaseMode) {
      debugPrint('[$_tag][STACK] $stack');
    }
  }

  /// Network — logs every HTTP request and response with timing
  static void network(
    String method,
    String url, {
    int? statusCode,
    int? durationMs,
    String? body,
    Object? exception,
  }) {
    if (kReleaseMode) return;

    final dur = durationMs != null ? '${durationMs}ms' : '';
    final status = statusCode != null ? ' → $statusCode' : '';

    debugPrint('[$_tag][NET] $method $url$status $dur');

    // ── Hostinger-specific checks ───────────────────────────
    if (exception != null) {
      final msg = exception.toString().toLowerCase();
      debugPrint('[$_tag][NET] ❌ Error: $exception');

      if (msg.contains('timeout') || msg.contains('timed out')) {
        debugPrint(
            '[$_tag][NET] ⚠️  HOSTINGER TIMEOUT — Server too slow or ISP blocking.');
        debugPrint(
            '[$_tag][NET]    → Check Cloudflare cache rules are active.');
        debugPrint(
            '[$_tag][NET]    → Check if user is on WiFi (ISP block) or mobile data.');
      } else if (msg.contains('socketexception') ||
          msg.contains('connection refused')) {
        debugPrint(
            '[$_tag][NET] ⚠️  CONNECTION REFUSED — Hostinger may be down.');
        debugPrint(
            '[$_tag][NET]    → Check https://legaryan.heama-soft.com in browser.');
      } else if (msg.contains('host lookup') || msg.contains('failed host')) {
        debugPrint(
            '[$_tag][NET] ⚠️  DNS FAILURE — ISP blocking domain or DNS issue.');
        debugPrint(
            '[$_tag][NET]    → Cloudflare proxy must be ON (orange cloud).');
      } else if (msg.contains('handshake') || msg.contains('certificate')) {
        debugPrint(
            '[$_tag][NET] ⚠️  SSL/TLS ERROR — Check SSL certificate on Hostinger.');
      } else if (msg.contains('network is unreachable') ||
          msg.contains('no address')) {
        debugPrint('[$_tag][NET] ⚠️  NO INTERNET on device.');
      }
    }

    if (statusCode != null) {
      if (statusCode == 200) {
        debugPrint('[$_tag][NET] ✅ Success');
      } else if (statusCode == 429) {
        debugPrint(
            '[$_tag][NET] ⚠️  RATE LIMITED — Too many requests to Hostinger.');
      } else if (statusCode == 500 || statusCode == 502 || statusCode == 503) {
        debugPrint(
            '[$_tag][NET] ⚠️  SERVER ERROR $statusCode — Hostinger PHP/DB issue.');
      } else if (statusCode == 524 || statusCode == 522) {
        debugPrint(
            '[$_tag][NET] ⚠️  CLOUDFLARE TIMEOUT $statusCode — Hostinger not responding.');
        debugPrint(
            '[$_tag][NET]    → Cloudflare reached server but server is too slow.');
      }
    }

    if (body != null && !kReleaseMode) {
      final preview = body.length > 300 ? '${body.substring(0, 300)}...' : body;
      debugPrint('[$_tag][NET] Body: $preview');
    }
  }

  /// Cache — logs cache hits/misses
  static void cache(String key, {required bool hit}) {
    if (kReleaseMode) return;
    final status = hit ? '✅ HIT' : '❌ MISS';
    debugPrint('[$_tag][CACHE] $status — $key');
  }

  // ── Internal ────────────────────────────────────────────────
  static void _log(_Level level, String message, {String? tag}) {
    if (kReleaseMode) return;
    final label = _levelLabel(level);
    final t = tag ?? _tag;
    debugPrint('[$t][$label] $message');
  }

  static String _levelLabel(_Level l) {
    switch (l) {
      case _Level.info:
        return 'INFO';
      case _Level.warning:
        return 'WARN';
      case _Level.error:
        return 'ERR ';
      case _Level.network:
        return 'NET ';
      case _Level.cache:
        return 'CACHE';
    }
  }
}
