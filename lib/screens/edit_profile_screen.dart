import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../services/api_service.dart';
import '../services/device_bridge.dart';
import '../services/storage.dart';
import '../state/app_state.dart';
import '../theme/neu_theme.dart';
import '../widgets/common.dart';
import '../widgets/neu.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final ApiService _api = ApiService.instance;
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();

  bool _deviceFilter = true;
  String _filterOs = 'android';
  String _filterOsVersion = '';
  String _filterArch = '';
  bool _saving = false;
  bool _uploading = false;
  bool _dirty = false;

  static const List<Map<String, String>> _osOptions = <Map<String, String>>[
    <String, String>{'key': 'android', 'label': 'Android'},
    <String, String>{'key': 'all', 'label': '不限制'},
  ];

  @override
  void initState() {
    super.initState();
    _nicknameController.text = AppState.instance.nickname ?? '';
    _bioController.text = AppState.instance.userInfo?.bio ?? '';
    _deviceFilter = Storage.instance.deviceFilterEnabled;
    _filterOs = 'android';
    _filterOsVersion = DeviceBridge.instance.androidVersion;
    _filterArch = DeviceBridge.instance.abi;
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final path = await DeviceBridge.instance.pickImage();
    if (path == null) return;
    setState(() => _uploading = true);
    try {
      await _api.uploadAvatar(path);
      showToast(context, '头像已更新');
      await AppState.instance.refreshUser();
    } on ApiException catch (e) {
      showToast(context, e.message);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _save() async {
    final nickname = _nicknameController.text.trim();
    final bio = _bioController.text.trim();
    if (nickname.isEmpty) {
      showToast(context, '昵称不能为空');
      return;
    }
    setState(() => _saving = true);
    try {
      await _api.updateProfile(
        nickname: nickname,
        bio: bio,
        deviceFilterEnabled: _deviceFilter,
        deviceFilterOs: _filterOs,
        deviceFilterOsVersion: _filterOsVersion,
        deviceFilterArch: _filterArch,
      );
      await Storage.instance.setDeviceFilterEnabled(_deviceFilter);
      await AppState.instance.refreshUser();
      if (!mounted) return;
      showToast(context, '已保存');
      setState(() => _dirty = false);
    } on ApiException catch (e) {
      if (mounted) showToast(context, e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = NeuPalette.of(context);
    final info = AppState.instance.userInfo;
    return Scaffold(
      appBar: NeuAppBar(
        title: '编辑资料',
        leading: NeuIconButton(icon: Icons.arrow_back, size: 40, onPressed: () => Navigator.pop(context)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
        children: <Widget>[
          Center(
            child: Stack(
              children: <Widget>[
                AvatarFrame(
                  avatar: AppState.instance.avatar,
                  frame: info?.frame,
                  frameW: info?.frameW ?? 100,
                  frameX: info?.frameX ?? 0,
                  frameY: info?.frameY ?? 0,
                  size: 88,
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: GestureDetector(
                    onTap: _uploading ? null : _pickAvatar,
                    child: NeuBox(
                      radius: 18,
                      width: 34,
                      height: 34,
                      padding: EdgeInsets.zero,
                      color: p.accent,
                      child: _uploading
                          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Center(child: Text('点击相机图标更换头像', style: TextStyle(color: p.subText, fontSize: 11.5))),
          const SizedBox(height: 20),
          NeuBox(
            radius: 22,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('基本资料', style: TextStyle(color: p.text, fontSize: 15, fontWeight: FontWeight.w300)),
                const SizedBox(height: 14),
                Text('昵称', style: TextStyle(color: p.subText, fontSize: 12.5)),
                const SizedBox(height: 6),
                NeuTextField(
                  controller: _nicknameController,
                  hint: '请输入昵称',
                  prefixIcon: Icons.person_outline,
                  maxLength: 20,
                  onChanged: (_) => _dirty = true,
                ),
                const SizedBox(height: 12),
                Text('个人简介', style: TextStyle(color: p.subText, fontSize: 12.5)),
                const SizedBox(height: 6),
                NeuTextField(
                  controller: _bioController,
                  hint: '介绍一下自己吧',
                  maxLines: 4,
                  maxLength: 100,
                  onChanged: (_) => _dirty = true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          NeuBox(
            radius: 22,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('设备过滤', style: TextStyle(color: p.text, fontSize: 15, fontWeight: FontWeight.w300)),
                const SizedBox(height: 4),
                Text('开启后将按照设备条件过滤应用列表', style: TextStyle(color: p.subText, fontSize: 12)),
                const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    Expanded(child: Text('启用设备过滤', style: TextStyle(color: p.text, fontSize: 14))),
                    NeuSwitch(
                      value: _deviceFilter,
                      onChanged: (bool v) {
                        setState(() {
                          _deviceFilter = v;
                          _dirty = true;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text('过滤系统', style: TextStyle(color: p.subText, fontSize: 12.5)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _osOptions.map((Map<String, String> o) {
                    return NeuChip(
                      label: o['label']!,
                      selected: _filterOs == o['key'],
                      onTap: () {
                        setState(() {
                          _filterOs = o['key']!;
                          _dirty = true;
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          NeuButton(
            text: _dirty ? '保存修改' : '保存',
            icon: Icons.check,
            primary: true,
            width: double.infinity,
            loading: _saving,
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}
