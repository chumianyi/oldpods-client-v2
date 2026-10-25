import 'dart:convert';

import 'package:http/http.dart' as http;

/// 蓝奏云分享链接解析器（对应规范第四部分：ajaxm.php / ajaxfile.php）
class LanzouResolver {
  LanzouResolver._();

  static final LanzouResolver instance = LanzouResolver._();

  static const String _ua =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.6261.95 Safari/537.36';

  final http.Client _client = http.Client();

  /// 判断是否为蓝奏云链接
  static bool isLanzouUrl(String url) {
    final lower = url.toLowerCase();
    return lower.contains('lanzou') || lower.contains('lanzoux') || lower.contains('lanzoup') || lower.contains('lanzo');
  }

  /// 解析蓝奏云分享链接为直链；失败时返回 null
  Future<String?> resolve(String shareUrl) async {
    try {
      final domain = Uri.parse(shareUrl);
      final origin = '${domain.scheme}://${domain.host}';

      // 1. 打开分享页，寻找 iframe（tp 页）地址
      final pageResp = await _client
          .get(Uri.parse(shareUrl), headers: <String, String>{'User-Agent': _ua, 'Referer': origin})
          .timeout(const Duration(seconds: 20));
      if (pageResp.statusCode != 200) return null;
      final html = pageResp.body;

      String? fid;
      String? iframeUrl;
      final iframeMatch = RegExp(r'''src\s*=\s*["']([^"']*?/tp/[^"']+)["']''', caseSensitive: false).firstMatch(html);
      if (iframeMatch != null) {
        iframeUrl = iframeMatch.group(1);
      }
      final fidMatch = RegExp(r'\?file=(\d+)').firstMatch(iframeUrl ?? '') ??
          RegExp(r'/tp/(\d+)').firstMatch(iframeUrl ?? '') ??
          RegExp(r'\?f=(\d+)').firstMatch(html) ??
          RegExp(r'/file/(\w{6,})').firstMatch(html);
      if (fidMatch != null) fid = fidMatch.group(1);
      if (fid == null || fid.isEmpty) return null;

      // 2. 打开 iframe 页面提取 sign
      final tpUrl = iframeUrl != null
          ? (iframeUrl.startsWith('http') ? iframeUrl : '$origin$iframeUrl')
          : '$origin/tp/$fid';
      final tpResp = await _client
          .get(Uri.parse(tpUrl), headers: <String, String>{'User-Agent': _ua, 'Referer': shareUrl})
          .timeout(const Duration(seconds: 20));
      final tpHtml = tpResp.body;
      String? sign;
      for (final pattern in <RegExp>[
        RegExp(r'''var\s+sign\s*=\s*['"]([\w]+)['"]'''),
        RegExp(r'''sign\s*[:=]\s*['"]([\w]+)['"]'''),
        RegExp(r'''var\s+sg\s*=\s*['"]([^'"]+)['"]'''),
      ]) {
        final m = pattern.firstMatch(tpHtml);
        if (m != null && m.group(1) != null && m.group(1)!.isNotEmpty) {
          sign = m.group(1);
          break;
        }
      }
      if (sign == null) return null;

      // 3. 新版接口 ajaxm.php
      final direct = await _tryAjaxm(origin, fid, sign) ?? await _tryAjaxfile(origin, fid, sign);
      return direct;
    } catch (_) {
      return null;
    }
  }

  Future<String?> _tryAjaxm(String origin, String fid, String sign) async {
    try {
      final resp = await _client
          .post(
            Uri.parse('$origin/ajaxm.php?file=$fid'),
            headers: <String, String>{
              'User-Agent': _ua,
              'Referer': '$origin/tp/$fid',
              'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
              'X-Requested-With': 'XMLHttpRequest',
            },
            body: <String, String>{
              'action': 'downprocess',
              'sign': sign,
              'kd': '0',
              'p': '1',
            },
          )
          .timeout(const Duration(seconds: 20));
      if (resp.statusCode != 200) return null;
      final json = jsonDecode(resp.body);
      if (json is Map && (json['zt'] == 1 || json['zt'] == '1')) {
        final dom = json['dom']?.toString() ?? '';
        final url = json['url']?.toString() ?? '';
        if (url.isEmpty) return null;
        if (dom.isEmpty) return url;
        return dom.startsWith('http') ? '$dom$url' : '$origin$url';
      }
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
      if (resp.statusCode != 200) return null;
      final json = jsonDecode(resp.body);
      if (json is Map && (json['zt'] == 1 || json['zt'] == '1')) {
        final dom = json['dom']?.toString() ?? '';
        if (dom.isEmpty) return null;
        return dom.startsWith('http') ? dom : '$origin$dom';
      }
    } catch (_) {}
    return null;
  }
}
