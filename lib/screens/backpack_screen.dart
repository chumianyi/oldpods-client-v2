import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/api_client.dart';
import '../services/api_service.dart';
import '../state/app_state.dart';
import '../theme/neu_theme.dart';
import '../widgets/common.dart';
import '../widgets/neu.dart';

class BackpackScreen extends StatefulWidget {
  const BackpackScreen({super.key});

  @override
  State<BackpackScreen> createState() => _BackpackScreenState();
}

class _BackpackScreenState extends State<BackpackScreen> {
  final ApiService _api = ApiService.instance;

  List<BackpackItem> _items = <BackpackItem>[];
  bool _loading = true;
  String? _error;
  bool _using = false;

  @override
  void initState() {
    super.initState();
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
      final items = await _api.backpack();
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

  Future<void> _use(BackpackItem item) async {
    final go = await confirmDialog(context, title: '使用物品', content: '确定使用「${item.name}」？');
    if (!go) return;
    setState(() => _using = true);
    try {
      await _api.useBackpackItem(item.id > 0 ? item.id : null);
      showToast(context, '使用成功');
    } on ApiException catch (e) {
      showToast(context, e.message);
    } finally {
      if (mounted) setState(() => _using = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = NeuPalette.of(context);
    return Scaffold(
      appBar: NeuAppBar(
        title: '我的背包',
        leading: NeuIconButton(icon: Icons.arrow_back, size: 40, onPressed: () => Navigator.pop(context)),
      ),
      body: !AppState.instance.loggedIn
          ? const EmptyView(message: '登录后查看背包', icon: Icons.lock_outline)
          : RefreshIndicator(
              color: p.accent,
              backgroundColor: p.surface,
              onRefresh: _load,
              child: _loading && _items.isEmpty
                  ? ListView(children: const <Widget>[SizedBox(height: 240, child: LoadingView())])
                  : (_error != null && _items.isEmpty
                      ? ListView(children: <Widget>[SizedBox(height: 300, child: ErrorView(message: _error!, onRetry: _load))])
                      : (_items.isEmpty
                          ? ListView(children: const <Widget>[SizedBox(height: 300, child: EmptyView(message: '背包空空如也', icon: Icons.backpack_outlined))])
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                              itemCount: _items.length,
                              itemBuilder: (BuildContext context, int i) {
                                final item = _items[i];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: NeuBox(
                                    radius: 18,
                                    padding: const EdgeInsets.all(12),
                                    child: Row(
                                      children: <Widget>[
                                        NetworkImageBox(
                                          url: item.icon.isEmpty ? null : item.icon,
                                          width: 52,
                                          height: 52,
                                          radius: 14,
                                          fallbackIcon: Icons.card_giftcard,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: <Widget>[
                                              Text(item.name, style: TextStyle(color: p.text, fontSize: 14.5, fontWeight: FontWeight.w300)),
                                              const SizedBox(height: 3),
                                              Text(
                                                item.count > 1 ? '数量：${item.count}' : (item.type.isNotEmpty ? item.type : '道具'),
                                                style: TextStyle(color: p.subText, fontSize: 12),
                                              ),
                                            ],
                                          ),
                                        ),
                                        NeuButton(
                                          text: '使用',
                                          compact: true,
                                          loading: _using,
                                          onPressed: () => _use(item),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ))),
            ),
    );
  }
}
