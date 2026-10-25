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
      final items = await _api.leaderboard(_type);
      if (!mounted) return;
      setState(() {
        _items = items;
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
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
            child: NeuSegmented<String>(
              values: const <String>['streak', 'today'],
              labels: const <String>['连续签到', '今日签到'],
              value: _type,
              onChanged: (String v) {
                setState(() => _type = v);
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
                                return _RankRow(item: item, index: i);
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
  const _RankRow({required this.item, required this.index});

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
                  '${item.streak > 0 ? item.streak : item.score} 天',
                  style: TextStyle(color: p.accent, fontSize: 14, fontWeight: FontWeight.w300),
                ),
                Text('连续签到', style: TextStyle(color: p.subText, fontSize: 10)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
