import 'package:flutter/material.dart';

import '../services/download_manager.dart';
import '../state/app_state.dart';
import '../theme/neu_theme.dart';
import '../widgets/neu.dart';
import 'home_screen.dart';
import 'browse_screen.dart';
import 'messages_screen.dart';
import 'user_center_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  final List<Widget> _pages = const <Widget>[
    HomeScreen(),
    BrowseScreen(),
    MessagesScreen(),
    UserCenterScreen(),
  ];

  final List<String> _titles = const <String>['首页', '应用', '消息', '我的'];

  @override
  void initState() {
    super.initState();
    AppState.instance.refreshUnread();
    AppState.instance.addListener(_onStateChanged);
  }

  void _onStateChanged() { if (mounted) setState(() {}); }

  @override
  void dispose() {
    AppState.instance.removeListener(_onStateChanged);
    super.dispose();
  }

  void _goTab(int i) {
    if (i == 2) AppState.instance.refreshUnread();
    setState(() => _index = i);
  }

  @override
  Widget build(BuildContext context) {
    final p = NeuPalette.of(context);
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: _NeuBottomBar(
        index: _index,
        titles: _titles,
        onTap: _goTab,
        unread: AppState.instance.unread,
      ),
      floatingActionButton: _index == 1 ? _BrowseFab(p) : null,
    );
  }

  Widget _BrowseFab(NeuPalette p) {
    return FloatingActionButton(
      backgroundColor: p.accent,
      elevation: 6,
      child: const Icon(Icons.search, color: Colors.white),
      onPressed: () => Navigator.pushNamed(context, '/search'),
    );
  }
}

class _NeuBottomBar extends StatelessWidget {
  final int index;
  final List<String> titles;
  final ValueChanged<int> onTap;
  final int unread;

  const _NeuBottomBar({
    required this.index,
    required this.titles,
    required this.onTap,
    required this.unread,
  });

  static const List<IconData> _icons = <IconData>[
    Icons.home_outlined,
    Icons.apps_outlined,
    Icons.chat_bubble_outline,
    Icons.person_outline,
  ];

  static const List<IconData> _activeIcons = <IconData>[
    Icons.home,
    Icons.apps,
    Icons.chat_bubble,
    Icons.person,
  ];

  @override
  Widget build(BuildContext context) {
    final p = NeuPalette.of(context);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
        child: NeuBox(
          radius: 26,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List<Widget>.generate(titles.length, (int i) {
              final selected = i == index;
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onTap(i),
                child: SizedBox(
                  width: (MediaQuery.of(context).size.width - 40) / titles.length,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Stack(
                        clipBehavior: Clip.none,
                        children: <Widget>[
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 160),
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: selected ? p.accentSoft : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              selected ? _activeIcons[i] : _icons[i],
                              size: 22,
                              color: selected ? p.accent : p.subText,
                            ),
                          ),
                          if (i == 2 && unread > 0)
                            Positioned(
                              right: -2,
                              top: -2,
                              child: NeuBadge(count: unread, size: 16),
                            ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        titles[i],
                        style: TextStyle(
                          color: selected ? p.accent : p.subText,
                          fontSize: 11,
                          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

/// 下载浮动入口（全局可用）
class DownloadsFab extends StatelessWidget {
  const DownloadsFab({super.key});

  @override
  Widget build(BuildContext context) {
    final p = NeuPalette.of(context);
    final active = DownloadManager.instance.tasks.where((t) => t.isActive).length;
    return FloatingActionButton(
      backgroundColor: p.accent,
      onPressed: () => Navigator.pushNamed(context, '/downloads'),
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          const Icon(Icons.download, color: Colors.white),
          if (active > 0)
            Positioned(
              right: -4,
              top: -4,
              child: NeuBadge(count: active, size: 16),
            ),
        ],
      ),
    );
  }
}
