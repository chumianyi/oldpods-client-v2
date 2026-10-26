import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../services/api_service.dart';
import '../services/device_bridge.dart';
import '../state/app_state.dart';
import '../theme/neu_theme.dart';
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
      setState(() => _status = '准备就绪');
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
