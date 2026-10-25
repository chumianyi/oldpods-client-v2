import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/api_service.dart';
import '../state/app_state.dart';
import '../theme/neu_theme.dart';
import '../widgets/common.dart';
import '../widgets/neu.dart';

class SubmissionsScreen extends StatefulWidget {
  const SubmissionsScreen({super.key});

  @override
  State<SubmissionsScreen> createState() => _SubmissionsScreenState();
}

class _SubmissionsScreenState extends State<SubmissionsScreen> {
  final ApiService _api = ApiService.instance;
  final ScrollController _scrollController = ScrollController();

  final List<SubmissionItem> _items = <SubmissionItem>[];
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
      final data = await _api.mySubmissions();
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
      final data = await _api.mySubmissions(page: _page + 1);
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
        title: '我的投稿',
        leading: NeuIconButton(icon: Icons.arrow_back, size: 40, onPressed: () => Navigator.pop(context)),
      ),
      body: !AppState.instance.loggedIn
          ? const EmptyView(message: '登录后查看我的投稿', icon: Icons.lock_outline)
          : RefreshIndicator(
              color: p.accent,
              backgroundColor: p.surface,
              onRefresh: _load,
              child: _loading && _items.isEmpty
                  ? ListView(children: const <Widget>[SizedBox(height: 240, child: LoadingView())])
                  : (_error != null && _items.isEmpty
                      ? ListView(children: <Widget>[SizedBox(height: 300, child: ErrorView(message: _error!, onRetry: _load))])
                      : (_items.isEmpty
                          ? ListView(children: const <Widget>[SizedBox(height: 300, child: EmptyView(message: '暂无投稿记录', icon: Icons.upload_file))])
                          : ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
                              itemCount: _items.length + 1,
                              itemBuilder: (BuildContext context, int i) {
                                if (i >= _items.length) {
                                  return LoadMoreFooter(loading: _loadingMore, hasMore: _page < _pages);
                                }
                                final item = _items[i];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: NeuBox(
                                    radius: 18,
                                    padding: const EdgeInsets.all(12),
                                    onTap: () => Navigator.pushNamed(context, '/app_detail', arguments: <String, dynamic>{'appId': item.id}),
                                    child: Row(
                                      children: <Widget>[
                                        NetworkImageBox(url: item.iconUrl, width: 48, height: 48, radius: 14, fallbackIcon: Icons.android),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: <Widget>[
                                              Text(
                                                item.title,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(color: p.text, fontSize: 14, fontWeight: FontWeight.w300),
                                              ),
                                              const SizedBox(height: 5),
                                              Wrap(
                                                spacing: 6,
                                                runSpacing: 4,
                                                children: <Widget>[
                                                  if (item.system.isNotEmpty) MetaTag(text: item.system),
                                                  if (item.size.isNotEmpty) MetaTag(text: item.size),
                                                  if (item.arch.isNotEmpty) MetaTag(text: item.arch),
                                                  if (item.statusLabel.isNotEmpty) MetaTag(text: item.statusLabel, color: p.accent),
                                                  if (item.downloads > 0) MetaTag(text: '${item.downloads} 下载'),
                                                ],
                                              ),
                                            ],
                                          ),
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
