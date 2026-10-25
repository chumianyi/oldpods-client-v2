import 'dart:async';

import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/api_client.dart';
import '../services/api_service.dart';
import '../state/app_state.dart';
import '../theme/neu_theme.dart';
import '../widgets/common.dart';
import '../widgets/neu.dart';

class MessageDetailScreen extends StatefulWidget {
  final int convId;
  final int peerId;
  final String nickname;

  const MessageDetailScreen({super.key, required this.convId, required this.peerId, required this.nickname});

  @override
  State<MessageDetailScreen> createState() => _MessageDetailScreenState();
}

class _MessageDetailScreenState extends State<MessageDetailScreen> with WidgetsBindingObserver {
  final ApiService _api = ApiService.instance;
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<MessageItem> _messages = <MessageItem>[];
  bool _loading = true;
  bool _sending = false;
  String? _error;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
    _pollTimer = Timer.periodic(const Duration(seconds: 8), (_) => _load(quiet: true));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollTimer?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _load(quiet: true);
  }

  Future<void> _load({bool quiet = false}) async {
    if (!quiet) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final thread = await _api.messageDetail(convId: widget.convId);
      if (!mounted) return;
      setState(() {
        _messages = thread.list;
        _loading = false;
      });
      _scrollToBottom();
      AppState.instance.refreshUnread();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final content = _controller.text.trim();
    if (content.isEmpty) return;
    setState(() => _sending = true);
    try {
      await _api.sendMessage(peerId: widget.peerId, content: content);
      _controller.clear();
      await _load();
    } on ApiException catch (e) {
      showToast(context, e.message);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _blockOrUnblock(bool block) async {
    final go = await confirmDialog(
      context,
      title: block ? '屏蔽用户' : '取消屏蔽',
      content: block ? '屏蔽后将不再收到该用户的消息' : '确定取消屏蔽该用户？',
      danger: block,
    );
    if (!go) return;
    try {
      if (block) {
        await _api.blockUser(widget.peerId);
      } else {
        await _api.unblockUser(widget.peerId);
      }
      showToast(context, block ? '已屏蔽' : '已取消屏蔽');
    } on ApiException catch (e) {
      showToast(context, e.message);
    }
  }

  Future<void> _deleteConversation() async {
    final go = await confirmDialog(context, title: '删除会话', content: '删除后聊天记录将不可恢复', danger: true);
    if (!go) return;
    try {
      await _api.deleteConversation(widget.convId);
      showToast(context, '已删除');
      Navigator.pop(context);
    } on ApiException catch (e) {
      showToast(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = NeuPalette.of(context);
    return Scaffold(
      appBar: NeuAppBar(
        title: widget.nickname,
        leading: NeuIconButton(icon: Icons.arrow_back, size: 40, onPressed: () => Navigator.pop(context)),
        actions: <Widget>[
          NeuIconButton(
            icon: Icons.block,
            size: 40,
            tooltip: '屏蔽/取消屏蔽',
            onPressed: () => _blockOrUnblock(true),
          ),
          const SizedBox(width: 4),
          NeuIconButton(
            icon: Icons.delete_outline,
            size: 40,
            tooltip: '删除会话',
            onPressed: _deleteConversation,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: _loading && _messages.isEmpty
                  ? const LoadingView(message: '正在加载消息…')
                  : (_error != null && _messages.isEmpty
                      ? ErrorView(message: _error!, onRetry: _load)
                      : _messages.isEmpty
                          ? const EmptyView(message: '开始你们的第一条消息吧', icon: Icons.chat_bubble_outline)
                          : ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                              itemCount: _messages.length,
                              itemBuilder: (BuildContext context, int i) {
                                final m = _messages[i];
                                final mine = m.isMine;
                                return Align(
                                  alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    constraints: BoxConstraints(
                                      maxWidth: MediaQuery.of(context).size.width * 0.72,
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: mine ? p.accent : p.surface,
                                      borderRadius: BorderRadius.only(
                                        topLeft: const Radius.circular(18),
                                        topRight: const Radius.circular(18),
                                        bottomLeft: Radius.circular(mine ? 18 : 4),
                                        bottomRight: Radius.circular(mine ? 4 : 18),
                                      ),
                                      boxShadow: mine
                                          ? <BoxShadow>[]
                                          : <BoxShadow>[
                                              BoxShadow(color: p.shadowDark.withOpacity(0.35), offset: const Offset(2, 3), blurRadius: 6),
                                            ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Text(
                                          m.content,
                                          style: TextStyle(
                                            color: mine ? Colors.white : p.text,
                                            fontSize: 14,
                                            height: 1.4,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _shortTime(m.createdAt),
                                          style: TextStyle(
                                            color: mine ? Colors.white70 : p.subText,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            )),
            ),
            _buildInputBar(p),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar(NeuPalette p) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          Expanded(
            child: NeuTextField(
              controller: _controller,
              hint: '输入消息…',
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
            ),
          ),
          const SizedBox(width: 10),
          NeuBox(
            radius: 24,
            width: 48,
            height: 48,
            padding: EdgeInsets.zero,
            color: p.accent,
            onTap: _sending ? null : _send,
            child: Center(
              child: _sending
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.send, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  String _shortTime(String time) {
    if (time.length >= 16) return time.substring(5, 16);
    return time;
  }
}
