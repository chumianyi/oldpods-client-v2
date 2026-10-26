import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// API 异常
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

/// 统一响应包装
class ApiResponse {
  final int code;
  final String msg;
  final dynamic data;
  final String raw;

  ApiResponse({required this.code, required this.msg, this.data, required this.raw});

  bool get ok => code == 200;

  Map<String, dynamic>? get dataMap => data is Map ? Map<String, dynamic>.from(data as Map) : null;

  List<dynamic>? get dataList => data is List ? data as List : null;
}

/// HTTP 客户端：负责 Cookie 会话、通用请求头、api_key 传递。
class ApiClient {
  ApiClient._();

  static final ApiClient instance = ApiClient._();

  static const String baseUrl = 'http://oldpods.cn';
  static const String webUserAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.6261.95 Safari/537.36';
  static const String appVersion = '1.0.0';

  String? _cookie;
  String get sessionCookie => _cookie ?? '';
  String? apiKey;
  String deviceLabel = 'Android 7; Generic';
  bool _sessionReady = false;
  final http.Client _client = http.Client();

  static const Set<String> _cookieAttributes = {
    'expires',
    'path',
    'domain',
    'max-age',
    'samesite',
    'secure',
    'httponly',
    'comment',
    'version',
  };

  void setApiKey(String? key) {
    if (key != apiKey) {
      _cookie = null;
      _sessionReady = false;
    }
    apiKey = (key == null || key.isEmpty) ? null : key;
  }

  void setDeviceLabel(String label) {
    deviceLabel = label;
  }

  /// 供下载管理等场景复用请求头
  Map<String, String> requestHeaders({String? referer, bool post = false}) {
    final h = <String, String>{
      'User-Agent': webUserAgent,
      'X-App-Client': 'OldPods/$appVersion ($deviceLabel)',
      'Accept': '*/*',
      'Accept-Encoding': 'identity',
      'Referer': referer ?? '$baseUrl/',
    };
    if (post) h['Origin'] = baseUrl;
    if (_cookie != null && _cookie!.isNotEmpty) h['Cookie'] = _cookie!;
    if (apiKey != null && apiKey!.isNotEmpty) h['API-Key'] = apiKey!;
    return h;
  }

  Uri buildUri(String path, [Map<String, String>? params]) {
    final uri = Uri.parse('$baseUrl$path');
    final query = Map<String, String>.of(uri.queryParameters);
    if (params != null) {
      params.forEach((k, v) {
        if (v.isNotEmpty) query[k] = v;
      });
    }
    return uri.replace(queryParameters: query.isEmpty ? null : query);
  }

  Map<String, String> _headers({bool post = false}) {
    final h = <String, String>{
      'User-Agent': webUserAgent,
      'X-App-Client': 'OldPods/$appVersion ($deviceLabel)',
      'Accept': 'application/json, text/plain, */*',
      'Accept-Encoding': 'identity',
      'Referer': '$baseUrl/',
    };
    if (post) h['Origin'] = baseUrl;
    if (_cookie != null && _cookie!.isNotEmpty) h['Cookie'] = _cookie!;
    if (apiKey != null && apiKey!.isNotEmpty) h['API-Key'] = apiKey!;
    return h;
  }

  void _updateCookie(http.Response resp) {
    final setCookie = resp.headers['set-cookie'];
    if (setCookie == null || setCookie.isEmpty) return;
    final matches = RegExp(r'([A-Za-z0-9_%\-]+)=([^;,]*)').allMatches(setCookie);
    final cookies = <String, String>{};
    for (final part in (_cookie ?? '').split(';')) {
      final eq = part.indexOf('=');
      if (eq > 0) cookies[part.substring(0, eq).trim()] = part.substring(eq + 1);
    }
    for (final m in matches) {
      final name = m.group(1)!.toLowerCase();
      final value = m.group(2)!;
      if (_cookieAttributes.contains(name)) continue;
      if (value.isEmpty) {
        cookies.remove(m.group(1));
      } else {
        cookies[m.group(1)!] = value;
      }
    }
    if (cookies.isNotEmpty) {
      _cookie = cookies.entries.map((e) => '${e.key}=${e.value}').join('; ');
      _sessionReady = true;
    }
  }

  /// 启动时获取会话 Cookie
  Future<void> ensureSession({bool force = false}) async {
    if (_sessionReady && !force) return;
    try {
      final resp = await _client
          .get(buildUri('/'), headers: _headers())
          .timeout(const Duration(seconds: 15));
      _updateCookie(resp);
    } catch (_) {
      // 网络异常时静默，下次请求会重试
    }
  }

  Future<ApiResponse> get(
    String path, {
    Map<String, String>? params,
    bool withApiKey = true,
    Duration timeout = const Duration(seconds: 20),
  }) async {
    await ensureSession();
    final query = params != null ? Map<String, String>.of(params) : <String, String>{};
    if (withApiKey && apiKey != null && apiKey!.isNotEmpty && !query.containsKey('api_key')) {
      query['api_key'] = apiKey!;
    }
    final resp = await _client.get(buildUri(path, query), headers: _headers()).timeout(timeout);
    _updateCookie(resp);
    return _parse(resp);
  }

  Future<ApiResponse> post(
    String path, {
    Map<String, String>? body,
    bool withApiKey = true,
    bool apiKeyInUrl = false,
    Duration timeout = const Duration(seconds: 20),
  }) async {
    await ensureSession();
    final form = body != null ? Map<String, String>.of(body) : <String, String>{};
    final query = <String, String>{};
    if (withApiKey && apiKey != null && apiKey!.isNotEmpty) {
      if (apiKeyInUrl) {
        query['api_key'] = apiKey!;
      } else {
        form.putIfAbsent('api_key', () => apiKey!);
      }
    }
    final resp = await _client
        .post(buildUri(path, query.isEmpty ? null : query), headers: _headers(post: true), body: form)
        .timeout(timeout);
    _updateCookie(resp);
    return _parse(resp);
  }

  Future<ApiResponse> postMultipart(
    String path, {
    required Map<String, String> fields,
    List<http.MultipartFile> files = const [],
    bool withApiKey = true,
    bool apiKeyInUrl = false,
    Duration timeout = const Duration(seconds: 90),
  }) async {
    await ensureSession();
    final form = Map<String, String>.of(fields);
    final query = <String, String>{};
    if (withApiKey && apiKey != null && apiKey!.isNotEmpty) {
      if (apiKeyInUrl) {
        query['api_key'] = apiKey!;
      } else {
        form.putIfAbsent('api_key', () => apiKey!);
      }
    }
    final request = http.MultipartRequest('POST', buildUri(path, query.isEmpty ? null : query));
    request.headers.addAll(_headers(post: true));
    request.fields.addAll(form);
    request.files.addAll(files);
    final streamed = await _client.send(request).timeout(timeout);
    final resp = await http.Response.fromStream(streamed);
    _updateCookie(resp);
    return _parse(resp);
  }

  ApiResponse _parse(http.Response resp) {
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw ApiException('请求失败（HTTP ${resp.statusCode}）', statusCode: resp.statusCode);
    }
    try {
      final decoded = jsonDecode(resp.body);
      if (decoded is Map && decoded.containsKey('code')) {
        return ApiResponse(
          code: decoded['code'] is int ? decoded['code'] as int : int.tryParse('${decoded['code']}') ?? resp.statusCode,
          msg: decoded['msg']?.toString() ?? '',
          data: decoded['data'],
          raw: resp.body,
        );
      }
      return ApiResponse(code: resp.statusCode, msg: '', data: decoded, raw: resp.body);
    } catch (_) {
      throw ApiException('服务器返回异常（HTTP ${resp.statusCode}）', statusCode: resp.statusCode);
    }
  }

  void dispose() {
    _client.close();
  }
}
