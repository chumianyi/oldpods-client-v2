import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/api_client.dart';
import '../services/api_service.dart';
import '../state/app_state.dart';
import '../theme/neu_theme.dart';
import '../widgets/common.dart';
import '../widgets/neu.dart';

class SystemMessagesScreen extends StatefulWidget {
  const SystemMessagesScreen({super.key});

  @override
  State<SystemMessagesScreen> createState() => _SystemMessagesScreenState();
}

class _SystemMessagesScreenState extends State<SystemMessagesScreen> {
  final ApiService _api = ApiService.instance;

  SystemMessageList? _data;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _api.systemMessages();
      if (!mounted) return;
      setState(() {
        _data = list;
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
  }

  Future<void> _delete(SystemMessage m) async {
    final go = await confirmDialog(context, title: '删除消息', content: '确定删除这条系统消息？', danger: true);
    if (!go) return;
    try {
      await _api.deleteSystemMessage(m.id);
      showToast(context, '已删除');
      _load();
    } on ApiException catch (e) {
      showToast(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = NeuPalette.of(context);
    final list = _data?.list ?? <SystemMessage>[];
    return Scaffold(
      appBar: NeuAppBar(
        title: '系统消息',
        leading: NeuIconButton(icon: Icons.arrow_back, size: 40, onPressed: () => Navigator.pop(context)),
      ),
      body: RefreshIndicator(
        color: p.accent,
        backgroundColor: p.surface,
        onRefresh: _load,
        child: _loading && _data == null
            ? ListView(children: const <Widget>[SizedBox(height: 240, child: LoadingView())])
            : (_error != null && _data == null
                ? ListView(children: <Widget>[SizedBox(height: 300, child: ErrorView(message: _error!, onRetry: _load))])
                : (list.isEmpty
                    ? ListView(children: const <Widget>[SizedBox(height: 300, child: EmptyView(message: '暂无系统消息', icon: Icons.notifications_off))])
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
                        itemCount: list.length,
                        itemBuilder: (BuildContext context, int i) {
                          final m = list[i];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: NeuBox(
                              radius: 18,
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  if (!m.isRead) ...<Widget>[
                                    Container(
                                      margin: const EdgeInsets.only(top: 6, right: 8),
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(color: p.danger, shape: BoxShape.circle),
                                    ),
                                  ],
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: <Widget>[
                                        if (m.title.isNotEmpty) ...<Widget>[
                                          Text(m.title, style: TextStyle(color: p.text, fontSize: 14.5, fontWeight: FontWeight.w300)),
                                          const SizedBox(height: 4),
                                        ],
                                        Text(
                                          stripHtml(m.content),
                                          style: TextStyle(color: p.subText, fontSize: 13, height: 1.5),
                                        ),
                                        if (m.createdAt.isNotEmpty) ...<Widget>[
                                          const SizedBox(height: 6),
                                          Text(m.createdAt, style: TextStyle(color: p.subText, fontSize: 11)),
                                        ],
                                      ],
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => _delete(m),
                                    child: Padding(
                                      padding: const EdgeInsets.all(4),
                                      child: Icon(Icons.delete_outline, size: 17, color: p.subText),
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
