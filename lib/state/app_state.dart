import 'package:flutter/foundation.dart';

import '../models/models.dart';
import '../services/api_client.dart';
import '../services/api_service.dart';
import '../services/device_bridge.dart';
import '../services/storage.dart';

/// 全局应用状态
class AppState extends ChangeNotifier {
  AppState._();

  static final AppState instance = AppState._();

  final ApiClient _client = ApiClient.instance;
  final ApiService _api = ApiService.instance;

  bool _loggedIn = false;
  bool get loggedIn => _loggedIn;

  String? _apiKey;
  String? get apiKey => _apiKey;

  int userId = 0;
  String? nickname;
  String? avatar;

  int _unread = 0;
  int get unread => _unread;

  int _themeMode = 0; // 0=跟随系统 1=浅色 2=深色
  int get themeMode => _themeMode;
  bool get darkMode => _themeMode == 2;

  UserInfo? userInfo;

  Future<void> init() async {
    _apiKey = Storage.instance.apiKey;
    userId = Storage.instance.userId;
    nickname = Storage.instance.nickname;
    avatar = Storage.instance.avatar;
    _themeMode = Storage.instance.themeMode;
    _loggedIn = _apiKey != null && _apiKey!.isNotEmpty;
    _client.setApiKey(_apiKey);
    _api.myUserId = userId;
    _loadDeviceLabel();
    notifyListeners();
  }

  Future<void> _loadDeviceLabel() async {
    try {
      await DeviceBridge.instance.info();
      _client.setDeviceLabel(DeviceBridge.instance.label);
    } catch (_) {}
  }

  void setThemeMode(int mode) {
    _themeMode = mode;
    Storage.instance.setThemeMode(mode);
    notifyListeners();
  }

  Future<void> applyLogin({
    required String apiKey,
    int? userId,
    String? nickname,
    String? avatar,
    String? email,
  }) async {
    _apiKey = apiKey;
    _loggedIn = true;
    _client.setApiKey(apiKey);
    await Storage.instance.setApiKey(apiKey);
    if (email != null && email.isNotEmpty) await Storage.instance.setEmail(email);
    this.userId = userId ?? this.userId;
    this.nickname = nickname ?? this.nickname;
    this.avatar = avatar ?? this.avatar;
    if (userId != null) await Storage.instance.setUserId(userId);
    if (nickname != null) await Storage.instance.setNickname(nickname);
    if (avatar != null) await Storage.instance.setAvatar(avatar);
    _api.myUserId = this.userId;
    notifyListeners();
    refreshUnread();
  }

  Future<void> refreshUser() async {
    if (!_loggedIn) return;
    try {
      final info = await _api.currentUser();
      userInfo = info;
      if (info.userId > 0) userId = info.userId;
      if (info.nickname.isNotEmpty) nickname = info.nickname;
      if (info.avatar.isNotEmpty) avatar = info.avatar;
      if (info.userId > 0) await Storage.instance.setUserId(info.userId);
      if (info.nickname.isNotEmpty) await Storage.instance.setNickname(info.nickname);
      if (info.avatar.isNotEmpty) await Storage.instance.setAvatar(info.avatar);
      _api.myUserId = userId;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> refreshUnread() async {
    if (!_loggedIn) {
      if (_unread != 0) {
        _unread = 0;
        notifyListeners();
      }
      return;
    }
    try {
      final count = await _api.unreadCount();
      if (count != _unread) {
        _unread = count;
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> logout() async {
    _apiKey = null;
    _loggedIn = false;
    userId = 0;
    nickname = null;
    avatar = null;
    userInfo = null;
    _unread = 0;
    _client.setApiKey(null);
    _api.myUserId = 0;
    try { await DeviceBridge.instance.clearWebSession(); } catch (_) {}
    await Storage.instance.clearAccount();
    notifyListeners();
  }
}
