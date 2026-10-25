import 'package:flutter/services.dart';

/// 与 Android 原生通信的平台通道
class DeviceBridge {
  DeviceBridge._();

  static final DeviceBridge instance = DeviceBridge._();

  static const MethodChannel _channel = MethodChannel('cn.oldpods.app/device');

  Map<String, dynamic>? _cachedInfo;

  Future<Map<String, dynamic>> info() async {
    if (_cachedInfo != null) return _cachedInfo!;
    try {
      final result = await _channel.invokeMethod<Object>('getDeviceInfo');
      if (result is Map) {
        _cachedInfo = Map<String, dynamic>.from(result);
      }
    } on PlatformException catch (_) {}
    _cachedInfo ??= <String, dynamic>{};
    return _cachedInfo!;
  }

  String get manufacturer => (_cachedInfo?['manufacturer'] ?? '').toString();
  String get brand => (_cachedInfo?['brand'] ?? '').toString();
  String get model => (_cachedInfo?['model'] ?? '').toString();
  String get device => (_cachedInfo?['device'] ?? '').toString();
  String get displayId => (_cachedInfo?['display_id'] ?? '').toString();
  String get androidVersion => (_cachedInfo?['android_version'] ?? '').toString();
  int get sdkInt {
    final v = _cachedInfo?['sdk_int'];
    if (v is int) return v;
    return int.tryParse('$v') ?? 24;
  }

  String get abi {
    final v = _cachedInfo?['abis'];
    if (v is List && v.isNotEmpty) return v.first.toString();
    return 'armeabi-v7a';
  }

  String get screen => (_cachedInfo?['screen'] ?? '').toString();

  int get density {
    final v = _cachedInfo?['density'];
    if (v is int) return v;
    return int.tryParse('$v') ?? 320;
  }

  String get label => 'Android $androidVersion; ${model.isEmpty ? 'Android' : model}';

  Future<Map<String, String>> versionInfo() async {
    try {
      final result = await _channel.invokeMethod<Object>('getVersionInfo');
      if (result is Map) {
        return Map<String, String>.from(result.map((k, v) => MapEntry(k.toString(), v.toString())));
      }
    } on PlatformException catch (_) {}
    return <String, String>{'versionName': '1.0.0', 'versionCode': '1'};
  }

  Future<String?> downloadDir() async {
    try {
      return await _channel.invokeMethod<String>('getDownloadDir');
    } on PlatformException catch (_) {
      return null;
    }
  }

  Future<bool> openApk(String path) async {
    try {
      return await _channel.invokeMethod<bool>('openApk', <String, Object>{'path': path}) ?? false;
    } on PlatformException catch (_) {
      return false;
    }
  }

  Future<bool> openUrl(String url) async {
    try {
      return await _channel.invokeMethod<bool>('openUrl', <String, Object>{'url': url}) ?? false;
    } on PlatformException catch (_) {
      return false;
    }
  }

  Future<String?> pickImage() async {
    try {
      return await _channel.invokeMethod<String>('pickImage');
    } on PlatformException catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> openDownloadBrowser(Map<String, Object> args) async {
    final result = await _channel.invokeMethod<Object>('openDownloadBrowser', args);
    return result is Map ? Map<String, dynamic>.from(result) : null;
  }

  Future<int> enqueueDownload(Map<String, Object> args) async =>
      await _channel.invokeMethod<int>('enqueueDownload', args) ?? (throw StateError('下载任务创建失败'));

  Future<List<Map<String, dynamic>>> listDownloads() async {
    final result = await _channel.invokeMethod<List<dynamic>>('listDownloads');
    return (result ?? <dynamic>[]).whereType<Map>().map((r) => Map<String, dynamic>.from(r)).toList();
  }

  Future<void> cancelDownload(int id) => _channel.invokeMethod<void>('cancelDownload', {'id': id});

  Future<void> forgetDownload(int id, {bool deleteFile = false}) =>
      _channel.invokeMethod<void>('forgetDownload', {'id': id, 'deleteFile': deleteFile});

  Future<void> clearWebSession() => _channel.invokeMethod<void>('clearWebSession');
}
