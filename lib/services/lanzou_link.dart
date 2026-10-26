/// 蓝奏分享地址与提取码。第三方解析仅接收这两项，不携带站点登录信息。
class LanzouLink {
  final Uri url;
  final String password;
  const LanzouLink(this.url, [this.password = '']);

  static bool isLanzou(String value) {
    final match = RegExp(r'https?://[^\s]+').firstMatch(value);
    final uri = Uri.tryParse(match?.group(0) ?? value);
    if (uri == null) return false;
    return RegExp(r'(^|\.)(?:lanzou[a-z]*|lanzn|lanzv|lanzo)[.](?:com|cn)$', caseSensitive: false).hasMatch(uri.host);
  }

  factory LanzouLink.parse(String value, {String password = ''}) {
    final match = RegExp(r'https?://[^\s]+').firstMatch(value.trim());
    var address = match?.group(0) ?? value.trim();
    var code = password.trim();
    final inline = RegExp(r'(?:提取码|密码|pwd)\s*[:：=]?\s*([a-zA-Z0-9]+)', caseSensitive: false).firstMatch(value);
    if (code.isEmpty && inline != null) code = inline[1]!;
    final suffix = RegExp(r'^(.+)_([a-zA-Z0-9]{1,16})$').firstMatch(address);
    if (suffix != null && !address.contains('?')) {
      address = suffix[1]!;
      if (code.isEmpty) code = suffix[2]!;
    }
    final uri = Uri.tryParse(address);
    if (uri == null || !['http', 'https'].contains(uri.scheme) || uri.host.isEmpty || uri.userInfo.isNotEmpty || !isLanzou(address)) {
      throw const FormatException('未获取到有效的蓝奏云分享链接');
    }
    if (code.isEmpty) code = uri.queryParameters['pwd'] ?? uri.queryParameters['password'] ?? '';
    return LanzouLink(uri, code);
  }

  Uri get backupUrl => Uri(
    scheme: 'http', host: '103.236.99.177', port: 24512, path: '/iosipa/app',
    queryParameters: <String, String>{'lanzou_url': '${url.toString()}${password.isEmpty ? '' : '_$password'}'},
  );
}
