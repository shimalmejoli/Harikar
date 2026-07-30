// lib/services/api_service.dart
// ─────────────────────────────────────────────────────────────
// Central HTTP service. Every API call goes through here.
// On Flutter Web (Chrome debug), requests go through a CORS
// proxy automatically. On mobile, direct connection is used.
// ─────────────────────────────────────────────────────────────

import 'dart:convert';
import 'package:flutter/foundation.dart'; // kIsWeb
import 'package:http/http.dart' as http;
import '../core/app_constants.dart';
import '../core/app_logger.dart';

/// Generic API response wrapper
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? error;
  final int? statusCode;
  final int? durationMs;

  const ApiResponse({
    required this.success,
    this.data,
    this.error,
    this.statusCode,
    this.durationMs,
  });

  bool get isNetworkError => statusCode == null && error != null;
}

class ApiService {
  ApiService._();
  static final ApiService instance = ApiService._();

  /// True when the decoded response body signals success via either
  /// of the conventions used by this app's PHP backend:
  ///   • `{"status": "success", ...}` — used by older endpoints.
  ///   • `{"success": true,    ...}` — used by newer endpoints
  ///     (e.g. register_user.php, fetch_subcategories, etc.).
  /// Without this dual check, an endpoint returning `success: true`
  /// is wrongly flagged as a failure and its `message` (which is the
  /// success text) is exposed as `response.error`.
  static bool _bodyOk(Map<String, dynamic> decoded) =>
      decoded['status'] == 'success' || decoded['success'] == true;

  // ── CORS proxy for Flutter Web development only ──────────────
  // On mobile (Android/iOS) this is never used.
  // On web debug builds, wraps the URL to bypass browser CORS.
  // In production mobile builds kIsWeb is false — no proxy.
  static const String _corsProxy = 'https://corsproxy.io/?';

  String _url(String url) {
    // Only wrap in proxy when running as Flutter Web
    if (kIsWeb) {
      AppLogger.info('Web mode — using CORS proxy for: $url', tag: 'API');
      return '$_corsProxy${Uri.encodeComponent(url)}';
    }
    return url;
  }

  // ── GET ─────────────────────────────────────────────────────

  Future<ApiResponse<Map<String, dynamic>>> get(
    String url, {
    Map<String, String>? queryParams,
  }) async {
    // Build the final URI with query params first, then wrap
    final rawUri = queryParams != null
        ? Uri.parse(url).replace(queryParameters: queryParams)
        : Uri.parse(url);

    // On web, wrap the full URL string in proxy
    final finalUri = kIsWeb
        ? Uri.parse('$_corsProxy${Uri.encodeComponent(rawUri.toString())}')
        : rawUri;

    final stopwatch = Stopwatch()..start();
    AppLogger.network('GET', rawUri.toString());

    try {
      final response = await http
          .get(finalUri, headers: _headers())
          .timeout(AppConstants.connectTimeout);

      stopwatch.stop();
      final ms = stopwatch.elapsedMilliseconds;

      AppLogger.network('GET', rawUri.toString(),
          statusCode: response.statusCode, durationMs: ms);

      if (response.statusCode == 200) {
        final decoded = _decode(response.body, rawUri.toString());
        if (decoded == null) {
          return ApiResponse(
            success: false,
            error: 'Invalid JSON response from server',
            statusCode: response.statusCode,
            durationMs: ms,
          );
        }
        return ApiResponse(
          success: true,
          data: decoded,
          statusCode: response.statusCode,
          durationMs: ms,
        );
      } else {
        AppLogger.error('GET failed — HTTP ${response.statusCode}', tag: 'API');
        return ApiResponse(
          success: false,
          error: 'Server error: ${response.statusCode}',
          statusCode: response.statusCode,
          durationMs: ms,
        );
      }
    } catch (e, stack) {
      stopwatch.stop();
      AppLogger.network('GET', rawUri.toString(), exception: e);
      AppLogger.error('GET exception', exception: e, stack: stack, tag: 'API');
      return ApiResponse(
        success: false,
        error: e.toString(),
        durationMs: stopwatch.elapsedMilliseconds,
      );
    }
  }

  // ── POST ────────────────────────────────────────────────────

  Future<ApiResponse<Map<String, dynamic>>> post(
    String url, {
    Map<String, String>? fields,
    Map<String, dynamic>? jsonBody,
  }) async {
    // On web, wrap in proxy
    final finalUrl = kIsWeb ? '$_corsProxy${Uri.encodeComponent(url)}' : url;

    final uri = Uri.parse(finalUrl);
    final stopwatch = Stopwatch()..start();
    AppLogger.network('POST', url);

    try {
      http.Response response;

      if (jsonBody != null) {
        response = await http
            .post(uri,
                headers: {
                  ..._headers(),
                  'Content-Type': 'application/json',
                },
                body: json.encode(jsonBody))
            .timeout(AppConstants.connectTimeout);
      } else {
        response = await http
            .post(uri, headers: _headers(), body: fields ?? {})
            .timeout(AppConstants.connectTimeout);
      }

      stopwatch.stop();
      final ms = stopwatch.elapsedMilliseconds;

      AppLogger.network('POST', url,
          statusCode: response.statusCode, durationMs: ms, body: response.body);

      if (response.statusCode == 200) {
        final decoded = _decode(response.body, url);
        if (decoded == null) {
          return ApiResponse(
            success: false,
            error: 'Invalid JSON response from server',
            statusCode: response.statusCode,
            durationMs: ms,
          );
        }
        final ok = _bodyOk(decoded);
        return ApiResponse(
          success: ok,
          data: decoded,
          statusCode: response.statusCode,
          durationMs: ms,
          error: ok ? null : decoded['message']?.toString(),
        );
      } else {
        AppLogger.error('POST failed — HTTP ${response.statusCode}',
            tag: 'API');
        return ApiResponse(
          success: false,
          error: 'Server error: ${response.statusCode}',
          statusCode: response.statusCode,
          durationMs: ms,
        );
      }
    } catch (e, stack) {
      stopwatch.stop();
      AppLogger.network('POST', url, exception: e);
      AppLogger.error('POST exception', exception: e, stack: stack, tag: 'API');
      return ApiResponse(
        success: false,
        error: e.toString(),
        durationMs: stopwatch.elapsedMilliseconds,
      );
    }
  }

  // ── Domain-specific helpers ──────────────────────────────────

  /// Cache-busting token — appended as `?_t=<ms>` to every helper GET
  /// that returns user-mutable data. The PHP backend sends
  /// `Cache-Control: max-age=300` for these endpoints, which would
  /// otherwise let the network layer return a 5-minute-stale response
  /// after a toggle/add/delete (the admin would update a category but
  /// the dashboard would keep showing the old `is_active` value).
  /// A unique URL forces a fresh round-trip every call.
  Map<String, String> _cacheBust() => {
        '_t': DateTime.now().millisecondsSinceEpoch.toString(),
      };

  Future<ApiResponse<Map<String, dynamic>>> fetchCategories() =>
      get(AppConstants.categoriesEndpoint, queryParams: _cacheBust());

  Future<ApiResponse<Map<String, dynamic>>> fetchSlideshow() =>
      get(AppConstants.slideshowEndpoint, queryParams: _cacheBust());

  Future<ApiResponse<Map<String, dynamic>>> fetchSubcategories() =>
      get(AppConstants.subcategoriesEndpoint, queryParams: _cacheBust());

  /// One page of work records. `fetch_full_details.php` applies the
  /// `sub_category_id` / `city` filters server-side and caps `limit` at
  /// [AppConstants.maxPageSize] (50) — asking for more still returns 50.
  /// Callers page through by incrementing [page] until a response comes
  /// back with fewer than [limit] rows (see WorkDetailsPage).
  Future<ApiResponse<Map<String, dynamic>>> fetchWorkDetails({
    String? subcategoryId,
    String? city,
    String lang = 'ku',
    int page = 1,
    int limit = AppConstants.maxPageSize,
  }) {
    final params = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
      'lang': lang,
    };
    if (subcategoryId?.isNotEmpty == true)
      params['sub_category_id'] = subcategoryId!;
    if (city?.isNotEmpty == true && city != 'هەموو شەهرەکان')
      params['city'] = city!;
    return get(AppConstants.fullDetailsEndpoint, queryParams: params);
  }

  Future<ApiResponse<Map<String, dynamic>>> fetchDetailById(String id) =>
      get(AppConstants.detailByIdEndpoint, queryParams: {'detail_id': id});

  Future<ApiResponse<Map<String, dynamic>>> fetchRelatedDetails(
          String subcategoryId) =>
      get(AppConstants.relatedDetailsEndpoint,
          queryParams: {'sub_category_id': subcategoryId});

  Future<ApiResponse<Map<String, dynamic>>> incrementViewCount(String id) =>
      post(AppConstants.incrementViewEndpoint, fields: {'detail_id': id});

  Future<ApiResponse<Map<String, dynamic>>> login(
          String phone, String password) =>
      post(AppConstants.loginEndpoint,
          jsonBody: {'input': phone, 'password': password});

  Future<ApiResponse<Map<String, dynamic>>> submitFeedback(
          String name, String phone, String message) =>
      post(AppConstants.feedbackEndpoint,
          jsonBody: {'name': name, 'phone_number': phone, 'message': message});

  Future<ApiResponse<Map<String, dynamic>>> deleteAccount(String phone) =>
      post(AppConstants.deleteAccountEndpoint, fields: {'phone_number': phone});

  // ── Private helpers ──────────────────────────────────────────

  Map<String, String> _headers() => {
        'Accept': 'application/json',
        'Accept-Language': 'ku,ar;q=0.9',
      };

  Map<String, dynamic>? _decode(String body, String url) {
    try {
      // corsproxy.io sometimes wraps the response — unwrap if needed
      final decoded = json.decode(body);
      if (decoded is Map<String, dynamic>) return decoded;
      // Some endpoints (e.g. get_users2.php) return a bare JSON array
      // instead of `{status, data}`. Wrap it in a synthetic envelope
      // so callers can use the standard `r.data!['data']` pattern and
      // `_bodyOk` treats it as successful.
      if (decoded is List) {
        return {'status': 'success', 'data': decoded};
      }
      AppLogger.error('Unexpected JSON type from $url: ${decoded.runtimeType}',
          tag: 'API');
      return null;
    } catch (e) {
      AppLogger.error('JSON decode failed for $url', exception: e, tag: 'API');
      AppLogger.network('DECODE', url, body: body);
      return null;
    }
  }
}
