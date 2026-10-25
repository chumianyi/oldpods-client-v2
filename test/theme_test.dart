import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oldpods_client/theme/neu_theme.dart';
import 'package:oldpods_client/widgets/neu.dart';

void main() {
  test('both themes use bundled WenKai Light', () {
    for (final theme in [NeuTheme.light(), NeuTheme.dark()]) {
      expect(theme.textTheme.bodyMedium?.fontFamily, 'LXGW WenKai');
      expect(theme.textTheme.bodyMedium?.height, greaterThan(1));
      expect(theme.textTheme.bodyMedium?.letterSpacing, greaterThan(0));
    }
  });
  testWidgets('icon target is at least 44 logical pixels', (tester) async {
    await tester.pumpWidget(MaterialApp(theme: NeuTheme.light(), home: Scaffold(body: Center(
      child: NeuIconButton(icon: Icons.close, size: 32, onPressed: () {})))));
    expect(tester.getSize(find.byType(NeuBox)).width, greaterThanOrEqualTo(44));
  });
  testWidgets('long button title does not overflow a narrow card', (tester) async {
    await tester.pumpWidget(MaterialApp(theme: NeuTheme.light(), home: Scaffold(body: Center(
      child: SizedBox(width: 180, child: NeuButton(text: '下载适合当前设备的完整应用版本', icon: Icons.download, onPressed: () {}))))));
    expect(tester.takeException(), isNull);
  });
}
