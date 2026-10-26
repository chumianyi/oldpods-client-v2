import 'dart:convert';

import 'package:http/http.dart' as http;
import 'lanzou_link.dart';

/// 蓝奏云分享链接解析器（对应规范第四部分：ajaxm.php / ajaxfile.php）
class LanzouResolver {
  LanzouResolver._();

  static final LanzouResolver instance = LanzouResolver._();

  static const String _ua =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.6261.95 Safari/537.36';

  final http.Client _client = http.Client();

  /// 判断是否为蓝奏云链接
  static bool isLanzouUrl(String url) {
    return LanzouLink.isLanzou(url);
  }

  /// 解析蓝奏云分享链接为直链；失败时返回 null
  Future<String?> resolve(String shareUrl, {String password = ''}) async {
    try {
      final link = LanzouLink.parse(shareUrl, password: password);
      shareUrl = link.url.toString();
      final domain = link.url;
      final origin = '${domain.scheme}://${domain.host}';

      // 1. 打开分享页，寻找 iframe（tp 页）地址
      final pageResp = await _client
          .get(Uri.parse(shareUrl), headers: <String, String>{'User-Agent': _ua, 'Referer': origin})
          .timeout(const Duration(seconds: 20));
      if (pageResp.statusCode != 200) return null;
      final html = pageResp.body;
      if (link.password.isNotEmpty) {
        final sign = RegExp(r'''['"]?sign['"]?\s*[:=]\s*['"]([^'"]+)['"]''').firstMatch(html)?.group(1);
        if (sign != null) {
          final result = await _client.post(domain.resolve('/ajaxm.php'), headers: <String, String>{
            'User-Agent': _ua, 'Referer': shareUrl, 'X-Requested-With': 'XMLHttpRequest',
          }, body: <String, String>{'action': 'downprocess', 'sign': sign, 'p': link.password})
            .timeout(const Duration(seconds: 20));
          final direct = _directUrl(result, origin);
          if (direct != null) return direct;
        }
      }

      String? fid;
      String? iframeUrl;
      final iframeMatch = RegExp(r'''<iframe[^>]*\bsrc\s*=\s*["']([^"']+)["']''', caseSensitive: false).firstMatch(html);
      if (iframeMatch != null) {
        iframeUrl = iframeMatch.group(1);
      }
      final fidMatch = RegExp(r'\?file=(\d+)').firstMatch(iframeUrl ?? '') ??
          RegExp(r'/tp/(\d+)').firstMatch(iframeUrl ?? '') ??
          RegExp(r'ajaxm\.php\?file=(\d+)').firstMatch(html) ??
          RegExp(r'\?f=(\d+)').firstMatch(html) ??
          RegExp(r'/file/(\w{6,})').firstMatch(html);
      if (fidMatch != null) fid = fidMatch.group(1);
      if ((fid == null || fid.isEmpty) && iframeUrl == null) return null;

      // 2. 打开 iframe 页面提取 sign
      final tpUrl = iframeUrl != null
          ? domain.resolve(iframeUrl.replaceAll('&amp;', '&')).toString()
          : '$origin/tp/$fid';
      final tpResp = await _client
          .get(Uri.parse(tpUrl), headers: <String, String>{'User-Agent': _ua, 'Referer': shareUrl})
          .timeout(const Duration(seconds: 20));
      final tpHtml = tpResp.body;
      if (tpResp.statusCode != 200) return null;
      fid ??= RegExp(r'ajaxm\.php\?file=(\d+)').firstMatch(tpHtml)?.group(1);
      if (fid == null || fid.isEmpty) return null;
      String? sign;
      for (final pattern in <RegExp>[
        RegExp(r'''var\s+sign\s*=\s*['"]([\w]+)['"]'''),
        RegExp(r'''sign\s*[:=]\s*['"]([\w]+)['"]'''),
        RegExp(r'''var\s+sg\s*=\s*['"]([^'"]+)['"]'''),
        RegExp(r'''var\s+(?:ajaxdata|wp_sign|ws_sign)\s*=\s*['"]([^'"]+)['"]'''),
      ]) {
        final m = pattern.firstMatch(tpHtml);
        if (m != null && m.group(1) != null && m.group(1)!.isNotEmpty) {
          sign = m.group(1);
          break;
        }
      }
      if (sign == null) return null;

      // 3. 新版接口 ajaxm.php
      final direct = await _tryAjaxm(origin, fid, sign, tpUrl) ?? await _tryAjaxfile(origin, fid, sign);
      return direct;
    } catch (_) {
      return null;
    }
  }

  Future<String?> _tryAjaxm(String origin, String fid, String sign, String referer) async {
    try {
      final resp = await _client
          .post(
            Uri.parse('$origin/ajaxm.php?file=$fid'),
            headers: <String, String>{
              'User-Agent': _ua,
              'Referer': referer,
              'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
              'X-Requested-With': 'XMLHttpRequest',
            },
            body: <String, String>{
              'action': 'downprocess',
              'sign': sign,
              'kd': '0',
              'ves': '1',
            },
          )
          .timeout(const Duration(seconds: 20));
      return _directUrl(resp, origin);
    } catch (_) {}
    return null;
  }

  Future<String?> _tryAjaxfile(String origin, String fid, String sign) async {
    try {
      final resp = await _client
          .post(
            Uri.parse('$origin/ajaxfile.php?file=$fid'),
            headers: <String, String>{
              'User-Agent': _ua,
              'Referer': '$origin/tp/$fid',
              'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
              'X-Requested-With': 'XMLHttpRequest',
            },
            body: <String, String>{
              'action': 'downprocess',
              'sign': sign,
            },
          )
          .timeout(const Duration(seconds: 20));
      return _directUrl(resp, origin);
    } catch (_) {}
    return null;
  }

  String? _directUrl(http.Response response, String origin) {
    if (response.statusCode != 200) return null;
    final data = jsonDecode(response.body);
    if (data is! Map || '${data['zt']}' != '1') return null;
    final token = '${data['url'] ?? ''}'.trim();
    final dom = '${data['dom'] ?? ''}'.trim();
    if (token.isEmpty || token == '0') return null;
    String result;
    if (token.startsWith('http://') || token.startsWith('https://')) {
      result = token;
    } else if (dom.isNotEmpty) {
      final base = dom.startsWith('//') ? '${Uri.parse(origin).scheme}:$dom' : dom;
      final host = base.startsWith('http') ? base : 'https://$base';
      result = '${host.replaceFirst(RegExp(r'/+$'), '')}/${token.startsWith('/') ? token.substring(1) : 'file/$token'}';
    } else {
      return null;
    }
    final uri = Uri.tryParse(result);
    return uri != null && ['http', 'https'].contains(uri.scheme) && uri.host.isNotEmpty && uri.userInfo.isEmpty ? result : null;
  }
}
