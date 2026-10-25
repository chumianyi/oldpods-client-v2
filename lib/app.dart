import 'package:flutter/material.dart';

import 'screens/announcements_screen.dart';
import 'screens/app_detail_screen.dart';
import 'screens/app_list_screen.dart';
import 'screens/backpack_screen.dart';
import 'screens/checkin_screen.dart';
import 'screens/downloads_screen.dart';
import 'screens/edit_profile_screen.dart';
import 'screens/favorites_screen.dart';
import 'screens/frames_screen.dart';
import 'screens/leaderboard_screen.dart';
import 'screens/login_screen.dart';
import 'screens/main_shell.dart';
import 'screens/message_detail_screen.dart';
import 'screens/messages_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/replies_screen.dart';
import 'screens/search_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/shop_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/submissions_screen.dart';
import 'screens/system_messages_screen.dart';
import 'screens/terms_screen.dart';
import 'screens/user_center_screen.dart';
import 'state/app_state.dart';
import 'theme/neu_theme.dart';

class OldPodsApp extends StatelessWidget {
  const OldPodsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppState.instance,
      builder: (BuildContext context, Widget? _) {
        return MaterialApp(
          title: '老豆荚',
          debugShowCheckedModeBanner: false,
          theme: NeuTheme.light(),
          darkTheme: NeuTheme.dark(),
          themeMode: AppState.instance.themeMode == 1
              ? ThemeMode.light
              : (AppState.instance.themeMode == 2 ? ThemeMode.dark : ThemeMode.system),
          initialRoute: '/',
          onGenerateRoute: _onGenerateRoute,
        );
      },
    );
  }

  Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
    final Object? args = settings.arguments;
    final Map<String, dynamic> a = args is Map<String, dynamic> ? args : <String, dynamic>{};
    Widget page;
    switch (settings.name) {
      case '/':
        page = const SplashScreen();
        break;
      case '/main':
        page = const MainShell();
        break;
      case '/app_list':
        page = AppListScreen(
          title: a['title'] as String? ?? '应用',
          catIds: a['catIds'] as String?,
          catGroups: a['catGroups'] as String?,
          q: a['q'] as String?,
        );
        break;
      case '/app_detail':
        page = AppDetailScreen(appId: a['appId'] as int? ?? 0);
        break;
      case '/search':
        page = SearchScreen(initialQuery: a['q'] as String?);
        break;
      case '/replies':
        page = const RepliesScreen();
        break;
      case '/messages':
        page = const MessagesScreen();
        break;
      case '/message_detail':
        page = MessageDetailScreen(
          convId: a['convId'] as int? ?? 0,
          peerId: a['peerId'] as int? ?? 0,
          nickname: a['nickname'] as String? ?? '私信',
        );
        break;
      case '/system_messages':
        page = const SystemMessagesScreen();
        break;
      case '/profile':
        page = ProfileScreen(userId: a['userId'] as int? ?? 0);
        break;
      case '/user_center':
        page = const UserCenterScreen();
        break;
      case '/login':
        page = LoginScreen(initialTab: a['tab'] as int? ?? 0);
        break;
      case '/edit_profile':
        page = const EditProfileScreen();
        break;
      case '/favorites':
        page = const FavoritesScreen();
        break;
      case '/submissions':
        page = const SubmissionsScreen();
        break;
      case '/shop':
        page = const ShopScreen();
        break;
      case '/backpack':
        page = const BackpackScreen();
        break;
      case '/frames':
        page = const FramesScreen();
        break;
      case '/leaderboard':
        page = const LeaderboardScreen();
        break;
      case '/checkin':
        page = const CheckinScreen();
        break;
      case '/announcements':
        page = const AnnouncementsScreen();
        break;
      case '/terms':
        page = const TermsScreen();
        break;
      case '/settings':
        page = const SettingsScreen();
        break;
      case '/downloads':
        page = const DownloadsScreen();
        break;
      default:
        page = _NotFoundPage(name: settings.name ?? '');
        break;
    }
    return MaterialPageRoute<dynamic>(builder: (BuildContext context) => page, settings: settings);
  }
}

class _NotFoundPage extends StatelessWidget {
  final String name;
  const _NotFoundPage({required this.name});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('页面不存在')),
      body: Center(child: Text('找不到页面：$name')),
    );
  }
}
