enum DownloadStatus { queued, resolving, downloading, completed, failed, canceled }

class DownloadRequest {
  final String url;
  final String sourceUrl;
  final String fileName;
  final String mime;
  final String cookie;
  final String userAgent;
  final String referer;

  const DownloadRequest({required this.url, required this.sourceUrl, required this.fileName,
    required this.mime, this.cookie = '', this.userAgent = '', this.referer = ''});

  factory DownloadRequest.fromMap(Map<String, dynamic> data) {
    final url = '${data['url'] ?? ''}';
    final uri = Uri.tryParse(url);
    if (uri == null || !['http', 'https'].contains(uri.scheme) || uri.host.isEmpty || uri.userInfo.isNotEmpty) {
      throw const FormatException('不支持的下载地址');
    }
    final mime = '${data['mime'] ?? 'application/octet-stream'}';
    if (mime.toLowerCase().contains('text/html') || mime.toLowerCase().contains('application/json')) {
      throw const FormatException('下载响应不是文件');
    }
    for (final key in ['cookie', 'userAgent', 'referer']) {
      if ('${data[key] ?? ''}'.contains(RegExp(r'[\r\n]'))) throw const FormatException('非法请求头');
    }
    return DownloadRequest(url: url, sourceUrl: '${data['sourceUrl'] ?? url}',
      fileName: safeFileName('${data['fileName'] ?? 'download.bin'}'), mime: mime,
      cookie: '${data['cookie'] ?? ''}', userAgent: '${data['userAgent'] ?? ''}', referer: '${data['referer'] ?? ''}');
  }

  static String safeFileName(String name) {
    final value = name.replaceAll(RegExp(r'[\\/:*?"<>|\x00-\x1f]'), '_').trim().replaceAll(RegExp(r'^\.+|\.+$'), '');
    if (value.isEmpty) return 'download.bin';
    return value.length > 140 ? value.substring(0, 140) : value;
  }

  Map<String, Object> toMap() => {'url': url, 'sourceUrl': sourceUrl, 'fileName': fileName,
    'mime': mime, 'cookie': cookie, 'userAgent': userAgent, 'referer': referer};
}

DownloadStatus parseDownloadStatus(Object? value) => DownloadStatus.values.firstWhere(
  (s) => s.name == value, orElse: () => DownloadStatus.failed);
