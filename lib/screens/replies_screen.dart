import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/api_client.dart';
import '../services/api_service.dart';
import '../state/app_state.dart';
import '../theme/neu_theme.dart';
import '../widgets/common.dart';
import '../widgets/neu.dart';

/// 我的回复（replies.php）
class RepliesScreen extends StatefulWidget {
  const RepliesScreen({super.key});

  @override
  State<RepliesScreen> createState() => _RepliesScreenState();
}

class _RepliesScreenState extends State<RepliesScreen> {
  final ApiService _api = ApiService.instance;

  ReplyList? _data;
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
      final list = await _api.replies();
      if (!mounted) return;
      setState(() {
        _data = list;
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

  Future<void> _delete(ReplyItem item) async {
    final go = await confirmDialog(context, title: '删除回复', content: '确定删除这条回复？', danger: true);
    if (!go) return;
    try {
      await _api.deleteReply(item.id);
      showToast(context, '已删除');
      _load();
    } on ApiException catch (e) {
      showToast(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = NeuPalette.of(context);
    final list = _data?.list ?? <ReplyItem>[];
    return Scaffold(
      appBar: NeuAppBar(
        title: '我的回复',
        leading: NeuIconButton(icon: Icons.arrow_back, size: 40, onPressed: () => Navigator.pop(context)),
      ),
      body: !AppState.instance.loggedIn
          ? const EmptyView(message: '登录后查看我的回复', icon: Icons.lock_outline)
          : RefreshIndicator(
              color: p.accent,
              backgroundColor: p.surface,
              onRefresh: _load,
              child: _loading && _data == null
                  ? ListView(children: const <Widget>[SizedBox(height: 240, child: LoadingView())])
                  : (_error != null && _data == null
                      ? ListView(children: <Widget>[SizedBox(height: 300, child: ErrorView(message: _error!, onRetry: _load))])
                      : (list.isEmpty
                          ? ListView(children: const <Widget>[SizedBox(height: 300, child: EmptyView(message: '暂无回复', icon: Icons.reply))])
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
                              itemCount: list.length,
                              itemBuilder: (BuildContext context, int i) {
                                final item = list[i];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: NeuBox(
                                    radius: 18,
                                    padding: const EdgeInsets.all(14),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: <Widget>[
                                              if (item.appTitle.isNotEmpty) ...<Widget>[
                                                GestureDetector(
                                                  onTap: () => Navigator.pushNamed(context, '/app_detail', arguments: <String, dynamic>{'appId': item.appId}),
                                                  child: Text(
                                                    item.appTitle,
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: TextStyle(color: p.accent, fontSize: 13, fontWeight: FontWeight.w300),
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                              ],
                                              Text(
                                                item.content,
                                                style: TextStyle(color: p.text, fontSize: 13.5, height: 1.45),
                                              ),
                                              if (item.createdAt.isNotEmpty) ...<Widget>[
                                                const SizedBox(height: 6),
                                                Text(item.createdAt, style: TextStyle(color: p.subText, fontSize: 11)),
                                              ],
                                            ],
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () => _delete(item),
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
