import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'api_client.dart';
import 'device_bridge.dart';
import 'download_request.dart';
export 'download_request.dart' show DownloadStatus;

class DownloadTask {
  final int appId;
  final int nativeId;
  final String appTitle;
  final String url;
  final String sourceUrl;
  final String fileName;
  final String mime;
  DownloadStatus status;
  int received;
  int total;
  String? filePath;
  String? error;

  DownloadTask({required this.appId, required this.appTitle, required this.url,
    required this.fileName, this.nativeId = 0, this.sourceUrl = '', this.mime = '',
    this.status = DownloadStatus.queued, this.received = 0, this.total = 0,
    this.filePath, this.error});

  factory DownloadTask.fromMap(Map<String, dynamic> r) => DownloadTask(
    appId: (r['appId'] as num?)?.toInt() ?? 0,
    nativeId: (r['nativeId'] as num?)?.toInt() ?? 0,
    appTitle: '${r['appTitle'] ?? '文件'}', url: '${r['url'] ?? ''}',
    sourceUrl: '${r['sourceUrl'] ?? r['url'] ?? ''}', fileName: '${r['fileName'] ?? ''}',
    mime: '${r['mime'] ?? ''}', status: parseDownloadStatus(r['status']),
    received: (r['received'] as num?)?.toInt() ?? 0, total: (r['total'] as num?)?.toInt() ?? 0,
    filePath: r['filePath']?.toString(), error: r['error']?.toString());

  double get progress => total <= 0 ? 0 : (received / total).clamp(0.0, 1.0).toDouble();
  bool get isActive => [DownloadStatus.queued, DownloadStatus.resolving, DownloadStatus.downloading].contains(status);
  bool get isApk => fileName.toLowerCase().endsWith('.apk') || mime == 'application/vnd.android.package-archive';
}

/// WebView owns detection; Android owns transfer and persistence.
class DownloadManager extends ChangeNotifier with WidgetsBindingObserver {
  DownloadManager._();
  static final DownloadManager instance = DownloadManager._();
  final List<DownloadTask> _tasks = [];
  Timer? _poll;
  bool _refreshing = false;
  bool _initialized = false;
  bool _browserOpen = false;

  List<DownloadTask> get tasks => List.unmodifiable(_tasks);
  DownloadTask? taskOf(int appId) {
    for (final task in _tasks) { if (task.appId == appId) return task; }
    return null;
  }
  bool isActive(int appId) => _tasks.any((t) => t.appId == appId && t.isActive);

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    WidgetsBinding.instance.addObserver(this);
    await refresh();
    _startPolling();
  }
  void _startPolling() {
    _poll?.cancel();
    _poll = Timer.periodic(const Duration(seconds: 1), (_) => refresh());
  }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) { refresh(); _startPolling(); }
    else { _poll?.cancel(); }
  }
  Future<void> refresh() async {
    if (_refreshing) return;
    _refreshing = true;
    try {
      final rows = await DeviceBridge.instance.listDownloads();
      _tasks..clear()..addAll(rows.map(DownloadTask.fromMap));
      notifyListeners();
    } catch (e) { debugPrint('Download queue unavailable: ${e.runtimeType}'); }
    finally { _refreshing = false; }
  }

  Future<DownloadTask?> browse({required int appId, required String appTitle,
    required String url, bool dark = false}) async {
    if (_browserOpen) return null;
    _browserOpen = true;
    try {
      final uri = Uri.tryParse(url);
      if (uri == null || !['http', 'https'].contains(uri.scheme) || uri.host.isEmpty) {
        throw const FormatException('网页地址无效');
      }
      final api = ApiClient.instance;
      await api.ensureSession();
      final firstParty = uri.host.toLowerCase() == Uri.parse(ApiClient.baseUrl).host;
      final data = await DeviceBridge.instance.openDownloadBrowser({
        'url': url, 'dark': dark, 'userAgent': ApiClient.webUserAgent,
        'cookie': firstParty ? api.sessionCookie : '', 'apiKey': firstParty ? (api.apiKey ?? '') : '',
      });
      if (data == null) return null;
      final request = DownloadRequest.fromMap(data);
      // De-duplicate double callbacks without replacing another file of this app.
      for (final t in _tasks) { if (t.url == request.url && t.isActive) return t; }
      final id = await DeviceBridge.instance.enqueueDownload({
        ...request.toMap(), 'appId': appId, 'appTitle': appTitle,
      });
      await refresh();
      for (final t in _tasks) { if (t.nativeId == id) return t; }
      return DownloadTask(appId: appId, nativeId: id, appTitle: appTitle,
        url: request.url, sourceUrl: request.sourceUrl, fileName: request.fileName, mime: request.mime);
    } finally { _browserOpen = false; }
  }

  // Compatibility for old call sites: never start transfer without WebView confirmation.
  Future<DownloadTask?> start({required int appId, required String appTitle, required String url}) =>
      browse(appId: appId, appTitle: appTitle, url: url);

  Future<void> cancelTask(DownloadTask task) async {
    await DeviceBridge.instance.cancelDownload(task.nativeId); await refresh();
  }
  Future<void> forgetTask(DownloadTask task, {bool deleteFile = false}) async {
    if (task.isActive && !deleteFile) throw StateError('请先取消正在进行的下载');
    await DeviceBridge.instance.forgetDownload(task.nativeId, deleteFile: deleteFile); await refresh();
  }
  Future<void> cancel(int appId) async {
    final task = taskOf(appId); if (task != null) await cancelTask(task);
  }
  Future<void> remove(int appId) async {
    final task = taskOf(appId); if (task != null) await forgetTask(task);
  }
  Future<void> clearFinishedRecords() async {
    for (final t in List<DownloadTask>.of(_tasks).where((t) => !t.isActive)) {
      await DeviceBridge.instance.forgetDownload(t.nativeId);
    }
    await refresh();
  }
  Future<bool> open(DownloadTask task) async {
    final path = task.filePath;
    if (!task.isApk || path == null || !File(path).existsSync()) return false;
    return DeviceBridge.instance.openApk(path);
  }
}
