import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/api_client.dart';
import '../services/api_service.dart';
import '../state/app_state.dart';
import '../theme/neu_theme.dart';
import '../widgets/common.dart';
import '../widgets/neu.dart';

class FramesScreen extends StatefulWidget {
  const FramesScreen({super.key});

  @override
  State<FramesScreen> createState() => _FramesScreenState();
}

class _FramesScreenState extends State<FramesScreen> {
  final ApiService _api = ApiService.instance;

  List<FrameItem> _items = <FrameItem>[];
  bool _loading = true;
  String? _error;
  bool _using = false;
  String _currentFrame = '';

  @override
  void initState() {
    super.initState();
    _currentFrame = AppState.instance.userInfo?.frame ?? '';
    _load();
  }

  Future<void> _load() async {
    if (!AppState.instance.loggedIn) {
      setState(() => _loading = false);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await _api.frames();
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _use(FrameItem item) async {
    setState(() => _using = true);
    try {
      final value = item.id > 0 ? '${item.id}' : item.image;
      await _api.useFrame(value);
      await AppState.instance.refreshUser();
      if (!mounted) return;
      setState(() => _currentFrame = item.image);
      showToast(context, '已更换头像框');
    } on ApiException catch (e) {
      if (mounted) showToast(context, e.message);
    } finally {
      if (mounted) setState(() => _using = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = NeuPalette.of(context);
    return Scaffold(
      appBar: NeuAppBar(
        title: '头像框',
        leading: NeuIconButton(icon: Icons.arrow_back, size: 40, onPressed: () => Navigator.pop(context)),
      ),
      body: !AppState.instance.loggedIn
          ? const EmptyView(message: '登录后查看头像框', icon: Icons.lock_outline)
          : RefreshIndicator(
              color: p.accent,
              backgroundColor: p.surface,
              onRefresh: _load,
              child: _loading && _items.isEmpty
                  ? ListView(children: const <Widget>[SizedBox(height: 240, child: LoadingView())])
                  : (_error != null && _items.isEmpty
                      ? ListView(children: <Widget>[SizedBox(height: 300, child: ErrorView(message: _error!, onRetry: _load))])
                      : GridView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 0.85,
                          ),
                          itemCount: _items.length,
                          itemBuilder: (BuildContext context, int i) {
                            final item = _items[i];
                            final using = _currentFrame.isNotEmpty && _currentFrame == item.image;
                            return NeuBox(
                              radius: 20,
                              padding: const EdgeInsets.all(12),
                              border: using ? Border.all(color: p.accent, width: 2) : null,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  AvatarFrame(
                                    avatar: AppState.instance.avatar,
                                    frame: item.image,
                                    frameW: item.frameW,
                                    frameX: item.frameX,
                                    frameY: item.frameY,
                                    size: 64,
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    item.name.isEmpty ? '头像框' : item.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(color: p.text, fontSize: 13, fontWeight: FontWeight.w300),
                                  ),
                                  const SizedBox(height: 8),
                                  NeuButton(
                                    text: using ? '使用中' : '使用',
                                    compact: true,
                                    primary: using,
                                    loading: _using,
                                    onPressed: using ? null : () => _use(item),
                                  ),
                                ],
                              ),
                            );
                          },
                        )),
            ),
    );
  }
}
