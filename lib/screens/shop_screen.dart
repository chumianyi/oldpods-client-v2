import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/api_client.dart';
import '../services/api_service.dart';
import '../state/app_state.dart';
import '../theme/neu_theme.dart';
import '../widgets/common.dart';
import '../widgets/neu.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  final ApiService _api = ApiService.instance;

  List<ShopItem> _items = <ShopItem>[];
  bool _loading = true;
  String? _error;
  bool _buying = false;

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
      final items = await _api.shopItems();
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

  Future<void> _buy(ShopItem item) async {
    final p = NeuPalette.of(context);
    final go = await confirmDialog(
      context,
      title: '购买商品',
      content: '确定花费 ${item.price} 硬币购买「${item.name}」？',
    );
    if (!go) return;
    setState(() => _buying = true);
    try {
      final result = await _api.buyItem(item.id);
      await AppState.instance.refreshUser();
      if (!mounted) return;
      final coins = result['coins'] ?? result['balance'] ?? '';
      showDialog<void>(
        context: context,
        builder: (BuildContext ctx) => AlertDialog(
          title: Row(
            children: <Widget>[
              Icon(Icons.check_circle, color: p.success),
              const SizedBox(width: 8),
              Text('购买成功', style: TextStyle(color: p.text, fontWeight: FontWeight.w300)),
            ],
          ),
          content: Text(
            coins.toString().isNotEmpty ? '剩余硬币：$coins' : '「${item.name}」已放入背包',
            style: TextStyle(color: p.subText),
          ),
          actions: <Widget>[
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text('好的', style: TextStyle(color: p.accent))),
          ],
        ),
      );
    } on ApiException catch (e) {
      if (mounted) showToast(context, e.message);
    } finally {
      if (mounted) setState(() => _buying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = NeuPalette.of(context);
    return Scaffold(
      appBar: NeuAppBar(
        title: '商店',
        leading: NeuIconButton(icon: Icons.arrow_back, size: 40, onPressed: () => Navigator.pop(context)),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Row(
              children: <Widget>[
                Icon(Icons.savings_outlined, size: 17, color: p.warning),
                const SizedBox(width: 4),
                Text('${AppState.instance.userInfo?.coins ?? 0}', style: TextStyle(color: p.text, fontSize: 14, fontWeight: FontWeight.w300)),
              ],
            ),
          ),
        ],
      ),
      body: !AppState.instance.loggedIn
          ? const EmptyView(message: '登录后进入商店', icon: Icons.lock_outline)
          : RefreshIndicator(
              color: p.accent,
              backgroundColor: p.surface,
              onRefresh: _load,
              child: _loading && _items.isEmpty
                  ? ListView(children: const <Widget>[SizedBox(height: 240, child: LoadingView())])
                  : (_error != null && _items.isEmpty
                      ? ListView(children: <Widget>[SizedBox(height: 300, child: ErrorView(message: _error!, onRetry: _load))])
                      : (_items.isEmpty
                          ? ListView(children: const <Widget>[SizedBox(height: 300, child: EmptyView(message: '商店暂无商品', icon: Icons.storefront))])
                          : GridView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                childAspectRatio: 0.82,
                              ),
                              itemCount: _items.length,
                              itemBuilder: (BuildContext context, int i) {
                                final item = _items[i];
                                return NeuBox(
                                  radius: 20,
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Center(
                                        child: NetworkImageBox(
                                          url: item.icon.isEmpty ? null : item.icon,
                                          width: 64,
                                          height: 64,
                                          radius: 16,
                                          fallbackIcon: Icons.card_giftcard,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        item.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(color: p.text, fontSize: 14, fontWeight: FontWeight.w300),
                                      ),
                                      const SizedBox(height: 4),
                                      Expanded(
                                        child: Text(
                                          item.description,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(color: p.subText, fontSize: 11.5, height: 1.4),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: <Widget>[
                                          Icon(Icons.savings_outlined, size: 15, color: p.warning),
                                          const SizedBox(width: 4),
                                          Text('${item.price}', style: TextStyle(color: p.warning, fontSize: 14, fontWeight: FontWeight.w300)),
                                          const Spacer(),
                                          NeuButton(
                                            text: '购买',
                                            compact: true,
                                            primary: true,
                                            loading: _buying,
                                            onPressed: () => _buy(item),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ))),
            ),
    );
  }
}
