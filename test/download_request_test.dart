import 'package:flutter_test/flutter_test.dart';
import 'package:oldpods_client/services/download_request.dart';

void main() {
  test('HTTP file metadata keeps filename and page origin', () {
    final request = DownloadRequest.fromMap({'url': 'https://files.example/app.apk',
      'sourceUrl': 'https://example/download', 'fileName': '应用.apk', 'mime': 'application/vnd.android.package-archive'});
    expect(request.fileName, '应用.apk');
    expect(request.sourceUrl, 'https://example/download');
    expect(request.cookie, isEmpty);
  });
  test('unsafe URLs do not create requests', () {
    for (final url in ['file:///a.apk', 'javascript:alert(1)', 'blob:https://site/id', 'https://user:pass@site/a.apk', 'https:///']) {
      expect(() => DownloadRequest.fromMap({'url': url}), throwsFormatException);
    }
  });
  test('HTML and JSON never masquerade as APK', () {
    for (final mime in ['text/html', 'application/json', 'Text/HTML; charset=utf-8']) {
      expect(() => DownloadRequest.fromMap({'url': 'https://site/file', 'mime': mime}), throwsFormatException);
    }
  });
  test('header injection is rejected', () {
    expect(() => DownloadRequest.fromMap({'url': 'https://site/a', 'cookie': 'a=b\r\nInjected: 1'}), throwsFormatException);
  });
  test('file names are sandbox safe and bounded', () {
    expect(DownloadRequest.safeFileName('../app.apk'), '_app.apk');
    expect(DownloadRequest.safeFileName('...'), 'download.bin');
    expect(DownloadRequest.safeFileName('x' * 200).length, 140);
  });
  test('unknown state fails closed', () {
    expect(parseDownloadStatus('completed'), DownloadStatus.completed);
    expect(parseDownloadStatus('downloading'), DownloadStatus.downloading);
    expect(parseDownloadStatus(null), DownloadStatus.failed);
  });
}
