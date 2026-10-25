import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/api_service.dart';
import '../services/storage.dart';
import '../theme/neu_theme.dart';
import '../widgets/common.dart';
import '../widgets/neu.dart';
import 'home_screen.dart' show AppRowCard;

class SearchScreen extends StatefulWidget {
  final String? initialQuery;
  const SearchScreen({super.key, this.initialQuery});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final ApiService _api = ApiService.instance;
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focus = FocusNode();

  int _tab = 0; // 0=应用 1=用户
  final List<AppItem> _apps = <AppItem>[];
  final List<UserItem> _users = <UserItem>[];
  bool _loading = false;
  bool _searched = false;
  String? _error;
  List<String> _history = <String>[];

  @override
  void initState() {
    super.initState();
    _history = Storage.instance.searchHistory;
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _controller.text = widget.initialQuery!;
      WidgetsBinding.instance.addPostFrameCallback((_) => _doSearch());
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _doSearch() async {
    final q = _controller.text.trim();
    if (q.isEmpty) return;
    _focus.unfocus();
    setState(() {
      _loading = true;
      _error = null;
      _searched = true;
    });
    try {
      if (_tab == 0) {
        final data = await _api.appList(page: 1, q: q);
        if (!mounted) return;
        setState(() {
          _apps
            ..clear()
            ..addAll(data.list);
          _loading = false;
        });
      } else {
        final users = await _api.searchUsers(q);
        if (!mounted) return;
        setState(() {
          _users
            ..clear()
            ..addAll(users);
          _loading = false;
        });
      }
      await Storage.instance.addSearchHistory(q);
      _history = Storage.instance.searchHistory;
      if (mounted) setState(() {});
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _removeHistory(String q) async {
    final list = Storage.instance.searchHistory..remove(q);
    await Storage.instance.clearSearchHistory();
    for (final item in list) {
      await Storage.instance.addSearchHistory(item);
    }
    setState(() => _history = Storage.instance.searchHistory);
  }

  @override
  Widget build(BuildContext context) {
    final p = NeuPalette.of(context);
    return Scaffold(
      appBar: NeuAppBar(
        title: '搜索',
        leading: NeuIconButton(icon: Icons.arrow_back, size: 40, onPressed: () => Navigator.pop(context)),
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: NeuTextField(
                      controller: _controller,
                      hint: _tab == 0 ? '搜索应用名称' : '搜索用户昵称',
                      prefixIcon: Icons.search,
                      autofocus: true,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => _doSearch(),
                      suffix: IconButton(
                        icon: Icon(Icons.send, color: p.accent, size: 20),
                        onPressed: _doSearch,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: NeuSegmented<int>(
                values: const <int>[0, 1],
                labels: const <String>['应用', '用户'],
                value: _tab,
                onChanged: (int v) {
                  setState(() {
                    _tab = v;
                    _searched = false;
                    _apps.clear();
                    _users.clear();
                    _error = null;
                  });
                  if (_controller.text.trim().isNotEmpty) _doSearch();
                },
              ),
            ),
            const SizedBox(height: 12),
            Expanded(child: _buildBody(p)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(NeuPalette p) {
    if (_loading) {
      return const LoadingView(message: '搜索中…');
    }
    if (_error != null) {
      return ErrorView(message: _error!, onRetry: _doSearch);
    }
    if (!_searched) {
      if (_history.isEmpty) {
        return const EmptyView(message: '输入关键词开始搜索', icon: Icons.search);
      }
      return ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: <Widget>[
          SectionHeader(
            title: '搜索历史',
            actionText: '清空',
            onAction: () async {
              await Storage.instance.clearSearchHistory();
              setState(() => _history = <String>[]);
            },
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _history.map((String q) {
              return NeuChip(
                label: q,
                onTap: () {
                  _controller.text = q;
                  _doSearch();
                },
              );
            }).toList(),
          ),
        ],
      );
    }
    if (_tab == 0) {
      if (_apps.isEmpty) {
        return const EmptyView(message: '没有找到相关应用', icon: Icons.search_off);
      }
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        itemCount: _apps.length,
        itemBuilder: (BuildContext context, int i) {
          final item = _apps[i];
          return AppRowCard(
            item: item,
            onTap: () => Navigator.pushNamed(context, '/app_detail', arguments: <String, dynamic>{'appId': item.id}),
          );
        },
      );
    }
    if (_users.isEmpty) {
      return const EmptyView(message: '没有找到相关用户', icon: Icons.person_search);
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      itemCount: _users.length,
      itemBuilder: (BuildContext context, int i) {
        final u = _users[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: NeuBox(
            radius: 18,
            padding: const EdgeInsets.all(12),
            onTap: () => Navigator.pushNamed(context, '/profile', arguments: <String, dynamic>{'userId': u.userId}),
            child: Row(
              children: <Widget>[
                AvatarFrame(avatar: u.avatar, frame: u.frame, frameW: u.frameW, frameX: u.frameX, frameY: u.frameY, size: 46),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Flexible(
                            child: Text(
                              u.nickname,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: p.text, fontSize: 14.5, fontWeight: FontWeight.w300),
                            ),
                          ),
                          if (u.isVerified) ...<Widget>[
                            const SizedBox(width: 4),
                            Icon(Icons.verified, size: 14, color: p.accent),
                          ],
                        ],
                      ),
                      if (u.bio.isNotEmpty) ...<Widget>[
                        const SizedBox(height: 3),
                        Text(
                          u.bio,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: p.subText, fontSize: 12),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: p.subText),
              ],
            ),
          ),
        );
      },
    );
  }
}
