// lib/services/cache_service.dart
// ─────────────────────────────────────────────────────────────
// Central cache service using SharedPreferences.
// All screens read/write cache through this class only.
// ─────────────────────────────────────────────────────────────

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/app_constants.dart';
import '../core/app_logger.dart';

class CacheService {
  CacheService._();
  static final CacheService instance = CacheService._();

  // ── Write ───────────────────────────────────────────────────

  Future<void> saveList(String key, List<dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, json.encode(data));
      AppLogger.info('Cache SAVED ✅ — $key (${data.length} items)',
          tag: 'CACHE');
    } catch (e) {
      AppLogger.error('CacheService.saveList failed',
          exception: e, tag: 'CACHE');
    }
  }

  Future<void> saveMap(String key, Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, json.encode(data));
      AppLogger.info('Cache SAVED ✅ — $key', tag: 'CACHE');
    } catch (e) {
      AppLogger.error('CacheService.saveMap failed',
          exception: e, tag: 'CACHE');
    }
  }

  Future<void> saveString(String key, String value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
      AppLogger.info('Cache SAVED ✅ — $key', tag: 'CACHE');
    } catch (e) {
      AppLogger.error('CacheService.saveString failed',
          exception: e, tag: 'CACHE');
    }
  }

  // ── Read ────────────────────────────────────────────────────

  Future<List<dynamic>?> getList(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(key);
      if (raw == null) {
        AppLogger.cache(key, hit: false);
        return null;
      }
      AppLogger.cache(key, hit: true);
      return json.decode(raw) as List<dynamic>;
    } catch (e) {
      AppLogger.error('CacheService.getList failed',
          exception: e, tag: 'CACHE');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getMap(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(key);
      if (raw == null) {
        AppLogger.cache(key, hit: false);
        return null;
      }
      AppLogger.cache(key, hit: true);
      return json.decode(raw) as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error('CacheService.getMap failed', exception: e, tag: 'CACHE');
      return null;
    }
  }

  Future<String?> getString(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(key);
    } catch (e) {
      AppLogger.error('CacheService.getString failed',
          exception: e, tag: 'CACHE');
      return null;
    }
  }

  // ── Delete ──────────────────────────────────────────────────

  Future<void> remove(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
      AppLogger.info('Cache REMOVED — $key', tag: 'CACHE');
    } catch (e) {
      AppLogger.error('CacheService.remove failed', exception: e, tag: 'CACHE');
    }
  }

  Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      AppLogger.info('Cache CLEARED ALL', tag: 'CACHE');
    } catch (e) {
      AppLogger.error('CacheService.clearAll failed',
          exception: e, tag: 'CACHE');
    }
  }

  // ── Work details cache key helper ────────────────────────────
  static String workDetailsCacheKey({String? subId, String? city}) {
    final sub = (subId?.isEmpty ?? true) ? 'all' : subId!;
    final c = (city?.isEmpty ?? true) ? 'all' : city!;
    return '${AppConstants.cacheWorkDetails}${sub}_$c';
  }
}
