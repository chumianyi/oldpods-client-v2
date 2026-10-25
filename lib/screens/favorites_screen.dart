import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/api_client.dart';
import '../services/api_service.dart';
import '../state/app_state.dart';
import '../theme/neu_theme.dart';
import '../widgets/common.dart';
import '../widgets/neu.dart';
import 'home_screen.dart' show AppRowCard;

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final ApiService _api = ApiService.instance;
  final ScrollController _scrollController = ScrollController();

  final List<AppItem> _items = <AppItem>[];
  int _page = 1;
  int _pages = 1;
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _load();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 300) {
      _loadMore();
    }
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
      final data = await _api.favoriteList();
      if (!mounted) return;
      setState(() {
        _items
          ..clear()
          ..addAll(data.list);
        _page = data.meta.page;
        _pages = data.meta.pages;
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

  Future<void> _loadMore() async {
    if (_loadingMore || _loading || _page >= _pages) return;
    setState(() => _loadingMore = true);
    try {
      final data = await _api.favoriteList(page: _page + 1);
      if (!mounted) return;
      setState(() {
        _items.addAll(data.list);
        _page = data.meta.page;
        _pages = data.meta.pages;
        _loadingMore = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  Future<void> _remove(AppItem item) async {
    final go = await confirmDialog(context, title: '取消收藏', content: '确定取消收藏「${item.title}」？', danger: true);
    if (!go) return;
    try {
      await _api.removeFavorite(item.id);
      showToast(context, '已取消收藏');
      setState(() => _items.remove(item));
    } on ApiException catch (e) {
      showToast(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = NeuPalette.of(context);
    return Scaffold(
      appBar: NeuAppBar(
        title: '我的收藏',
        leading: NeuIconButton(icon: Icons.arrow_back, size: 40, onPressed: () => Navigator.pop(context)),
      ),
      body: !AppState.instance.loggedIn
          ? const EmptyView(message: '登录后查看收藏', icon: Icons.lock_outline)
          : RefreshIndicator(
              color: p.accent,
              backgroundColor: p.surface,
              onRefresh: _load,
              child: _loading && _items.isEmpty
                  ? ListView(children: const <Widget>[SizedBox(height: 240, child: LoadingView())])
                  : (_error != null && _items.isEmpty
                      ? ListView(children: <Widget>[SizedBox(height: 300, child: ErrorView(message: _error!, onRetry: _load))])
                      : (_items.isEmpty
                          ? ListView(children: const <Widget>[SizedBox(height: 300, child: EmptyView(message: '还没有收藏任何应用', icon: Icons.star_border))])
                          : ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
                              itemCount: _items.length + 1,
                              itemBuilder: (BuildContext context, int i) {
                                if (i >= _items.length) {
                                  return LoadMoreFooter(loading: _loadingMore, hasMore: _page < _pages);
                                }
                                final item = _items[i];
                                return Row(
                                  children: <Widget>[
                                    Expanded(
                                      child: AppRowCard(
                                        item: item,
                                        onTap: () => Navigator.pushNamed(context, '/app_detail', arguments: <String, dynamic>{'appId': item.id}),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () => _remove(item),
                                      child: Padding(
                                        padding: const EdgeInsets.only(left: 4, bottom: 12),
                                        child: Icon(Icons.delete_outline, size: 18, color: p.subText),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ))),
            ),
    );
  }
}
