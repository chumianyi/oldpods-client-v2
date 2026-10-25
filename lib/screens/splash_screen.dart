import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/api_client.dart';
import '../services/api_service.dart';
import '../services/device_bridge.dart';
import '../services/download_manager.dart';
import '../services/storage.dart';
import '../state/app_state.dart';
import '../theme/neu_theme.dart';
import '../widgets/common.dart';
import '../widgets/neu.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String _status = '正在连接老豆荚…';

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      await ApiService.instance.initSession();
      if (!mounted) return;
      setState(() => _status = '正在同步设备信息…');
      await DeviceBridge.instance.info();
      ApiClient.instance.setDeviceLabel(DeviceBridge.instance.label);
      await _reportDevice();
      await AppState.instance.refreshUser();
      if (!mounted) return;
      setState(() => _status = '正在检查更新…');
      await _checkUpdate();
    } catch (_) {
      // 忽略启动异常，直接进入主界面
    }
    if (!mounted) return;
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/main');
  }

  Future<void> _reportDevice() async {
    if (!AppState.instance.loggedIn) return;
    try {
      final info = await DeviceBridge.instance.info();
      final abis = info['abis'];
      final abi = abis is List && abis.isNotEmpty ? abis.first.toString() : 'armeabi-v7a';
      final version = await DeviceBridge.instance.versionInfo();
      await ApiService.instance.reportDevice(<String, String>{
        'manufacturer': DeviceBridge.instance.manufacturer,
        'brand': DeviceBridge.instance.brand,
        'model': DeviceBridge.instance.model,
        'device': DeviceBridge.instance.device,
        'display_id': DeviceBridge.instance.displayId,
        'abi': abi,
        'android_version': DeviceBridge.instance.androidVersion,
        'sdk_int': '${DeviceBridge.instance.sdkInt}',
        'screen': DeviceBridge.instance.screen,
        'app_version': version['versionName'] ?? '1.0.0',
        'app_version_code': version['versionCode'] ?? '1',
        'density': '${DeviceBridge.instance.density}',
      });
    } catch (_) {}
  }

  Future<void> _checkUpdate() async {
    try {
      final version = await DeviceBridge.instance.versionInfo();
      final name = version['versionName'] ?? '1.0.0';
      final code = int.tryParse(version['versionCode'] ?? '1') ?? 1;
      final update = await ApiService.instance.checkUpdate(version: name, versionCode: code);
      if (!mounted) return;
      if (update.needUpdate && update.version != (Storage.instance.ignoredUpdate ?? '')) {
        await _showUpdateDialog(update);
      }
    } catch (_) {}
  }

  Future<void> _showUpdateDialog(CheckUpdate update) async {
    final p = NeuPalette.of(context);
    final go = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: Text(update.updateTitle, style: TextStyle(color: p.text, fontWeight: FontWeight.w300)),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('最新版本：${update.version}', style: TextStyle(color: p.accent, fontSize: 14, fontWeight: FontWeight.w300)),
              const SizedBox(height: 10),
              Flexible(
                child: SingleChildScrollView(
                  child: Text(
                    update.updateLog.join('\n'),
                    style: TextStyle(color: p.subText, fontSize: 13, height: 1.5),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: <Widget>[
          if (!update.forceUpdate)
            TextButton(
              onPressed: () {
                Storage.instance.setIgnoredUpdate(update.version);
                Navigator.pop(ctx, false);
              },
              child: Text('忽略此版本', style: TextStyle(color: p.subText)),
            ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('以后再说', style: TextStyle(color: p.subText)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('立即更新', style: TextStyle(color: p.accent, fontWeight: FontWeight.w300)),
          ),
        ],
      ),
    );
    if (go == true && update.downloadUrl.isNotEmpty) {
      if (!mounted) return;
      await DownloadManager.instance.browse(
        appId: 0, appTitle: '老豆荚 ${update.version}', url: update.downloadUrl,
        dark: Theme.of(context).brightness == Brightness.dark,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = NeuPalette.of(context);
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            NeuBox(
              radius: 36,
              width: 108,
              height: 108,
              padding: EdgeInsets.zero,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(36),
                child: Image.asset('assets/icon.png', width: 108, height: 108),
              ),
            ),
            const SizedBox(height: 24),
            Text('老豆荚', style: TextStyle(color: p.text, fontSize: 28, fontWeight: FontWeight.w300, letterSpacing: 2)),
            const SizedBox(height: 8),
            Text(_status, style: TextStyle(color: p.subText, fontSize: 13)),
            const SizedBox(height: 28),
            SizedBox(
              width: 120,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  minHeight: 8,
                  backgroundColor: p.shadowDark.withOpacity(0.3),
                  valueColor: AlwaysStoppedAnimation<Color>(p.accent),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
