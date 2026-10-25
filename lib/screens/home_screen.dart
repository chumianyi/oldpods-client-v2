import 'dart:async';

import 'package:flutter/material.dart' hide Banner;

import '../models/models.dart';
import '../services/api_service.dart';
import '../services/device_bridge.dart';
import '../services/download_manager.dart';
import '../services/storage.dart';
import '../state/app_state.dart';
import '../theme/neu_theme.dart';
import '../widgets/common.dart';
import '../widgets/neu.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _api = ApiService.instance;

  HomeData? _home;
  List<Announcement> _announcements = <Announcement>[];
  List<AppItem> _recommended = <AppItem>[];
  bool _loading = true;
  String? _error;
  bool _checkedIn = false;

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
      final home = await _api.home();
      final annFuture = _api.announcements().catchError((Object _) => <Announcement>[]);
      final appsFuture = _api.appList(page: 1, sort: 'hot').then((v) => v.list).catchError((Object _) => <AppItem>[]);
      final ann = await annFuture;
      final apps = await appsFuture;
      if (!mounted) return;
      final today = _today();
      setState(() {
        _home = home;
        _announcements = ann.take(3).toList();
        _recommended = apps.take(8).toList();
        _checkedIn = Storage.instance.lastCheckinDate == today;
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

  String _today() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  void _openApp(int appId) {
    Navigator.pushNamed(context, '/app_detail', arguments: <String, dynamic>{'appId': appId});
  }

  void _openLink(String url) {
    if (url.isEmpty) return;
    final match = RegExp(r'app\.php\?id=(\d+)').firstMatch(url);
    if (url.contains('oldpods.cn') && match != null) {
      _openApp(int.tryParse(match.group(1) ?? '0') ?? 0);
      return;
    }
    DeviceBridge.instance.openUrl(url);
  }

  Future<void> _goCheckin() async {
    if (!AppState.instance.loggedIn) {
      showToast(context, '请先登录');
      Navigator.pushNamed(context, '/login');
      return;
    }
    final result = await Navigator.pushNamed(context, '/checkin');
    if (result == true && mounted) {
      final today = _today();
      setState(() => _checkedIn = true);
      Storage.instance.setLastCheckinDate(today);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = NeuPalette.of(context);
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: p.accent,
          backgroundColor: p.surface,
          onRefresh: _load,
          child: _loading && _home == null
              ? const LoadingView(message: '正在加载首页…')
              : (_error != null && _home == null
                  ? ErrorView(message: _error!, onRetry: _load)
                  : _buildContent(p)),
        ),
      ),
    );
  }

  Widget _buildContent(NeuPalette p) {
    final home = _home!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: <Widget>[
        _buildHeader(p, home),
        const SizedBox(height: 16),
        if (home.banners.isNotEmpty) ...<Widget>[
          _BannerCarousel(banners: home.banners, onTap: _openLink),
          const SizedBox(height: 16),
        ],
        NeuBox(radius: 26, color: p.accentSoft, padding: const EdgeInsets.all(24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('好应用，值得再遇见', style: TextStyle(color: p.text, fontSize: 27, height: 1.3)),
            const SizedBox(height: 10),
            Text('按系统与架构寻找适合你的版本。\n从发现到下载，在这里一站完成。', style: TextStyle(color: p.subText, height: 1.7)),
            const SizedBox(height: 18),
            NeuButton(text: '发现适合我的应用', icon: Icons.explore_outlined, primary: true,
              onPressed: () => Navigator.pushNamed(context, '/app_list', arguments: {'title': '发现应用'})),
          ])),
        const SizedBox(height: 16),
        NeuBox(onTap: () => Navigator.pushNamed(context, '/search'), radius: 18,
          padding: const EdgeInsets.all(16), child: Row(children: [
            Icon(Icons.search, color: p.accent), const SizedBox(width: 10),
            Expanded(child: Text('搜索应用、版本与创作者', style: TextStyle(color: p.subText))),
            Icon(Icons.arrow_forward, size: 18, color: p.subText),
          ])),
        const SizedBox(height: 20),
        _buildQuickActions(p),
        const SizedBox(height: 20),
        if (_announcements.isNotEmpty) ...<Widget>[
          SectionHeader(
            title: '公告',
            actionText: '全部',
            onAction: () => Navigator.pushNamed(context, '/announcements'),
          ),
          ..._announcements.map((a) => _AnnouncementCard(announcement: a)),
          const SizedBox(height: 12),
        ],
        if (home.categoryGroups.isNotEmpty) ...<Widget>[
          SectionHeader(title: '分类'),
          ...home.categoryGroups.map((List<Category> group) {
            if (group.isEmpty) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(group.first.groupName, style: TextStyle(color: p.subText, fontSize: 12.5, fontWeight: FontWeight.w300)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: group.map((Category c) {
                      return NeuChip(
                        label: c.name,
                        onTap: () => Navigator.pushNamed(context, '/app_list', arguments: <String, dynamic>{
                          'title': c.name,
                          'catIds': '${c.id}',
                        }),
                      );
                    }).toList(),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 8),
        ],
        if (_recommended.isNotEmpty) ...<Widget>[
          SectionHeader(
            title: '热门应用',
            actionText: '更多',
            onAction: () => Navigator.pushNamed(context, '/app_list', arguments: <String, dynamic>{
              'title': '全部应用',
              'q': null,
              'catIds': null,
            }),
          ),
          ..._recommended.map((AppItem item) => AppRowCard(item: item, onTap: () => _openApp(item.id))),
        ],
      ],
    );
  }

  Widget _buildHeader(NeuPalette p, HomeData home) {
    final greeting = _greeting();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(greeting, style: TextStyle(color: p.text, fontSize: 21, fontWeight: FontWeight.w300)),
              const SizedBox(height: 4),
              Text(
                '老豆荚 · 让旧设备重新焕发生机',
                style: TextStyle(color: p.subText, fontSize: 12),
              ),
              if (home.quote.content.isNotEmpty) ...<Widget>[
                const SizedBox(height: 6),
                Text(
                  '「${home.quote.content}」${home.quote.author}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: p.subText, fontSize: 11.5, fontStyle: FontStyle.italic),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 10),
        NeuIconButton(
          icon: Icons.search,
          tooltip: '搜索',
          onPressed: () => Navigator.pushNamed(context, '/search'),
        ),
        const SizedBox(width: 8),
        NeuIconButton(
          icon: Icons.download_outlined,
          tooltip: '下载管理',
          badge: DownloadManager.instance.tasks.where((t) => t.isActive).isNotEmpty,
          onPressed: () => Navigator.pushNamed(context, '/downloads'),
        ),
      ],
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 6) return '夜深了';
    if (hour < 11) return '早上好';
    if (hour < 14) return '中午好';
    if (hour < 18) return '下午好';
    return '晚上好';
  }

  Widget _buildQuickActions(NeuPalette p) {
    final items = <Widget>[
      _QuickAction(
        icon: Icons.event_available,
        label: _checkedIn ? '已签到' : '签到',
        highlight: !_checkedIn,
        onTap: _goCheckin,
      ),
      _QuickAction(
        icon: Icons.leaderboard_outlined,
        label: '排行榜',
        onTap: () => Navigator.pushNamed(context, '/leaderboard'),
      ),
      _QuickAction(
        icon: Icons.storefront_outlined,
        label: '商店',
        onTap: () => _requireLogin(() => Navigator.pushNamed(context, '/shop')),
      ),
      _QuickAction(
        icon: Icons.backpack_outlined,
        label: '背包',
        onTap: () => _requireLogin(() => Navigator.pushNamed(context, '/backpack')),
      ),
      _QuickAction(
        icon: Icons.star_border,
        label: '我的收藏',
        onTap: () => _requireLogin(() => Navigator.pushNamed(context, '/favorites')),
      ),
    ];
    return NeuBox(
      radius: 22,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: items.map((item) => Expanded(child: item)).toList(),
      ),
    );
  }

  void _requireLogin(VoidCallback action) {
    if (!AppState.instance.loggedIn) {
      showToast(context, '请先登录');
      Navigator.pushNamed(context, '/login');
      return;
    }
    action();
  }
}

class _BannerCarousel extends StatefulWidget {
  final List<Banner> banners;
  final ValueChanged<String> onTap;

  const _BannerCarousel({required this.banners, required this.onTap});

  @override
  State<_BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<_BannerCarousel> {
  final PageController _controller = PageController();
  int _page = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.banners.length > 1) {
      _timer = Timer.periodic(const Duration(seconds: 4), (_) {
        if (!mounted || !_controller.hasClients) return;
        final next = (_controller.page?.round() ?? _page) + 1;
        _controller.animateToPage(
          next % widget.banners.length,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = NeuPalette.of(context);
    return Column(
      children: <Widget>[
        SizedBox(
          height: 160,
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.banners.length,
            onPageChanged: (int i) => setState(() => _page = i),
            itemBuilder: (BuildContext context, int i) {
              final banner = widget.banners[i];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: NeuBox(
                  radius: 22,
                  padding: EdgeInsets.zero,
                  onTap: () => widget.onTap(banner.linkUrl),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: NetworkImageBox(url: banner.imageUrl, width: double.infinity, height: 160, fit: BoxFit.cover),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List<Widget>.generate(widget.banners.length, (int i) {
            final active = i == _page;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: active ? 16 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: active ? p.accent : p.divider,
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool highlight;

  const _QuickAction({required this.icon, required this.label, required this.onTap, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    final p = NeuPalette.of(context);
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            NeuBox(
              radius: 18,
              width: 44,
              height: 44,
              padding: EdgeInsets.zero,
              color: highlight ? p.accentSoft : null,
              child: Icon(icon, size: 21, color: highlight ? p.accent : p.text),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: highlight ? p.accent : p.subText, fontSize: 11.5, fontWeight: FontWeight.w300),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  final Announcement announcement;
  const _AnnouncementCard({required this.announcement});

  @override
  Widget build(BuildContext context) {
    final p = NeuPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: NeuBox(
        radius: 18,
        padding: const EdgeInsets.all(14),
        onTap: () => Navigator.pushNamed(context, '/announcements'),
        child: Row(
          children: <Widget>[
            NeuBox(inset: true, radius: 12, width: 38, height: 38, padding: EdgeInsets.zero, child: Icon(Icons.campaign, size: 19, color: p.accent)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    announcement.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: p.text, fontSize: 14, fontWeight: FontWeight.w300),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    stripHtml(announcement.content),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: p.subText, fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: p.subText),
          ],
        ),
      ),
    );
  }
}

class AppRowCard extends StatelessWidget {
  final AppItem item;
  final VoidCallback onTap;
  const AppRowCard({super.key, required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = NeuPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: NeuBox(
        radius: 20,
        padding: const EdgeInsets.all(12),
        onTap: onTap,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            NetworkImageBox(url: item.iconUrl, width: 56, height: 56, radius: 16, fallbackIcon: Icons.android),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: p.text, fontSize: 15, fontWeight: FontWeight.w300),
                  ),
                  const SizedBox(height: 5),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: <Widget>[
                      if (item.system.isNotEmpty) MetaTag(text: item.system),
                      if (item.size.isNotEmpty) MetaTag(text: item.size),
                      if (item.arch.isNotEmpty) MetaTag(text: item.arch),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: <Widget>[
                      Icon(Icons.download_outlined, size: 13, color: p.subText),
                      const SizedBox(width: 3),
                      Text('${item.downloads}', style: TextStyle(color: p.subText, fontSize: 11.5)),
                      const SizedBox(width: 12),
                      StarRating(value: item.ratingAvg, size: 12),
                      const SizedBox(width: 4),
                      Text(item.ratingAvg.toStringAsFixed(1), style: TextStyle(color: p.subText, fontSize: 11.5)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
