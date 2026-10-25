import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// 本地存储（SharedPreferences）
class Storage {
  Storage._();

  static final Storage instance = Storage._();

  static late final SharedPreferences _prefs;

  static const String _kApiKey = 'api_key';
  static const String _kUserId = 'user_id';
  static const String _kNickname = 'nickname';
  static const String _kAvatar = 'avatar';
  static const String _kEmail = 'email';
  static const String _kThemeMode = 'theme_mode'; // 0=system 1=light 2=dark
  static const String _kSearchHistory = 'search_history';
  static const String _kDownloadRecords = 'download_records';
  static const String _kDeviceFilter = 'device_filter_enabled';
  static const String _kIgnoredUpdate = 'ignored_update';
  static const String _kLastCheckin = 'last_checkin_date';

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ---- 账户 ----
  String? get apiKey => _prefs.getString(_kApiKey);

  Future<void> setApiKey(String? v) async {
    if (v == null || v.isEmpty) {
      await _prefs.remove(_kApiKey);
    } else {
      await _prefs.setString(_kApiKey, v);
    }
  }

  int get userId => _prefs.getInt(_kUserId) ?? 0;

  Future<void> setUserId(int v) async => _prefs.setInt(_kUserId, v);

  String? get nickname => _prefs.getString(_kNickname);

  Future<void> setNickname(String? v) async {
    if (v == null || v.isEmpty) {
      await _prefs.remove(_kNickname);
    } else {
      await _prefs.setString(_kNickname, v);
    }
  }

  String? get avatar => _prefs.getString(_kAvatar);

  Future<void> setAvatar(String? v) async {
    if (v == null || v.isEmpty) {
      await _prefs.remove(_kAvatar);
    } else {
      await _prefs.setString(_kAvatar, v);
    }
  }

  String? get email => _prefs.getString(_kEmail);

  Future<void> setEmail(String? v) async {
    if (v == null || v.isEmpty) {
      await _prefs.remove(_kEmail);
    } else {
      await _prefs.setString(_kEmail, v);
    }
  }

  Future<void> clearAccount() async {
    await _prefs.remove(_kApiKey);
    await _prefs.remove(_kUserId);
    await _prefs.remove(_kNickname);
    await _prefs.remove(_kAvatar);
  }

  // ---- 主题 ----
  int get themeMode => _prefs.getInt(_kThemeMode) ?? 0;

  Future<void> setThemeMode(int v) async => _prefs.setInt(_kThemeMode, v);

  // ---- 搜索历史 ----
  List<String> get searchHistory => _prefs.getStringList(_kSearchHistory) ?? <String>[];

  Future<void> addSearchHistory(String q) async {
    final text = q.trim();
    if (text.isEmpty) return;
    final list = searchHistory;
    list.remove(text);
    list.insert(0, text);
    while (list.length > 20) {
      list.removeLast();
    }
    await _prefs.setStringList(_kSearchHistory, list);
  }

  Future<void> clearSearchHistory() async => _prefs.remove(_kSearchHistory);

  // ---- 下载记录 ----
  List<Map<String, dynamic>> get downloadRecords {
    final s = _prefs.getString(_kDownloadRecords);
    if (s == null || s.isEmpty) return <Map<String, dynamic>>[];
    try {
      final decoded = jsonDecode(s);
      if (decoded is List) {
        return decoded.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (_) {}
    return <Map<String, dynamic>>[];
  }

  Future<void> saveDownloadRecords(List<Map<String, dynamic>> records) async {
    await _prefs.setString(_kDownloadRecords, jsonEncode(records));
  }

  // ---- 其他 ----
  bool get deviceFilterEnabled => _prefs.getBool(_kDeviceFilter) ?? true;

  Future<void> setDeviceFilterEnabled(bool v) async => _prefs.setBool(_kDeviceFilter, v);

  String? get ignoredUpdate => _prefs.getString(_kIgnoredUpdate);

  Future<void> setIgnoredUpdate(String? v) async {
    if (v == null || v.isEmpty) {
      await _prefs.remove(_kIgnoredUpdate);
    } else {
      await _prefs.setString(_kIgnoredUpdate, v);
    }
  }

  String? get lastCheckinDate => _prefs.getString(_kLastCheckin);

  Future<void> setLastCheckinDate(String v) async => _prefs.setString(_kLastCheckin, v);
}
