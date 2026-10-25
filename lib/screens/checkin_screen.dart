import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../services/api_service.dart';
import '../services/storage.dart';
import '../state/app_state.dart';
import '../theme/neu_theme.dart';
import '../widgets/common.dart';
import '../widgets/neu.dart';

class CheckinScreen extends StatefulWidget {
  const CheckinScreen({super.key});

  @override
  State<CheckinScreen> createState() => _CheckinScreenState();
}

class _CheckinScreenState extends State<CheckinScreen> {
  final ApiService _api = ApiService.instance;

  bool _loading = false;
  bool _done = false;
  int _streak = 0;
  String? _resultMessage;

  @override
  void initState() {
    super.initState();
    final today = _today();
    _done = Storage.instance.lastCheckinDate == today;
    _loadStreak();
  }

  String _today() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> _loadStreak() async {
    if (!AppState.instance.loggedIn) return;
    try {
      final list = await _api.leaderboard('streak');
      if (!mounted) return;
      final my = list.where((item) => item.nickname == (AppState.instance.nickname ?? ''));
      if (my.isNotEmpty) {
        setState(() => _streak = my.first.streak);
      }
    } catch (_) {}
  }

  Future<void> _checkin() async {
    if (!AppState.instance.loggedIn) {
      showToast(context, '请先登录');
      Navigator.pushNamed(context, '/login');
      return;
    }
    setState(() => _loading = true);
    try {
      final result = await _api.checkin();
      await Storage.instance.setLastCheckinDate(_today());
      await AppState.instance.refreshUser();
      if (!mounted) return;
      final coins = result['coins'] ?? result['reward'] ?? result['coin'];
      final streak = result['streak'] ?? result['days'];
      setState(() {
        _done = true;
        _loading = false;
        _resultMessage = [
          if (coins != null) '获得 $coins 硬币',
          if (streak != null) '已连续签到 $streak 天',
          if (coins == null && streak == null) '签到成功',
        ].join('，');
        if (streak != null) {
          final n = int.tryParse('$streak');
          if (n != null) _streak = n;
        }
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      showToast(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = NeuPalette.of(context);
    return Scaffold(
      appBar: NeuAppBar(
        title: '每日签到',
        leading: NeuIconButton(icon: Icons.arrow_back, size: 40, onPressed: () => Navigator.pop(context)),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              NeuBox(
                radius: 60,
                width: 120,
                height: 120,
                padding: EdgeInsets.zero,
                color: _done ? p.success : p.surface,
                child: Icon(_done ? Icons.check_circle : Icons.event_available, size: 54, color: _done ? Colors.white : p.accent),
              ),
              const SizedBox(height: 22),
              Text(
                _done ? '今日已签到' : '今日还未签到',
                style: TextStyle(color: p.text, fontSize: 20, fontWeight: FontWeight.w300),
              ),
              const SizedBox(height: 8),
              if (_streak > 0)
                Text('已连续签到 $_streak 天', style: TextStyle(color: p.subText, fontSize: 13.5))
              else
                Text('每天签到可领取硬币奖励', style: TextStyle(color: p.subText, fontSize: 13.5)),
              if (_resultMessage != null) ...<Widget>[
                const SizedBox(height: 10),
                Text(_resultMessage!, style: TextStyle(color: p.success, fontSize: 14, fontWeight: FontWeight.w300)),
              ],
              const SizedBox(height: 26),
              if (!_done)
                NeuButton(
                  text: '立即签到',
                  icon: Icons.event_available,
                  primary: true,
                  width: 200,
                  loading: _loading,
                  onPressed: _checkin,
                ),
              if (_done)
                NeuButton(
                  text: '看看排行榜',
                  icon: Icons.leaderboard_outlined,
                  width: 200,
                  onPressed: () => Navigator.pushReplacementNamed(context, '/leaderboard'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
