import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/api_client.dart';
import '../services/api_service.dart';
import '../state/app_state.dart';
import '../theme/neu_theme.dart';
import '../widgets/common.dart';
import '../widgets/neu.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final ApiService _api = ApiService.instance;

  ConversationList? _conversations;
  SystemMessageList? _systemMessages;
  bool _loading = true;
  bool _loadingSystem = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
    AppState.instance.addListener(_onAppState);
  }

  @override
  void dispose() {
    AppState.instance.removeListener(_onAppState);
    super.dispose();
  }

  void _onAppState() {
    if (mounted) setState(() {});
  }

  Future<void> _load() async {
    if (!AppState.instance.loggedIn) {
      setState(() {
        _loading = false;
        _loadingSystem = false;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final convs = await _api.conversations();
      if (!mounted) return;
      setState(() {
        _conversations = convs;
        _loading = false;
      });
      AppState.instance.refreshUnread();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
    _loadSystem();
  }

  Future<void> _loadSystem() async {
    if (!AppState.instance.loggedIn) return;
    setState(() => _loadingSystem = true);
    try {
      final list = await _api.systemMessages();
      if (!mounted) return;
      setState(() {
        _systemMessages = list;
        _loadingSystem = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingSystem = false);
    }
  }

  Future<void> _openConversation(Conversation c) async {
    await Navigator.pushNamed(context, '/message_detail', arguments: <String, dynamic>{
      'convId': c.convId,
      'peerId': c.peerId,
      'nickname': c.nickname,
    });
    _load();
  }

  Future<void> _convAction(Conversation c) async {
    final p = NeuPalette.of(context);
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext ctx) {
        return Container(
          decoration: BoxDecoration(color: p.surface, borderRadius: BorderRadius.circular(22)),
          padding: const EdgeInsets.all(20),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(c.nickname, style: TextStyle(color: p.text, fontSize: 16, fontWeight: FontWeight.w300)),
                const SizedBox(height: 14),
                _SheetAction(
                  icon: Icons.block,
                  text: '屏蔽该用户',
                  color: p.warning,
                  onTap: () => Navigator.pop(ctx, 'block'),
                ),
                _SheetAction(
                  icon: Icons.delete_outline,
                  text: '删除会话',
                  color: p.danger,
                  onTap: () => Navigator.pop(ctx, 'delete'),
                ),
                _SheetAction(
                  icon: Icons.close,
                  text: '取消',
                  color: p.subText,
                  onTap: () => Navigator.pop(ctx),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (action == 'block') {
      try {
        await _api.blockUser(c.peerId);
        showToast(context, '已屏蔽');
      } on ApiException catch (e) {
        showToast(context, e.message);
      }
    } else if (action == 'delete') {
      final go = await confirmDialog(context, title: '删除会话', content: '删除后聊天记录将不可恢复', danger: true);
      if (!go) return;
      try {
        await _api.deleteConversation(c.convId);
        showToast(context, '已删除');
        _load();
      } on ApiException catch (e) {
        showToast(context, e.message);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = NeuPalette.of(context);
    return Scaffold(
      appBar: NeuAppBar(
        title: '消息',
        actions: <Widget>[
          NeuIconButton(
            icon: Icons.notifications_none,
            size: 40,
            tooltip: '系统消息',
            onPressed: () => Navigator.pushNamed(context, '/system_messages').then((_) => _loadSystem()),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: !AppState.instance.loggedIn
          ? EmptyView(
              message: '登录后可查看私信与系统消息',
              icon: Icons.lock_outline,
            )
          : RefreshIndicator(
              color: p.accent,
              backgroundColor: p.surface,
              onRefresh: _load,
              child: _loading && _conversations == null
                  ? ListView(children: const <Widget>[SizedBox(height: 240, child: LoadingView())])
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                      children: <Widget>[
                        if (_error != null && _conversations == null)
                          SizedBox(height: 200, child: ErrorView(message: _error!, onRetry: _load)),
                        _buildSystemPreview(p),
                        const SizedBox(height: 16),
                        SectionHeader(title: '私信'),
                        if ((_conversations?.list ?? <Conversation>[]).isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 30),
                            child: EmptyView(message: '暂无私信', icon: Icons.chat_bubble_outline),
                          )
                        else
                          ...(_conversations!.list).map((Conversation c) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: NeuBox(
                                radius: 18,
                                padding: const EdgeInsets.all(12),
                                onTap: () => _openConversation(c),
                                onLongPress: () => _convAction(c),
                                child: Row(
                                  children: <Widget>[
                                    AvatarFrame(avatar: c.avatar, size: 44),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: <Widget>[
                                          Row(
                                            children: <Widget>[
                                              Expanded(
                                                child: Text(
                                                  c.nickname,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: TextStyle(color: p.text, fontSize: 14.5, fontWeight: FontWeight.w300),
                                                ),
                                              ),
                                              if (c.unread > 0) NeuBadge(count: c.unread, size: 18),
                                            ],
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            c.lastMessage.isEmpty ? '暂无消息' : c.lastMessage,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(color: p.subText, fontSize: 12.5),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (c.updatedAt.isNotEmpty)
                                      Text(
                                        _shortTime(c.updatedAt),
                                        style: TextStyle(color: p.subText, fontSize: 10.5),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          }),
                      ],
                    ),
            ),
    );
  }

  Widget _buildSystemPreview(NeuPalette p) {
    final list = _systemMessages?.list ?? <SystemMessage>[];
    final unreadSystem = list.where((SystemMessage m) => !m.isRead).length;
    return NeuBox(
      radius: 18,
      padding: const EdgeInsets.all(14),
      onTap: () => Navigator.pushNamed(context, '/system_messages').then((_) => _loadSystem()),
      child: Row(
        children: <Widget>[
          NeuBox(inset: true, radius: 12, width: 40, height: 40, padding: EdgeInsets.zero, child: Icon(Icons.campaign, size: 20, color: p.accent)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('系统消息', style: TextStyle(color: p.text, fontSize: 14.5, fontWeight: FontWeight.w300)),
                const SizedBox(height: 2),
                Text(
                  _loadingSystem ? '加载中…' : (list.isEmpty ? '暂无系统消息' : '${list.length} 条消息'),
                  style: TextStyle(color: p.subText, fontSize: 12),
                ),
              ],
            ),
          ),
          if (unreadSystem > 0) NeuBadge(count: unreadSystem, size: 18),
          Icon(Icons.chevron_right, color: p.subText),
        ],
      ),
    );
  }

  String _shortTime(String time) {
    if (time.length >= 16) return time.substring(5, 16);
    return time;
  }
}

class _SheetAction extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  final VoidCallback onTap;
  const _SheetAction({required this.icon, required this.text, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = NeuPalette.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 8),
        child: Row(
          children: <Widget>[
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Text(text, style: TextStyle(color: color, fontSize: 14.5, fontWeight: FontWeight.w300)),
            const Spacer(),
            Icon(Icons.chevron_right, color: p.subText, size: 18),
          ],
        ),
      ),
    );
  }
}
