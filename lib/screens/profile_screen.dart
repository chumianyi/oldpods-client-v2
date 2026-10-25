import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/api_client.dart';
import '../services/api_service.dart';
import '../state/app_state.dart';
import '../theme/neu_theme.dart';
import '../widgets/common.dart';
import '../widgets/neu.dart';

class ProfileScreen extends StatefulWidget {
  final int userId;
  const ProfileScreen({super.key, required this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _api = ApiService.instance;
  final ScrollController _scrollController = ScrollController();

  UserProfile? _profile;
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
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final profile = await _api.userProfile(widget.userId);
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _items
          ..clear()
          ..addAll(profile.submissions.list);
        _page = profile.submissions.meta.page;
        _pages = profile.submissions.meta.pages;
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
      final profile = await _api.userProfile(widget.userId, page: _page + 1);
      if (!mounted) return;
      setState(() {
        _items.addAll(profile.submissions.list);
        _page = profile.submissions.meta.page;
        _pages = profile.submissions.meta.pages;
        _loadingMore = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  Future<void> _sendMessage() async {
    if (!AppState.instance.loggedIn) {
      showToast(context, '请先登录');
      Navigator.pushNamed(context, '/login');
      return;
    }
    final p = NeuPalette.of(context);
    final controller = TextEditingController();
    final content = await showDialog<String>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: Text('发私信给 ${_profile?.user.nickname ?? ''}', style: TextStyle(color: p.text, fontSize: 16, fontWeight: FontWeight.w300)),
        content: NeuTextField(
          controller: controller,
          hint: '输入消息内容',
          maxLines: 4,
          autofocus: true,
        ),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('取消', style: TextStyle(color: p.subText))),
          TextButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: Text('发送', style: TextStyle(color: p.accent, fontWeight: FontWeight.w300))),
        ],
      ),
    );
    if (content == null || content.isEmpty) return;
    try {
      await _api.sendMessage(peerId: widget.userId, content: content);
      showToast(context, '已发送');
      Navigator.pushNamed(context, '/messages');
    } on ApiException catch (e) {
      showToast(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = NeuPalette.of(context);
    final user = _profile?.user;
    return Scaffold(
      appBar: NeuAppBar(
        title: user?.nickname ?? '用户主页',
        leading: NeuIconButton(icon: Icons.arrow_back, size: 40, onPressed: () => Navigator.pop(context)),
        actions: <Widget>[
          if (widget.userId != AppState.instance.userId && AppState.instance.loggedIn)
            NeuIconButton(icon: Icons.chat_bubble_outline, size: 40, tooltip: '发私信', onPressed: _sendMessage),
          const SizedBox(width: 8),
        ],
      ),
      body: _loading && _profile == null
          ? const LoadingView(message: '正在加载主页…')
          : (_error != null
              ? ErrorView(message: _error!, onRetry: _load)
              : RefreshIndicator(
                  color: p.accent,
                  backgroundColor: p.surface,
                  onRefresh: _load,
                  child: ListView(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    children: <Widget>[
                      _buildHeader(p, user!),
                      const SizedBox(height: 18),
                      SectionHeader(title: '投稿（${_profile?.submissions.meta.total ?? 0}）'),
                      if (_items.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 30),
                          child: EmptyView(message: '该用户暂无投稿', icon: Icons.upload_file),
                        )
                      else
                        ..._items.map((SubmissionItem item) {
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
                                            if (item.downloads > 0) MetaTag(text: '${item.downloads} 下载'),
                                            if (item.statusLabel.isNotEmpty) MetaTag(text: item.statusLabel, color: p.accent),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      if (_items.isNotEmpty) LoadMoreFooter(loading: _loadingMore, hasMore: _page < _pages),
                    ],
                  ),
                )),
    );
  }

  Widget _buildHeader(NeuPalette p, UserItem user) {
    return NeuBox(
      radius: 24,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: <Widget>[
          AvatarFrame(
            avatar: user.avatar,
            frame: user.frame,
            frameW: user.frameW,
            frameX: user.frameX,
            frameY: user.frameY,
            size: 84,
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Flexible(
                child: Text(
                  user.nickname,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: p.text, fontSize: 19, fontWeight: FontWeight.w300),
                ),
              ),
              if (user.isVerified) ...<Widget>[
                const SizedBox(width: 6),
                Icon(Icons.verified, size: 18, color: p.accent),
              ],
            ],
          ),
          if (user.verifyBadge.isNotEmpty) ...<Widget>[
            const SizedBox(height: 4),
            Text(user.verifyBadge, style: TextStyle(color: p.accent, fontSize: 12)),
          ],
          if (user.memberLabel.isNotEmpty) ...<Widget>[
            const SizedBox(height: 8),
            MetaTag(text: user.memberLabel, color: p.warning, icon: Icons.workspace_premium),
          ],
          if (user.bio.isNotEmpty) ...<Widget>[
            const SizedBox(height: 12),
            Text(
              user.bio,
              textAlign: TextAlign.center,
              style: TextStyle(color: p.subText, fontSize: 13.5, height: 1.5),
            ),
          ],
        ],
      ),
    );
  }
}
