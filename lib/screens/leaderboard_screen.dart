import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/neu_theme.dart';
import '../widgets/common.dart';
import '../widgets/neu.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final ApiService _api = ApiService.instance;

  String _type = 'streak';
  List<LeaderboardItem> _items = <LeaderboardItem>[];
  bool _loading = true;
  String? _error;
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final requestId = ++_requestId;
    final type = _type;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await _api.leaderboard(type);
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = NeuPalette.of(context);
    return Scaffold(
      appBar: NeuAppBar(
        title: '排行榜',
        leading: NeuIconButton(icon: Icons.arrow_back, size: 40, onPressed: () => Navigator.pop(context)),
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: NeuBox(
              radius: 22,
              padding: const EdgeInsets.all(18),
              child: Row(children: <Widget>[
                Icon(_type == 'today' ? Icons.schedule : Icons.local_fire_department_outlined, color: p.accent, size: 32),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                  Text(_type == 'today' ? '每日签到榜' : '连续签到榜', style: TextStyle(color: p.text, fontSize: 20)),
                  const SizedBox(height: 6),
                  Text(_type == 'today' ? '记录今天的签到时刻，不与连续天数混用' : '每一天的坚持，都值得被看见', style: TextStyle(color: p.subText, fontSize: 12, height: 1.5)),
                ])),
              ]),
            ),
          ),
          if (_error != null && _items.isNotEmpty)
            Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: TextButton.icon(
              onPressed: _load, icon: const Icon(Icons.refresh), label: const Text('刷新失败，点击重试'))),
          if (_loading && _items.isNotEmpty) const LinearProgressIndicator(minHeight: 2),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
            child: NeuSegmented<String>(
              values: const <String>['streak', 'today'],
              labels: const <String>['连续签到', '今日签到'],
              value: _type,
              onChanged: (String v) {
                if (_type == v) return;
                setState(() { _type = v; _items = <LeaderboardItem>[]; });
                _load();
              },
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              color: p.accent,
              backgroundColor: p.surface,
              onRefresh: _load,
              child: _loading && _items.isEmpty
                  ? ListView(children: const <Widget>[SizedBox(height: 240, child: LoadingView())])
                  : (_error != null && _items.isEmpty
                      ? ListView(children: <Widget>[SizedBox(height: 300, child: ErrorView(message: _error!, onRetry: _load))])
                      : (_items.isEmpty
                          ? ListView(children: const <Widget>[SizedBox(height: 300, child: EmptyView(message: '暂无排行数据', icon: Icons.leaderboard))])
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                              itemCount: _items.length,
                              itemBuilder: (BuildContext context, int i) {
                                final item = _items[i];
                                return _RankRow(item: item, index: i, today: _type == 'today');
                              },
                            ))),
            ),
          ),
        ],
      ),
    );
  }
}

class _RankRow extends StatelessWidget {
  final LeaderboardItem item;
  final int index;
  final bool today;
  const _RankRow({required this.item, required this.index, required this.today});

  @override
  Widget build(BuildContext context) {
    final p = NeuPalette.of(context);
    final rank = item.rank > 0 ? item.rank : index + 1;
    Color? rankColor;
    if (rank == 1) rankColor = const Color(0xFFFFD54F);
    if (rank == 2) rankColor = const Color(0xFFB0BEC5);
    if (rank == 3) rankColor = const Color(0xFFD7A86E);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: NeuBox(
        radius: 18,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: <Widget>[
            SizedBox(
              width: 34,
              child: Center(
                child: rank <= 3
                    ? Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(color: rankColor, shape: BoxShape.circle),
                        child: Center(
                          child: Text('$rank', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w300)),
                        ),
                      )
                    : Text('$rank', style: TextStyle(color: p.subText, fontSize: 14, fontWeight: FontWeight.w300)),
              ),
            ),
            AvatarFrame(
              avatar: item.avatar,
              frame: item.frame,
              frameW: item.frameW,
              frameX: item.frameX,
              frameY: item.frameY,
              size: 42,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item.nickname,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: p.text, fontSize: 14, fontWeight: FontWeight.w300),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Text(
                  today ? item.timeLabel : '${item.streak > 0 ? item.streak : item.score} 天',
                  style: TextStyle(color: p.accent, fontSize: 14, fontWeight: FontWeight.w300),
                ),
                Text(today ? '签到时间' : '连续签到', style: TextStyle(color: p.subText, fontSize: 10)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
