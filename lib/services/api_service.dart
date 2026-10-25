import 'package:http/http.dart' as http;

import '../models/models.dart';
import 'api_client.dart';

/// 老豆荚全量接口封装（对应《接口规范标准》全部端点）。
class ApiService {
  ApiService._();

  static final ApiService instance = ApiService._();

  final ApiClient _c = ApiClient.instance;

  /// 当前登录用户 id（由 AppState 维护），用于判断私信是否为自己发出
  int myUserId = 0;

  // ==================== 会话 / 设备 / 签到 ====================

  /// GET / 建立会话 Cookie
  Future<void> initSession() => _c.ensureSession(force: true);

  /// POST /api/report_device.php 上报设备信息
  Future<void> reportDevice(Map<String, String> fields) async {
    final r = await _c.post('/api/report_device.php', body: fields);
    if (!r.ok) throw ApiException(r.msg.isEmpty ? '设备信息上报失败' : r.msg);
  }

  /// POST /api/checkin.php 每日签到
  Future<Map<String, dynamic>> checkin() async {
    final r = await _c.post('/api/checkin.php', body: const <String, String>{});
    if (!r.ok) throw ApiException(r.msg.isEmpty ? '签到失败' : r.msg);
    return r.dataMap ?? <String, dynamic>{};
  }

  /// GET /api/check_update.php 检查更新
  Future<CheckUpdate> checkUpdate({String version = '1.0.0', int versionCode = 1}) async {
    final r = await _c.get('/api/check_update.php', params: <String, String>{
      'current_version': version,
      'version_code': '$versionCode',
      'current_version_code': '$versionCode',
    });
    if (!r.ok) throw ApiException(r.msg.isEmpty ? '检查更新失败' : r.msg);
    return CheckUpdate.fromJson(r.dataMap ?? <String, dynamic>{});
  }

  // ==================== 首页 / 浏览 ====================

  /// GET /api/home.php 首页
  Future<HomeData> home() async {
    final r = await _c.get('/api/home.php');
    if (!r.ok) throw ApiException(r.msg.isEmpty ? '首页加载失败' : r.msg);
    return HomeData.fromJson(r.dataMap ?? <String, dynamic>{});
  }

  /// GET /api/app_list.php 应用列表
  Future<AppListData> appList({
    int page = 1,
    String? sort,
    String? catIds,
    String? catGroups,
    String? q,
  }) async {
    final params = <String, String>{'page': '$page'};
    if (sort != null && sort.isNotEmpty) params['sort'] = sort;
    if (catIds != null && catIds.isNotEmpty) params['cat_ids'] = catIds;
    if (catGroups != null && catGroups.isNotEmpty) params['cat_groups'] = catGroups;
    if (q != null && q.isNotEmpty) params['q'] = q;
    final r = await _c.get('/api/app_list.php', params: params);
    if (!r.ok) throw ApiException(r.msg.isEmpty ? '应用列表加载失败' : r.msg);
    return AppListData.fromJson(r.dataMap ?? <String, dynamic>{});
  }

  /// GET /api/app_detail.php 应用详情
  Future<AppDetail> appDetail(int id) async {
    final r = await _c.get('/api/app_detail.php', params: <String, String>{'id': '$id'});
    if (!r.ok) throw ApiException(r.msg.isEmpty ? '应用详情加载失败' : r.msg);
    return AppDetail.fromJson(r.dataMap ?? <String, dynamic>{});
  }

  /// GET /api/announcements.php 公告列表
  Future<List<Announcement>> announcements() async {
    final r = await _c.get('/api/announcements.php');
    if (!r.ok) throw ApiException(r.msg.isEmpty ? '公告加载失败' : r.msg);
    return parseList(r.dataMap ?? <String, dynamic>{}).map(Announcement.fromJson).toList();
  }

  /// GET /api/terms.php 用户协议
  Future<TermsData> terms() async {
    final r = await _c.get('/api/terms.php');
    if (!r.ok) throw ApiException(r.msg.isEmpty ? '协议加载失败' : r.msg);
    return TermsData.fromJson(r.dataMap ?? <String, dynamic>{});
  }

  /// GET /api/leaderboard.php 排行榜
  Future<List<LeaderboardItem>> leaderboard(String type) async {
    final r = await _c.get('/api/leaderboard.php', params: <String, String>{'type': type});
    if (!r.ok) throw ApiException(r.msg.isEmpty ? '排行榜加载失败' : r.msg);
    return parseList(r.dataMap ?? <String, dynamic>{}).map(LeaderboardItem.fromJson).toList();
  }

  /// GET /api/search_users.php 搜索用户
  Future<List<UserItem>> searchUsers(String q, {int page = 1}) async {
    final r = await _c.get('/api/search_users.php', params: <String, String>{
      'q': q,
      'page': '$page',
    });
    if (!r.ok) throw ApiException(r.msg.isEmpty ? '用户搜索失败' : r.msg);
    return parseList(r.dataMap ?? <String, dynamic>{}).map(UserItem.fromJson).toList();
  }

  // ==================== 评论 / 评分 ====================

  /// GET /api/comments.php 评论列表
  Future<CommentList> comments({required int appId, int page = 1, int perPage = 30}) async {
    final r = await _c.get('/api/comments.php', params: <String, String>{
      'app_id': '$appId',
      'page': '$page',
      'per_page': '$perPage',
    });
    if (!r.ok) throw ApiException(r.msg.isEmpty ? '评论加载失败' : r.msg);
    return CommentList.fromJson(r.dataMap ?? <String, dynamic>{});
  }

  /// POST /api/comments.php 发表评论
  Future<void> postComment({required int appId, required String content}) async {
    final r = await _c.post('/api/comments.php', body: <String, String>{
      'app_id': '$appId',
      'content': content,
    });
    if (!r.ok) throw ApiException(r.msg.isEmpty ? '评论发表失败' : r.msg);
  }

  /// POST /api/rating.php 应用评分
  Future<void> rateApp({required int appId, required int rating}) async {
    final r = await _c.post('/api/rating.php', body: <String, String>{
      'app_id': '$appId',
      'rating': '$rating',
    });
    if (!r.ok) throw ApiException(r.msg.isEmpty ? '评分失败' : r.msg);
  }

  // ==================== 收藏 / 奖励 ====================

  /// POST /api/favorite.php action=toggle 收藏/取消收藏
  Future<bool> toggleFavorite(int appId) async {
    final r = await _c.post('/api/favorite.php', body: <String, String>{
      'action': 'toggle',
      'app_id': '$appId',
    });
    if (!r.ok) throw ApiException(r.msg.isEmpty ? '操作失败' : r.msg);
    final d = r.dataMap;
    if (d != null) {
      for (final key in const ['is_favorited', 'favorited', 'favorite']) {
        if (d[key] != null) return d[key] == true || d[key] == 1 || d[key] == '1';
      }
    }
    return r.msg.contains('取消') ? false : true;
  }

  /// POST /api/favorite.php action=remove 取消收藏
  Future<void> removeFavorite(int appId) async {
    final r = await _c.post('/api/favorite.php', body: <String, String>{
      'action': 'remove',
      'app_id': '$appId',
    });
    if (!r.ok) throw ApiException(r.msg.isEmpty ? '取消收藏失败' : r.msg);
  }

  /// POST /api/favorite.php action=list 收藏列表
  Future<AppListData> favoriteList({int page = 1}) async {
    final r = await _c.post('/api/favorite.php', body: <String, String>{
      'action': 'list',
      'page': '$page',
    });
    if (!r.ok) throw ApiException(r.msg.isEmpty ? '收藏列表加载失败' : r.msg);
    return AppListData.fromJson(r.dataMap ?? <String, dynamic>{});
  }

  /// GET /api/reward.php 奖励信息
  Future<RewardInfo> rewardInfo(int appId) async {
    final r = await _c.get('/api/reward.php', params: <String, String>{'app_id': '$appId'});
    if (!r.ok) throw ApiException(r.msg.isEmpty ? '奖励信息加载失败' : r.msg);
    return RewardInfo.fromJson(r.dataMap ?? <String, dynamic>{});
  }

  /// POST /api/reward.php 领取奖励
  Future<Map<String, dynamic>> claimReward(int appId) async {
    final r = await _c.post('/api/reward.php', body: <String, String>{'app_id': '$appId'});
    if (!r.ok) throw ApiException(r.msg.isEmpty ? '领取失败' : r.msg);
    return r.dataMap ?? <String, dynamic>{};
  }

  // ==================== 下载 ====================

  /// POST /api/download.php 获取下载地址
  Future<String> getDownloadUrl({required int appId, required int btnIndex}) async {
    final r = await _c.post('/api/download.php', body: <String, String>{
      'app_id': '$appId',
      'btn_index': '$btnIndex',
    });
    if (!r.ok) throw ApiException(r.msg.isEmpty ? '获取下载地址失败' : r.msg);
    final d = r.dataMap ?? <String, dynamic>{};
    for (final key in const ['url', 'download_url', 'link', 'address', 'lanzou_url', 'file_url']) {
      final v = d[key];
      if (v != null && v.toString().isNotEmpty) return v.toString();
    }
    // 兜底：data 直接是字符串
    if (r.data is String && (r.data as String).isNotEmpty) return r.data as String;
    throw ApiException('未获取到下载地址');
  }

  /// POST /login.php 下载前建立 Web 会话
  Future<void> webLoginBeforeDownload({required String email, required String password}) async {
    final r = await _c.post('/login.php', body: <String, String>{
      'email': email,
      'password': password,
    });
    if (!r.ok) throw ApiException(r.msg.isEmpty ? 'Web 会话建立失败' : r.msg);
  }

  /// POST /profile.php Web 登录（删评论前建立会话）
  Future<void> webProfileLogin({required String email, required String password}) async {
    final r = await _c.post('/profile.php', body: <String, String>{
      'email': email,
      'password': password,
      'remember': '1',
    });
    if (!r.ok) throw ApiException(r.msg.isEmpty ? 'Web 会话建立失败' : r.msg);
  }

  /// GET /download.php Web 下载入口页（返回页面地址，供浏览器打开）
  String webDownloadEntry({required int appId, int btnIndex = 1}) =>
      '${ApiClient.baseUrl}/download.php?app_id=$appId&btn=$btnIndex';

  // ==================== 用户 ====================

  /// GET /api/user_info.php 当前登录用户
  Future<UserInfo> currentUser() async {
    final r = await _c.get('/api/user_info.php');
    if (!r.ok) throw ApiException(r.msg.isEmpty ? '用户信息加载失败' : r.msg);
    return UserInfo.fromJson(r.dataMap ?? <String, dynamic>{});
  }

  /// GET /api/user_info.php?id= 指定用户
  Future<UserInfo> userById(int id) async {
    final r = await _c.get('/api/user_info.php', params: <String, String>{'id': '$id'});
    if (!r.ok) throw ApiException(r.msg.isEmpty ? '用户信息加载失败' : r.msg);
    return UserInfo.fromJson(r.dataMap ?? <String, dynamic>{});
  }

  /// GET /api/user_profile.php 用户主页
  Future<UserProfile> userProfile(int userId, {int page = 1}) async {
    final r = await _c.get('/api/user_profile.php', params: <String, String>{
      'user_id': '$userId',
      'page': '$page',
    });
    if (!r.ok) throw ApiException(r.msg.isEmpty ? '用户主页加载失败' : r.msg);
    return UserProfile.fromJson(r.dataMap ?? <String, dynamic>{});
  }

  /// POST /api/update_profile.php 修改资料
  Future<void> updateProfile({
    String? nickname,
    String? bio,
    bool? deviceFilterEnabled,
    String? deviceFilterOs,
    String? deviceFilterOsVersion,
    String? deviceFilterArch,
  }) async {
    final body = <String, String>{};
    if (nickname != null) body['nickname'] = nickname;
    if (bio != null) body['bio'] = bio;
    if (deviceFilterEnabled != null) body['device_filter_enabled'] = deviceFilterEnabled ? '1' : '0';
    if (deviceFilterOs != null) body['device_filter_os'] = deviceFilterOs;
    if (deviceFilterOsVersion != null) body['device_filter_os_version'] = deviceFilterOsVersion;
    if (deviceFilterArch != null) body['device_filter_arch'] = deviceFilterArch;
    final r = await _c.post('/api/update_profile.php', body: body);
    if (!r.ok) throw ApiException(r.msg.isEmpty ? '资料保存失败' : r.msg);
  }

  /// POST /api/update_profile.php multipart 上传头像
  Future<void> uploadAvatar(String filePath, {String? nickname}) async {
    final fields = <String, String>{};
    if (nickname != null) fields['nickname'] = nickname;
    final r = await _c.postMultipart(
      '/api/update_profile.php',
      fields: fields,
      files: <http.MultipartFile>[await http.MultipartFile.fromPath('avatar_file', filePath, filename: 'avatar.jpg')],
    );
    if (!r.ok) throw ApiException(r.msg.isEmpty ? '头像上传失败' : r.msg);
  }

  /// POST /api/delete_account.php 注销账号
  Future<void> deleteAccount(String password) async {
    final r = await _c.post('/api/delete_account.php', body: <String, String>{
      'api_key': ApiClient.instance.apiKey ?? '',
      'password': password,
    });
    if (!r.ok) throw ApiException(r.msg.isEmpty ? '注销失败' : r.msg);
  }

  /// POST /api/send_code.php 发送邮箱验证码
  Future<void> sendCode(String email) async {
    final r = await _c.post('/api/send_code.php', body: <String, String>{'email': email});
    if (!r.ok) throw ApiException(r.msg.isEmpty ? '验证码发送失败' : r.msg);
  }

  /// POST /api/login.php 登录
  Future<Map<String, dynamic>> login(String email, String password) async {
    final r = await _c.post('/api/login.php', body: <String, String>{
      'email': email,
      'password': password,
    });
    if (!r.ok) throw ApiException(r.msg.isEmpty ? '登录失败' : r.msg);
    return r.dataMap ?? <String, dynamic>{};
  }

  /// POST /api/register.php 注册
  Future<void> register({
    required String email,
    required String password,
    required String nickname,
    required String code,
    String termsVersion = '1',
  }) async {
    final r = await _c.post('/api/register.php', body: <String, String>{
      'email': email,
      'password': password,
      'nickname': nickname,
      'code': code,
      'agree': '1',
      'terms_version': termsVersion,
    });
    if (!r.ok) throw ApiException(r.msg.isEmpty ? '注册失败' : r.msg);
  }

  /// POST /forgot.php 找回密码-发送验证码
  Future<void> forgotSendCode(String email) async {
    final r = await _c.post('/forgot.php', body: <String, String>{
      'email': email,
      'send_code': '1',
    });
    if (!r.ok) throw ApiException(r.msg.isEmpty ? '验证码发送失败' : r.msg);
  }

  /// POST /forgot.php 找回密码-重置
  Future<void> forgotReset({
    required String email,
    required String code,
    required String password,
    required String password2,
  }) async {
    final r = await _c.post('/forgot.php', body: <String, String>{
      'email': email,
      'code': code,
      'password': password,
      'password2': password2,
      'reset_password': '1',
    });
    if (!r.ok) throw ApiException(r.msg.isEmpty ? '重置失败' : r.msg);
  }

  /// GET /api/submissions.php 我的投稿
  Future<SubmissionList> mySubmissions({int page = 1}) async {
    final r = await _c.get('/api/submissions.php', params: <String, String>{'page': '$page'});
    if (!r.ok) throw ApiException(r.msg.isEmpty ? '投稿列表加载失败' : r.msg);
    return SubmissionList.fromJson(r.dataMap ?? <String, dynamic>{});
  }

  // ==================== 回复 ====================

  /// GET /replies.php 评论回复列表
  Future<ReplyList> replies({int page = 1}) async {
    final r = await _c.get('/replies.php', params: <String, String>{'page': '$page'});
    if (!r.ok) throw ApiException(r.msg.isEmpty ? '回复列表加载失败' : r.msg);
    return ReplyList.fromJson(r.dataMap ?? <String, dynamic>{});
  }

  /// GET /replies.php?delete_id= 删除一条回复
  Future<void> deleteReply(int id) async {
    final r = await _c.get('/replies.php', params: <String, String>{'delete_id': '$id'});
    if (!r.ok) throw ApiException(r.msg.isEmpty ? '删除失败' : r.msg);
  }

  /// GET /app.php?id=&delete_comment= 删除评论（Web 兼容接口）
  Future<void> deleteComment({
    required int appId,
    required int commentId,
    required String email,
    required String password,
  }) async {
    await webProfileLogin(email: email, password: password);
    final r = await _c.get('/app.php', params: <String, String>{
      'id': '$appId',
      'delete_comment': '$commentId',
    });
    if (!r.ok) throw ApiException(r.msg.isEmpty ? '删除评论失败' : r.msg);
  }

  // ==================== 消息 ====================

  /// GET /api/messages.php?action=list 私信列表
  Future<ConversationList> conversations({int page = 1}) async {
    final r = await _c.get('/api/messages.php', params: <String, String>{
      'action': 'list',
      'page': '$page',
    });
    if (!r.ok) throw ApiException(r.msg.isEmpty ? '私信列表加载失败' : r.msg);
    return ConversationList.fromJson(r.dataMap ?? <String, dynamic>{});
  }

  /// GET /api/messages.php?action=detail 私信详情
  Future<MessageThread> messageDetail({required int convId, int page = 1}) async {
    final r = await _c.get('/api/messages.php', params: <String, String>{
      'action': 'detail',
      'conv_id': '$convId',
      'page': '$page',
    });
    if (!r.ok) throw ApiException(r.msg.isEmpty ? '消息加载失败' : r.msg);
    return MessageThread.fromJson(r.dataMap ?? <String, dynamic>{}, myUserId);
  }

  /// POST /api/messages.php action=send 发送私信
  Future<void> sendMessage({required int peerId, required String content}) async {
    final r = await _c.post('/api/messages.php', body: <String, String>{
      'action': 'send',
      'peer_id': '$peerId',
      'content': content,
    });
    if (!r.ok) throw ApiException(r.msg.isEmpty ? '发送失败' : r.msg);
  }

  /// POST /api/messages.php action=block 屏蔽用户
  Future<void> blockUser(int peerId) async {
    final r = await _c.post('/api/messages.php', body: <String, String>{
      'action': 'block',
      'peer_id': '$peerId',
    });
    if (!r.ok) throw ApiException(r.msg.isEmpty ? '屏蔽失败' : r.msg);
  }

  /// POST /api/messages.php action=unblock 取消屏蔽
  Future<void> unblockUser(int peerId) async {
    final r = await _c.post('/api/messages.php', body: <String, String>{
      'action': 'unblock',
      'peer_id': '$peerId',
    });
    if (!r.ok) throw ApiException(r.msg.isEmpty ? '取消屏蔽失败' : r.msg);
  }

  /// POST /api/messages.php action=delete_conv 删除会话
  Future<void> deleteConversation(int convId) async {
    final r = await _c.post('/api/messages.php', body: <String, String>{
      'action': 'delete_conv',
      'conv_id': '$convId',
    });
    if (!r.ok) throw ApiException(r.msg.isEmpty ? '删除会话失败' : r.msg);
  }

  /// GET /api/messages.php?action=system_list 系统消息列表
  Future<SystemMessageList> systemMessages({int page = 1}) async {
    final r = await _c.get('/api/messages.php', params: <String, String>{
      'action': 'system_list',
      'page': '$page',
    });
    if (!r.ok) throw ApiException(r.msg.isEmpty ? '系统消息加载失败' : r.msg);
    return SystemMessageList.fromJson(r.dataMap ?? <String, dynamic>{});
  }

  /// POST /api/messages.php action=system_delete 删除系统消息
  Future<void> deleteSystemMessage(int msgId) async {
    final r = await _c.post('/api/messages.php',
        body: <String, String>{'action': 'system_delete', 'msg_id': '$msgId'},
        apiKeyInUrl: true);
    if (!r.ok) throw ApiException(r.msg.isEmpty ? '删除失败' : r.msg);
  }

  /// GET /api/unread_count.php 未读消息数
  Future<int> unreadCount() async {
    final r = await _c.get('/api/unread_count.php');
    if (!r.ok) return 0;
    final d = r.dataMap ?? <String, dynamic>{};
    for (final key in const ['count', 'unread', 'unread_count', 'total', 'num']) {
      final v = d[key];
      if (v is int) return v;
      if (v is String) {
        final n = int.tryParse(v);
        if (n != null) return n;
      }
    }
    if (r.data is int) return r.data as int;
    return 0;
  }

  // ==================== 商城 / 背包 / 头像框 / 设备过滤 ====================

  /// GET /api/shop.php 商店商品
  Future<List<ShopItem>> shopItems() async {
    final r = await _c.get('/api/shop.php');
    if (!r.ok) throw ApiException(r.msg.isEmpty ? '商店加载失败' : r.msg);
    return parseList(r.dataMap ?? <String, dynamic>{}).map(ShopItem.fromJson).toList();
  }

  /// POST /api/shop.php 购买商品
  Future<Map<String, dynamic>> buyItem(int itemId) async {
    final r = await _c.post('/api/shop.php', body: <String, String>{
      'item_id': '$itemId',
    });
    if (!r.ok) throw ApiException(r.msg.isEmpty ? '购买失败' : r.msg);
    return r.dataMap ?? <String, dynamic>{};
  }

  /// GET /api/backpack.php 背包物品
  Future<List<BackpackItem>> backpack() async {
    final r = await _c.get('/api/backpack.php');
    if (!r.ok) throw ApiException(r.msg.isEmpty ? '背包加载失败' : r.msg);
    return parseList(r.dataMap ?? <String, dynamic>{}).map(BackpackItem.fromJson).toList();
  }

  /// POST /api/backpack.php 使用背包物品
  Future<void> useBackpackItem(int? itemId) async {
    final body = <String, String>{'use_makeup': '1'};
    if (itemId != null) body['item_id'] = '$itemId';
    final r = await _c.post('/api/backpack.php', body: body);
    if (!r.ok) throw ApiException(r.msg.isEmpty ? '使用失败' : r.msg);
  }

  /// GET /api/user_frames.php 头像框列表
  Future<List<FrameItem>> frames() async {
    final r = await _c.get('/api/user_frames.php');
    if (!r.ok) throw ApiException(r.msg.isEmpty ? '头像框加载失败' : r.msg);
    return parseList(r.dataMap ?? <String, dynamic>{}).map(FrameItem.fromJson).toList();
  }

  /// POST /api/user_frames.php 使用头像框
  Future<void> useFrame(String frame) async {
    final r = await _c.post('/api/user_frames.php', body: <String, String>{
      'use_frame': frame,
    });
    if (!r.ok) throw ApiException(r.msg.isEmpty ? '设置失败' : r.msg);
  }

  /// POST /api/device_filter.php 设备过滤开关
  Future<void> setDeviceFilter(bool enabled) async {
    final r = await _c.post('/api/device_filter.php', body: <String, String>{
      'enabled': enabled ? '1' : '0',
    });
    if (!r.ok) throw ApiException(r.msg.isEmpty ? '设置失败' : r.msg);
  }
}
