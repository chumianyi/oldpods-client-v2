import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/neu_theme.dart';
import '../widgets/common.dart';
import '../widgets/neu.dart';
import 'home_screen.dart' show AppRowCard;

class AppListScreen extends StatefulWidget {
  final String title;
  final String? catIds;
  final String? catGroups;
  final String? q;

  const AppListScreen({super.key, required this.title, this.catIds, this.catGroups, this.q});

  @override
  State<AppListScreen> createState() => _AppListScreenState();
}

class _AppListScreenState extends State<AppListScreen> {
  final ApiService _api = ApiService.instance;
  final ScrollController _scrollController = ScrollController();

  final List<AppItem> _items = <AppItem>[];
  int _page = 1;
  int _pages = 1;
  String _sort = 'new';
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;

  static const List<Map<String, String>> _sorts = <Map<String, String>>[
    <String, String>{'key': 'new', 'label': '最新'},
    <String, String>{'key': 'hot', 'label': '最热'},
    <String, String>{'key': 'rating', 'label': '评分'},
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _load(refresh: true);
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

  Future<void> _load({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final data = await _api.appList(page: 1, sort: _sort, catIds: widget.catIds, catGroups: widget.catGroups, q: widget.q);
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
      final data = await _api.appList(page: _page + 1, sort: _sort, catIds: widget.catIds, catGroups: widget.catGroups, q: widget.q);
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

  @override
  Widget build(BuildContext context) {
    final p = NeuPalette.of(context);
    return Scaffold(
      appBar: NeuAppBar(
        title: widget.title,
        leading: NeuIconButton(icon: Icons.arrow_back, size: 40, onPressed: () => Navigator.pop(context)),
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: _sorts.map((Map<String, String> s) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: NeuChip(
                      label: s['label']!,
                      selected: _sort == s['key'],
                      onTap: () {
                        setState(() => _sort = s['key']!);
                        _load(refresh: true);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                color: p.accent,
                backgroundColor: p.surface,
                onRefresh: () => _load(refresh: true),
                child: _loading && _items.isEmpty
                    ? ListView(children: const <Widget>[SizedBox(height: 200, child: LoadingView())])
                    : (_error != null && _items.isEmpty
                        ? ListView(children: <Widget>[SizedBox(height: 300, child: ErrorView(message: _error!, onRetry: _load))])
                        : (_items.isEmpty
                            ? ListView(children: const <Widget>[SizedBox(height: 300, child: EmptyView(message: '暂无相关应用'))])
                            : ListView.builder(
                                controller: _scrollController,
                                padding: const EdgeInsets.fromLTRB(16, 6, 16, 20),
                                itemCount: _items.length + 1,
                                itemBuilder: (BuildContext context, int i) {
                                  if (i >= _items.length) {
                                    return LoadMoreFooter(loading: _loadingMore, hasMore: _page < _pages);
                                  }
                                  final item = _items[i];
                                  return AppRowCard(
                                    item: item,
                                    onTap: () => Navigator.pushNamed(context, '/app_detail', arguments: <String, dynamic>{'appId': item.id}),
                                  );
                                },
                              ))),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
