import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme/neu_theme.dart';
import '../widgets/common.dart';
import '../widgets/neu.dart';

class UserCenterScreen extends StatefulWidget {
  const UserCenterScreen({super.key});

  @override
  State<UserCenterScreen> createState() => _UserCenterScreenState();
}

class _UserCenterScreenState extends State<UserCenterScreen> {
  @override
  void initState() {
    super.initState();
    AppState.instance.addListener(_onChange);
    if (AppState.instance.loggedIn) {
      AppState.instance.refreshUser();
      AppState.instance.refreshUnread();
    }
  }

  @override
  void dispose() {
    AppState.instance.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  void _requireLogin(VoidCallback action) {
    if (!AppState.instance.loggedIn) {
      showToast(context, '请先登录');
      Navigator.pushNamed(context, '/login');
      return;
    }
    action();
  }

  @override
  Widget build(BuildContext context) {
    final p = NeuPalette.of(context);
    final loggedIn = AppState.instance.loggedIn;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
          children: <Widget>[
            _buildProfileCard(p, loggedIn),
            const SizedBox(height: 18),
            SectionHeader(title: '我的'),
            _buildGrid(p),
            const SizedBox(height: 18),
            SectionHeader(title: '更多'),
            _buildMoreList(p),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(NeuPalette p, bool loggedIn) {
    if (!loggedIn) {
      return NeuBox(
        radius: 24,
        padding: const EdgeInsets.all(22),
        child: Column(
          children: <Widget>[
            NeuBox(inset: true, radius: 42, width: 84, height: 84, padding: EdgeInsets.zero, child: Icon(Icons.person_outline, size: 40, color: p.subText)),
            const SizedBox(height: 14),
            Text('未登录', style: TextStyle(color: p.text, fontSize: 17, fontWeight: FontWeight.w300)),
            const SizedBox(height: 6),
            Text('登录后可收藏应用、签到领硬币、私信交流', textAlign: TextAlign.center, style: TextStyle(color: p.subText, fontSize: 12.5)),
            const SizedBox(height: 16),
            NeuButton(
              text: '登录 / 注册',
              icon: Icons.login,
              primary: true,
              onPressed: () => Navigator.pushNamed(context, '/login'),
            ),
          ],
        ),
      );
    }
    final info = AppState.instance.userInfo;
    return NeuBox(
      radius: 24,
      padding: const EdgeInsets.all(18),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/edit_profile'),
                child: Stack(
                  children: <Widget>[
                    AvatarFrame(
                      avatar: AppState.instance.avatar,
                      frame: info?.frame,
                      frameW: info?.frameW ?? 100,
                      frameX: info?.frameX ?? 0,
                      frameY: info?.frameY ?? 0,
                      size: 66,
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(color: p.accent, shape: BoxShape.circle),
                        child: const Icon(Icons.camera_alt, size: 11, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Flexible(
                          child: Text(
                            AppState.instance.nickname ?? '用户${AppState.instance.userId}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: p.text, fontSize: 17, fontWeight: FontWeight.w300),
                          ),
                        ),
                        if (info?.isVerified == true) ...<Widget>[
                          const SizedBox(width: 5),
                          Icon(Icons.verified, size: 16, color: p.accent),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('ID: ${AppState.instance.userId}', style: TextStyle(color: p.subText, fontSize: 12)),
                    if (info != null && info.memberType.isNotEmpty && info.isMember) ...<Widget>[
                      const SizedBox(height: 6),
                      MetaTag(text: info.isMemberPermanent ? '永久会员' : '会员', color: p.warning, icon: Icons.workspace_premium),
                    ],
                  ],
                ),
              ),
              Column(
                children: <Widget>[
                  NeuBox(
                    inset: true,
                    radius: 16,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    child: Column(
                      children: <Widget>[
                        Icon(Icons.savings_outlined, size: 18, color: p.warning),
                        const SizedBox(height: 2),
                        Text(
                          '${info?.coins ?? 0}',
                          style: TextStyle(color: p.text, fontSize: 15, fontWeight: FontWeight.w300),
                        ),
                        Text('硬币', style: TextStyle(color: p.subText, fontSize: 10)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              Expanded(
                child: NeuButton(
                  text: '编辑资料',
                  icon: Icons.edit_outlined,
                  compact: true,
                  onPressed: () => Navigator.pushNamed(context, '/edit_profile'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: NeuButton(
                  text: '我的主页',
                  icon: Icons.person_outline,
                  compact: true,
                  onPressed: () => Navigator.pushNamed(context, '/profile', arguments: <String, dynamic>{'userId': AppState.instance.userId}),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(NeuPalette p) {
    final entries = <_Entry>[
      _Entry(icon: Icons.upload_file, label: '我的投稿', onTap: () => _requireLogin(() => Navigator.pushNamed(context, '/submissions'))),
      _Entry(icon: Icons.star_border, label: '我的收藏', onTap: () => _requireLogin(() => Navigator.pushNamed(context, '/favorites'))),
      _Entry(icon: Icons.reply, label: '我的回复', onTap: () => _requireLogin(() => Navigator.pushNamed(context, '/replies'))),
      _Entry(icon: Icons.storefront_outlined, label: '商店', onTap: () => _requireLogin(() => Navigator.pushNamed(context, '/shop'))),
      _Entry(icon: Icons.backpack_outlined, label: '背包', onTap: () => _requireLogin(() => Navigator.pushNamed(context, '/backpack'))),
      _Entry(icon: Icons.face_retouching_natural, label: '头像框', onTap: () => _requireLogin(() => Navigator.pushNamed(context, '/frames'))),
      _Entry(icon: Icons.leaderboard_outlined, label: '排行榜', onTap: () => Navigator.pushNamed(context, '/leaderboard')),
      _Entry(icon: Icons.event_available, label: '签到', onTap: () => _requireLogin(() => Navigator.pushNamed(context, '/checkin'))),
      _Entry(icon: Icons.download_outlined, label: '下载管理', onTap: () => Navigator.pushNamed(context, '/downloads')),
    ];
    return NeuBox(
      radius: 22,
      padding: const EdgeInsets.all(14),
      child: GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 8,
        crossAxisSpacing: 4,
        children: entries.map((_Entry e) {
          return GestureDetector(
            onTap: e.onTap,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                NeuBox(
                  radius: 18,
                  width: 46,
                  height: 46,
                  padding: EdgeInsets.zero,
                  child: Icon(e.icon, size: 21, color: p.text),
                ),
                const SizedBox(height: 6),
                Text(
                  e.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: p.subText, fontSize: 11.5),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMoreList(NeuPalette p) {
    final items = <_MoreItem>[
      _MoreItem(icon: Icons.notifications_none, label: '消息中心', onTap: () => _requireLogin(() => Navigator.pushNamed(context, '/messages'))),
      _MoreItem(icon: Icons.campaign_outlined, label: '公告', onTap: () => Navigator.pushNamed(context, '/announcements')),
      _MoreItem(icon: Icons.description_outlined, label: '用户协议', onTap: () => Navigator.pushNamed(context, '/terms')),
      _MoreItem(icon: Icons.settings_outlined, label: '设置', onTap: () => Navigator.pushNamed(context, '/settings')),
      if (AppState.instance.loggedIn)
        _MoreItem(
          icon: Icons.logout,
          label: '退出登录',
          danger: true,
          onTap: () async {
            final go = await confirmDialog(context, title: '退出登录', content: '确定退出当前账号？');
            if (!go) return;
            await AppState.instance.logout();
            if (mounted) showToast(context, '已退出登录');
          },
        ),
    ];
    return NeuBox(
      radius: 22,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: items.map((_MoreItem item) {
          return ListTile(
            leading: Icon(item.icon, color: item.danger ? p.danger : p.text, size: 21),
            title: Text(item.label, style: TextStyle(color: item.danger ? p.danger : p.text, fontSize: 14.5, fontWeight: FontWeight.w300)),
            trailing: Icon(Icons.chevron_right, color: p.subText),
            onTap: item.onTap,
          );
        }).toList(),
      ),
    );
  }
}

class _Entry {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  _Entry({required this.icon, required this.label, required this.onTap});
}

class _MoreItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;
  _MoreItem({required this.icon, required this.label, required this.onTap, this.danger = false});
}
