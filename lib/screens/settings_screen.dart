import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/api_service.dart';
import '../services/device_bridge.dart';
import '../services/download_manager.dart';
import '../services/storage.dart';
import '../state/app_state.dart';
import '../theme/neu_theme.dart';
import '../widgets/common.dart';
import '../widgets/neu.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ApiService _api = ApiService.instance;

  bool _deviceFilter = true;
  String _versionName = '1.0.0';
  String _versionCode = '1';
  bool _checking = false;
  int _activeDownloads = 0;

  @override
  void initState() {
    super.initState();
    _deviceFilter = Storage.instance.deviceFilterEnabled;
    _loadVersion();
    _refreshActive();
  }

  void _refreshActive() {
    _activeDownloads = DownloadManager.instance.tasks.where((t) => t.isActive).length;
  }

  Future<void> _loadVersion() async {
    final info = await DeviceBridge.instance.versionInfo();
    if (!mounted) return;
    setState(() {
      _versionName = info['versionName'] ?? _versionName;
      _versionCode = info['versionCode'] ?? _versionCode;
    });
  }

  void _setThemeMode(int mode) {
    AppState.instance.setThemeMode(mode);
  }

  Future<void> _toggleDeviceFilter(bool value) async {
    setState(() => _deviceFilter = value);
    await Storage.instance.setDeviceFilterEnabled(value);
    try {
      await _api.setDeviceFilter(value);
    } catch (_) {}
    if (!mounted) return;
    showToast(context, value ? '已开启设备过滤' : '已关闭设备过滤');
  }

  Future<void> _clearCache() async {
    final ok = await confirmDialog(
      context,
      title: '清除缓存',
      content: '将清除搜索历史与下载记录，不影响已下载的文件。确定继续吗？',
      confirmText: '清除',
    );
    if (!ok) return;
    await Storage.instance.clearSearchHistory();
    await Storage.instance.saveDownloadRecords(<Map<String, dynamic>>[]);
    await DownloadManager.instance.clearFinishedRecords();
    if (!mounted) return;
    showToast(context, '缓存已清除');
  }

  Future<void> _checkUpdate() async {
    if (_checking) return;
    setState(() => _checking = true);
    try {
      final CheckUpdate update = await _api.checkUpdate(
        version: _versionName,
        versionCode: int.tryParse(_versionCode) ?? 1,
      );
      if (!mounted) return;
      setState(() => _checking = false);
      if (!update.needUpdate) {
        showToast(context, '已是最新版本');
        return;
      }
      _showUpdateDialog(update);
    } catch (e) {
      if (!mounted) return;
      setState(() => _checking = false);
      showToast(context, '检查更新失败：$e');
    }
  }

  void _showUpdateDialog(CheckUpdate update) {
    final p = NeuPalette.of(context);
    showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: p.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: Text(
            update.updateTitle.isEmpty ? '发现新版本' : update.updateTitle,
            style: TextStyle(color: p.text, fontSize: 17, fontWeight: FontWeight.w300),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: <Widget>[
                  MetaTag(text: '当前 $_versionName', color: p.subText),
                  MetaTag(text: '最新 ${update.version}', color: p.accent),
                ],
              ),
              if (update.updateLog.isNotEmpty) ...<Widget>[
                const SizedBox(height: 12),
                ...update.updateLog.map((String log) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text('· ', style: TextStyle(color: p.accent, fontSize: 13.5)),
                        Expanded(
                          child: Text(log, style: TextStyle(color: p.subText, fontSize: 13.5, height: 1.5)),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ],
          ),
          actions: <Widget>[
            if (!update.forceUpdate)
              TextButton(
                onPressed: () async {
                  await Storage.instance.setIgnoredUpdate(update.version);
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: Text('忽略此版本', style: TextStyle(color: p.subText)),
              ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('以后再说', style: TextStyle(color: p.subText)),
            ),
            if (update.downloadUrl.isNotEmpty)
              TextButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  try {
                    final task = await DownloadManager.instance.browse(
                      appId: 0, appTitle: '老豆荚 ${update.version}', url: update.downloadUrl,
                      dark: Theme.of(context).brightness == Brightness.dark,
                    );
                    if (mounted && task != null) Navigator.pushNamed(context, '/downloads');
                  } catch (e) {
                    if (mounted) showToast(context, '更新下载未开始：$e');
                  }
                },
                child: Text('立即更新', style: TextStyle(color: p.accent, fontWeight: FontWeight.w300)),
              ),
          ],
        );
      },
    );
  }

  Future<void> _logout() async {
    final ok = await confirmDialog(
      context,
      title: '退出登录',
      content: '确定要退出当前账号吗？',
      confirmText: '退出',
    );
    if (!ok) return;
    await AppState.instance.logout();
    if (!mounted) return;
    showToast(context, '已退出登录');
  }

  Future<void> _deleteAccount() async {
    final controller = TextEditingController();
    final p = NeuPalette.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: p.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: Text('注销账号', style: TextStyle(color: p.text, fontSize: 17, fontWeight: FontWeight.w300)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                '注销后账号数据将无法恢复，请输入登录密码确认操作。',
                style: TextStyle(color: p.subText, fontSize: 13, height: 1.6),
              ),
              const SizedBox(height: 14),
              NeuTextField(
                controller: controller,
                hint: '登录密码',
                obscure: true,
                prefixIcon: Icons.lock_outline,
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('取消', style: TextStyle(color: p.subText)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('确认注销', style: TextStyle(color: p.danger, fontWeight: FontWeight.w300)),
            ),
          ],
        );
      },
    );
    final password = controller.text;
    controller.dispose();
    if (ok != true || password.isEmpty) return;
    try {
      await _api.deleteAccount(password);
      await AppState.instance.logout();
      if (!mounted) return;
      showToast(context, '账号已注销');
    } catch (e) {
      if (!mounted) return;
      showToast(context, '注销失败：$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = NeuPalette.of(context);
    return AnimatedBuilder(
      animation: AppState.instance,
      builder: (context, _) {
        final loggedIn = AppState.instance.loggedIn;
        return Scaffold(
          appBar: NeuAppBar(
            title: '设置',
            leading: NeuIconButton(icon: Icons.arrow_back, size: 40, onPressed: () => Navigator.pop(context)),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
            children: <Widget>[
              _sectionLabel('外观'),
              NeuBox(
                radius: 20,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Icon(Icons.palette_outlined, color: p.accent, size: 20),
                        const SizedBox(width: 10),
                        Text('主题模式', style: TextStyle(color: p.text, fontSize: 14.5, fontWeight: FontWeight.w300)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    NeuSegmented<int>(
                      values: const <int>[0, 1, 2],
                      labels: const <String>['跟随系统', '浅色', '深色'],
                      value: AppState.instance.themeMode,
                      onChanged: _setThemeMode,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _sectionLabel('通用'),
              NeuBox(
                radius: 20,
                padding: const EdgeInsets.all(6),
                child: Column(
                  children: <Widget>[
                    _settingRow(
                      icon: Icons.phone_android_outlined,
                      title: '设备过滤',
                      subtitle: '只展示与当前设备兼容的应用',
                      trailing: NeuSwitch(value: _deviceFilter, onChanged: _toggleDeviceFilter),
                    ),
                    _divider(),
                    _settingRow(
                      icon: Icons.download_outlined,
                      title: '我的下载',
                      subtitle: _activeDownloads > 0 ? '$_activeDownloads 个任务进行中' : '管理下载任务',
                      onTap: () => Navigator.pushNamed(context, '/downloads'),
                    ),
                    _divider(),
                    _settingRow(
                      icon: Icons.cleaning_services_outlined,
                      title: '清除缓存',
                      subtitle: '搜索历史与下载记录',
                      onTap: _clearCache,
                    ),
                    _divider(),
                    _settingRow(
                      icon: Icons.system_update_outlined,
                      title: '检查更新',
                      subtitle: '当前版本 $_versionName',
                      trailing: _checking
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: p.accent),
                            )
                          : Icon(Icons.chevron_right, color: p.subText),
                      onTap: _checkUpdate,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _sectionLabel('关于'),
              NeuBox(
                radius: 20,
                padding: const EdgeInsets.all(6),
                child: Column(
                  children: <Widget>[
                    _settingRow(
                      icon: Icons.description_outlined,
                      title: '用户协议',
                      onTap: () => Navigator.pushNamed(context, '/terms'),
                    ),
                    _divider(),
                    _settingRow(
                      icon: Icons.public_outlined,
                      title: '访问官网',
                      subtitle: 'oldpods.cn',
                      onTap: () => DeviceBridge.instance.openUrl('http://oldpods.cn'),
                    ),
                    _divider(),
                    _settingRow(
                      icon: Icons.info_outline,
                      title: '关于老豆荚',
                      subtitle: 'OldPods 客户端 v$_versionName (${_versionCode})',
                      onTap: _showAbout,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              if (loggedIn) ...<Widget>[
                _sectionLabel('账号'),
                NeuBox(
                  radius: 20,
                  padding: const EdgeInsets.all(6),
                  child: Column(
                    children: <Widget>[
                      _settingRow(
                        icon: Icons.logout_outlined,
                        title: '退出登录',
                        iconColor: p.warning,
                        onTap: _logout,
                      ),
                      _divider(),
                      _settingRow(
                        icon: Icons.person_off_outlined,
                        title: '注销账号',
                        iconColor: p.danger,
                        onTap: _deleteAccount,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _showAbout() {
    final p = NeuPalette.of(context);
    showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: p.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 72,
                height: 72,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: p.surface,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: <BoxShadow>[
                    BoxShadow(color: p.shadowDark, offset: const Offset(3, 3), blurRadius: 8, spreadRadius: -2),
                    BoxShadow(color: p.shadowLight, offset: const Offset(-3, -3), blurRadius: 8, spreadRadius: -2),
                  ],
                ),
                child: Image.asset('assets/icon.png'),
              ),
              const SizedBox(height: 14),
              Text('老豆荚', style: TextStyle(color: p.text, fontSize: 18, fontWeight: FontWeight.w300)),
              const SizedBox(height: 4),
              Text(
                'OldPods v$_versionName (${_versionCode})\n最低支持 Android 7.0',
                textAlign: TextAlign.center,
                style: TextStyle(color: p.subText, fontSize: 12.5, height: 1.7),
              ),
              const SizedBox(height: 10),
              Text(
                '本客户端基于老豆荚开放接口制作，\n仅供学习交流使用。',
                textAlign: TextAlign.center,
                style: TextStyle(color: p.subText, fontSize: 12, height: 1.7),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('关闭', style: TextStyle(color: p.accent)),
            ),
          ],
        );
      },
    );
  }

  Widget _sectionLabel(String text) {
    final p = NeuPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 6, bottom: 10),
      child: Text(text, style: TextStyle(color: p.subText, fontSize: 12.5, fontWeight: FontWeight.w300)),
    );
  }

  Widget _divider() {
    final p = NeuPalette.of(context);
    return Divider(height: 1, thickness: 1, color: p.shadowDark.withOpacity(0.25), indent: 56);
  }

  Widget _settingRow({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    Color? iconColor,
    VoidCallback? onTap,
  }) {
    final p = NeuPalette.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        child: Row(
          children: <Widget>[
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: p.surface,
                borderRadius: BorderRadius.circular(10),
                boxShadow: <BoxShadow>[
                  BoxShadow(color: p.shadowDark, offset: const Offset(1.5, 1.5), blurRadius: 4, spreadRadius: -1),
                  BoxShadow(color: p.shadowLight, offset: const Offset(-1.5, -1.5), blurRadius: 4, spreadRadius: -1),
                ],
              ),
              child: Icon(icon, size: 18, color: iconColor ?? p.accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(title, style: TextStyle(color: p.text, fontSize: 14.5, fontWeight: FontWeight.w300)),
                  if (subtitle != null && subtitle.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 2),
                    Text(subtitle, style: TextStyle(color: p.subText, fontSize: 11.5)),
                  ],
                ],
              ),
            ),
            if (trailing != null) trailing else const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }
}
