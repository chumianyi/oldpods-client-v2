/// 数据模型层：对老豆荚服务端接口返回做防御式解析。
library;

String? _s(dynamic v) => v == null ? null : v.toString();

int _i(dynamic v, [int d = 0]) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? d;
  return d;
}

double _d(dynamic v, [double dd = 0]) {
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? dd;
  return dd;
}

bool _b(dynamic v) => v == true || v == 1 || v == '1' || v == 'true';
bool _bv(dynamic v, [bool d = false]) => v == null ? d : _b(v);

String _str(dynamic v, [String d = '']) => _s(v) ?? d;

List<Map<String, dynamic>> _mapList(dynamic v) {
  if (v is List) {
    return v.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }
  return <Map<String, dynamic>>[];
}

/// 通用分页元信息
class PageMeta {
  final int total;
  final int page;
  final int pages;
  PageMeta({this.total = 0, this.page = 1, this.pages = 1});

  factory PageMeta.fromJson(Map<String, dynamic> j) => PageMeta(
        total: _i(j['total']),
        page: _i(j['page'], 1),
        pages: _i(j['pages'], 1),
      );

  bool get hasMore => page < pages;
}

/// 从 data 中解析分页列表：兼容 list / items / data 三种键
List<Map<String, dynamic>> parseList(Map<String, dynamic> data) {
  for (final key in const ['list', 'items', 'data', 'records']) {
    if (data[key] is List) return _mapList(data[key]);
  }
  return <Map<String, dynamic>>[];
}

// ---------------- 首页 ----------------

class Banner {
  final String imageUrl;
  final String linkUrl;
  final String ratio;
  Banner({required this.imageUrl, required this.linkUrl, required this.ratio});

  factory Banner.fromJson(Map<String, dynamic> j) => Banner(
        imageUrl: _str(j['image_url']),
        linkUrl: _str(j['link_url']),
        ratio: _str(j['ratio']),
      );
}

class Quote {
  final String content;
  final String author;
  Quote({required this.content, required this.author});

  factory Quote.fromJson(Map<String, dynamic> j) => Quote(
        content: _str(j['content']),
        author: _str(j['author']),
      );
}

class Category {
  final int id;
  final String name;
  final String groupName;
  Category({required this.id, required this.name, required this.groupName});

  factory Category.fromJson(Map<String, dynamic> j) => Category(
        id: _i(j['id']),
        name: _str(j['name']),
        groupName: _str(j['group_name']),
      );
}

class HomeData {
  final List<Banner> banners;
  final Quote quote;
  final List<List<Category>> categoryGroups;
  HomeData({required this.banners, required this.quote, required this.categoryGroups});

  factory HomeData.fromJson(Map<String, dynamic> j) {
    final rawGroups = j['categories'];
    final groups = <List<Category>>[];
    if (rawGroups is List) {
      for (final g in rawGroups) {
        if (g is List) {
          groups.add(_mapList(g).map(Category.fromJson).toList());
        }
      }
    }
    return HomeData(
      banners: _mapList(j['banners']).map(Banner.fromJson).toList(),
      quote: Quote.fromJson(j['quote'] is Map ? Map<String, dynamic>.from(j['quote']) : <String, dynamic>{}),
      categoryGroups: groups,
    );
  }

  List<Category> get allCategories {
    final all = <Category>[];
    for (final g in categoryGroups) {
      all.addAll(g);
    }
    return all;
  }
}

// ---------------- 应用 ----------------

class AppItem {
  final int id;
  final String title;
  final String iconUrl;
  final String system;
  final String size;
  final String arch;
  final int downloads;
  final double ratingAvg;
  final int ratingCount;
  AppItem({
    required this.id,
    required this.title,
    required this.iconUrl,
    required this.system,
    required this.size,
    required this.arch,
    required this.downloads,
    required this.ratingAvg,
    required this.ratingCount,
  });

  factory AppItem.fromJson(Map<String, dynamic> j) => AppItem(
        id: _i(j['id']),
        title: _str(j['title'], _str(j['name'])),
        iconUrl: _str(j['icon_url'], _str(j['icon'])),
        system: _str(j['system'], _str(j['system_requirements'])),
        size: _str(j['size'], _str(j['file_size'])),
        arch: _str(j['arch'], _str(j['architecture'])),
        downloads: _i(j['downloads']),
        ratingAvg: _d(j['rating_avg']),
        ratingCount: _i(j['rating_count']),
      );
}

class AppListData {
  final List<AppItem> list;
  final PageMeta meta;
  AppListData({required this.list, required this.meta});

  factory AppListData.fromJson(Map<String, dynamic> j) => AppListData(
        list: parseList(j).map(AppItem.fromJson).toList(),
        meta: PageMeta.fromJson(j),
      );

  bool get hasMore => meta.hasMore;
}

class DownloadButton {
  final String text;
  final String type;
  final int coins;
  final bool payEveryTime;
  final String kind;
  final int seq;
  final String kindName;
  final String channel;
  final String priceTag;
  final bool isPurchased;
  final bool isUnlocked;
  final bool needPay;
  final String getUrlApi;
  DownloadButton({
    required this.text,
    required this.type,
    required this.coins,
    required this.payEveryTime,
    required this.kind,
    required this.seq,
    required this.kindName,
    required this.channel,
    required this.priceTag,
    required this.isPurchased,
    required this.isUnlocked,
    required this.needPay,
    required this.getUrlApi,
  });

  factory DownloadButton.fromJson(Map<String, dynamic> j) => DownloadButton(
        text: _str(j['text']),
        type: _str(j['type']),
        coins: _i(j['coins']),
        payEveryTime: _b(j['pay_every_time']),
        kind: _str(j['kind']),
        seq: _i(j['seq'], 1),
        kindName: _str(j['kind_name']),
        channel: _str(j['channel']),
        priceTag: _str(j['price_tag']),
        isPurchased: _b(j['is_purchased']),
        isUnlocked: _bv(j['is_unlocked'], true),
        needPay: _b(j['need_pay']),
        getUrlApi: _str(j['get_url_api']),
      );
}

class Submitter {
  final int id;
  final String nickname;
  final String avatar;
  final String frame;
  final double frameW;
  final double frameX;
  final double frameY;
  final bool isMember;
  final String memberExpire;
  final bool isMemberPermanent;
  final String memberType;
  final String verifyBadge;
  final bool isVerified;
  Submitter({
    required this.id,
    required this.nickname,
    required this.avatar,
    required this.frame,
    required this.frameW,
    required this.frameX,
    required this.frameY,
    required this.isMember,
    required this.memberExpire,
    required this.isMemberPermanent,
    required this.memberType,
    required this.verifyBadge,
    required this.isVerified,
  });

  factory Submitter.fromJson(Map<String, dynamic> j) => Submitter(
        id: _i(j['id']),
        nickname: _str(j['nickname']),
        avatar: _str(j['avatar']),
        frame: _str(j['frame'], _str(j['frame_url'])),
        frameW: _d(j['frame_w'], 100),
        frameX: _d(j['frame_x']),
        frameY: _d(j['frame_y']),
        isMember: _b(j['is_member']),
        memberExpire: _str(j['member_expire']),
        isMemberPermanent: _b(j['is_member_permanent']),
        memberType: _str(j['member_type']),
        verifyBadge: _str(j['verify_badge']),
        isVerified: _b(j['is_verified']),
      );
}

class AppDetail {
  final int id;
  final String title;
  final String iconUrl;
  final String description;
  final String systemRequirements;
  final String fileSize;
  final String architecture;
  final List<DownloadButton> downloadButtons;
  final List<String> screenshots;
  final int downloads;
  final double ratingAvg;
  final int ratingCount;
  final bool userRated;
  final int myRating;
  final bool isFavorited;
  final List<String> categories;
  final Submitter? submitter;
  final String createdAt;
  AppDetail({
    required this.id,
    required this.title,
    required this.iconUrl,
    required this.description,
    required this.systemRequirements,
    required this.fileSize,
    required this.architecture,
    required this.downloadButtons,
    required this.screenshots,
    required this.downloads,
    required this.ratingAvg,
    required this.ratingCount,
    required this.userRated,
    required this.myRating,
    required this.isFavorited,
    required this.categories,
    required this.submitter,
    required this.createdAt,
  });

  factory AppDetail.fromJson(Map<String, dynamic> j) => AppDetail(
        id: _i(j['id']),
        title: _str(j['title']),
        iconUrl: _str(j['icon_url']),
        description: _str(j['description']),
        systemRequirements: _str(j['system_requirements']),
        fileSize: _str(j['file_size']),
        architecture: _str(j['architecture']),
        downloadButtons: _mapList(j['download_buttons']).map(DownloadButton.fromJson).toList(),
        screenshots: (j['screenshots'] is List ? j['screenshots'] as List : const []).map((e) => e.toString()).toList(),
        downloads: _i(j['downloads']),
        ratingAvg: _d(j['rating_avg']),
        ratingCount: _i(j['rating_count']),
        userRated: _b(j['user_rated']),
        myRating: _i(j['my_rating']),
        isFavorited: _b(j['is_favorited']),
        categories: (j['categories'] is List ? j['categories'] as List : const []).map((e) => e.toString()).toList(),
        submitter: j['submitter'] is Map ? Submitter.fromJson(Map<String, dynamic>.from(j['submitter'])) : null,
        createdAt: _str(j['created_at']),
      );
}

// ---------------- 评论 ----------------

class Comment {
  final int id;
  final int userId;
  final String nickname;
  final String avatar;
  final String content;
  final int parentId;
  final bool deleted;
  final bool parentDeleted;
  final String createdAt;
  final String createdAtCst;
  final bool isMember;
  final String memberExpire;
  final bool isMemberPermanent;
  final String memberType;
  final String verifyBadge;
  final bool isVerified;
  final String frame;
  final double frameW;
  final double frameX;
  final double frameY;
  Comment({
    required this.id,
    required this.userId,
    required this.nickname,
    required this.avatar,
    required this.content,
    required this.parentId,
    required this.deleted,
    required this.parentDeleted,
    required this.createdAt,
    required this.createdAtCst,
    required this.isMember,
    required this.memberExpire,
    required this.isMemberPermanent,
    required this.memberType,
    required this.verifyBadge,
    required this.isVerified,
    required this.frame,
    required this.frameW,
    required this.frameX,
    required this.frameY,
  });

  factory Comment.fromJson(Map<String, dynamic> j) => Comment(
        id: _i(j['id']),
        userId: _i(j['user_id']),
        nickname: _str(j['nickname'], '用户${_i(j['user_id'])}'),
        avatar: _str(j['avatar']),
        content: _str(j['content']),
        parentId: _i(j['parent_id']),
        deleted: _b(j['deleted']),
        parentDeleted: _b(j['parent_deleted']),
        createdAt: _str(j['created_at']),
        createdAtCst: _str(j['created_at_cst']),
        isMember: _b(j['is_member']),
        memberExpire: _str(j['member_expire']),
        isMemberPermanent: _b(j['is_member_permanent']),
        memberType: _str(j['member_type']),
        verifyBadge: _str(j['verify_badge']),
        isVerified: _b(j['is_verified']),
        frame: _str(j['frame']),
        frameW: _d(j['frame_w'], 100),
        frameX: _d(j['frame_x']),
        frameY: _d(j['frame_y']),
      );


}

class CommentList {
  final List<Comment> list;
  final PageMeta meta;
  CommentList({required this.list, required this.meta});

  factory CommentList.fromJson(Map<String, dynamic> j) => CommentList(
        list: parseList(j).map(Comment.fromJson).toList(),
        meta: PageMeta.fromJson(j),
      );
}

// ---------------- 用户 ----------------

class UserItem {
  final int userId;
  final String nickname;
  final String avatar;
  final String bio;
  final bool isMember;
  final String memberExpire;
  final bool isMemberPermanent;
  final String memberType;
  final String verifyBadge;
  final bool isVerified;
  final String frame;
  final double frameW;
  final double frameX;
  final double frameY;
  UserItem({
    required this.userId,
    required this.nickname,
    required this.avatar,
    required this.bio,
    required this.isMember,
    required this.memberExpire,
    required this.isMemberPermanent,
    required this.memberType,
    required this.verifyBadge,
    required this.isVerified,
    required this.frame,
    required this.frameW,
    required this.frameX,
    required this.frameY,
  });

  factory UserItem.fromJson(Map<String, dynamic> j) => UserItem(
        userId: _i(j['user_id'], _i(j['id'])),
        nickname: _str(j['nickname']),
        avatar: _str(j['avatar']),
        bio: _str(j['bio']),
        isMember: _b(j['is_member']),
        memberExpire: _str(j['member_expire']),
        isMemberPermanent: _b(j['is_member_permanent']),
        memberType: _str(j['member_type']),
        verifyBadge: _str(j['verify_badge']),
        isVerified: _b(j['is_verified']),
        frame: _str(j['frame']),
        frameW: _d(j['frame_w'], 100),
        frameX: _d(j['frame_x']),
        frameY: _d(j['frame_y']),
      );

  String get memberLabel {
    if (isMemberPermanent) return '永久会员';
    if (isMember && memberType == 'expiring') return '会员';
    return '';
  }
}

class UserInfo {
  final int userId;
  final String nickname;
  final String avatar;
  final String bio;
  final String email;
  final int coins;
  final bool isMember;
  final String memberExpire;
  final bool isMemberPermanent;
  final String memberType;
  final String verifyBadge;
  final bool isVerified;
  final String frame;
  final double frameW;
  final double frameX;
  final double frameY;
  final Map<String, dynamic> raw;
  UserInfo({
    required this.userId,
    required this.nickname,
    required this.avatar,
    required this.bio,
    required this.email,
    required this.coins,
    required this.isMember,
    required this.memberExpire,
    required this.isMemberPermanent,
    required this.memberType,
    required this.verifyBadge,
    required this.isVerified,
    required this.frame,
    required this.frameW,
    required this.frameX,
    required this.frameY,
    required this.raw,
  });

  factory UserInfo.fromJson(Map<String, dynamic> j) => UserInfo(
        userId: _i(j['user_id'], _i(j['id'])),
        nickname: _str(j['nickname']),
        avatar: _str(j['avatar']),
        bio: _str(j['bio']),
        email: _str(j['email']),
        coins: _i(j['coins'], _i(j['coin'])),
        isMember: _b(j['is_member']),
        memberExpire: _str(j['member_expire']),
        isMemberPermanent: _b(j['is_member_permanent']),
        memberType: _str(j['member_type']),
        verifyBadge: _str(j['verify_badge']),
        isVerified: _b(j['is_verified']),
        frame: _str(j['frame']),
        frameW: _d(j['frame_w'], 100),
        frameX: _d(j['frame_x']),
        frameY: _d(j['frame_y']),
        raw: j,
      );
}

class UserProfile {
  final UserItem user;
  final SubmissionList submissions;
  UserProfile({required this.user, required this.submissions});

  factory UserProfile.fromJson(Map<String, dynamic> j) {
    final subsRaw = j['submissions'];
    final subsMap = subsRaw is Map ? Map<String, dynamic>.from(subsRaw) : <String, dynamic>{};
    return UserProfile(
      user: UserItem.fromJson(j),
      submissions: SubmissionList.fromJson(subsMap),
    );
  }
}

// ---------------- 投稿 ----------------

class SubmissionItem {
  final int id;
  final String title;
  final String iconUrl;
  final String system;
  final String size;
  final String arch;
  final String status;
  final int downloads;
  final String createdAt;
  SubmissionItem({
    required this.id,
    required this.title,
    required this.iconUrl,
    required this.system,
    required this.size,
    required this.arch,
    required this.status,
    required this.downloads,
    required this.createdAt,
  });

  factory SubmissionItem.fromJson(Map<String, dynamic> j) => SubmissionItem(
        id: _i(j['id']),
        title: _str(j['title']),
        iconUrl: _str(j['icon_url']),
        system: _str(j['system'], _str(j['system_requirements'])),
        size: _str(j['size'], _str(j['file_size'])),
        arch: _str(j['arch'], _str(j['architecture'])),
        status: _str(j['status']),
        downloads: _i(j['downloads']),
        createdAt: _str(j['created_at']),
      );

  String get statusLabel {
    switch (status) {
      case 'publish':
        return '已发布';
      case 'pending':
        return '审核中';
      case 'review':
        return '审核中';
      case 'reject':
        return '未通过';
      case 'draft':
        return '草稿';
      case 'offline':
        return '已下架';
      default:
        return status.isEmpty ? '' : status;
    }
  }
}

class SubmissionList {
  final List<SubmissionItem> list;
  final PageMeta meta;
  SubmissionList({required this.list, required this.meta});

  factory SubmissionList.fromJson(Map<String, dynamic> j) => SubmissionList(
        list: parseList(j).map(SubmissionItem.fromJson).toList(),
        meta: PageMeta.fromJson(j),
      );
}

// ---------------- 排行榜 ----------------

class LeaderboardItem {
  final String nickname;
  final String avatar;
  final int streak;
  final int score;
  final String checkinTime;
  final int rank;
  final String frame;
  final double frameW;
  final double frameX;
  final double frameY;
  LeaderboardItem({
    required this.nickname,
    required this.avatar,
    required this.streak,
    required this.score,
    this.checkinTime = '',
    required this.rank,
    required this.frame,
    required this.frameW,
    required this.frameX,
    required this.frameY,
  });

  factory LeaderboardItem.fromJson(Map<String, dynamic> j) => LeaderboardItem(
        nickname: _str(j['nickname']),
        avatar: _str(j['avatar']),
        streak: _i(j['streak'], _i(j['continuous_days'], _i(j['streak_days']))),
        score: _i(j['score'], _i(j['checkins'])),
        checkinTime: _checkinTime(j),
        rank: _i(j['rank']),
        frame: _str(j['frame']),
        frameW: _d(j['frame_w'], 100),
        frameX: _d(j['frame_x']),
        frameY: _d(j['frame_y']),
      );
  String get timeLabel => checkinTime.isEmpty ? '时间未提供' : checkinTime;

  static String _checkinTime(Map<String, dynamic> j) {
    for (final key in const ['checkin_time', 'checkin_at', 'checked_in_at',
      'checkin_time_cst', 'created_at_cst', 'check_time', 'sign_time', 'time', 'created_at']) {
      final text = _str(j[key]).trim();
      final clock = RegExp(r'(?:^|[T\s])(\d{1,2}):(\d{2})(?::(\d{2}))?(?:$|[.Z+\-\s])').firstMatch(text);
      if (clock != null) {
        final hour = int.parse(clock[1]!);
        final minute = int.parse(clock[2]!);
        final second = int.parse(clock[3] ?? '0');
        if (hour < 24 && minute < 60 && second < 60) {
          return '${hour.toString().padLeft(2, '0')}:${clock[2]}${clock[3] == null ? '' : ':${clock[3]}'}';
        }
      }
      if (RegExp(r'^\d{10}(?:\d{3})?$').hasMatch(text)) {
        final epoch = int.tryParse(text);
        if (epoch != null) {
          final dt = DateTime.fromMillisecondsSinceEpoch(text.length == 10 ? epoch * 1000 : epoch,
            isUtc: true).add(const Duration(hours: 8));
          return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
        }
      }
    }
    return '';
  }
}

// ---------------- 公告 / 协议 ----------------

class Announcement {
  final int id;
  final String title;
  final String content;
  final String createdAt;
  Announcement({required this.id, required this.title, required this.content, required this.createdAt});

  factory Announcement.fromJson(Map<String, dynamic> j) => Announcement(
        id: _i(j['id']),
        title: _str(j['title']),
        content: _str(j['content']),
        createdAt: _str(j['created_at']),
      );
}

class TermsSection {
  final String title;
  final String content;
  TermsSection({required this.title, required this.content});
}

class TermsData {
  final String version;
  final String versionLabel;
  final String title;
  final String updatedAt;
  final String intro;
  final List<TermsSection> sections;
  final String contactTitle;
  final List<TermsSection> contacts;
  final List<String> signatures;
  final String text;

  TermsData({
    required this.version,
    required this.versionLabel,
    required this.title,
    required this.updatedAt,
    required this.intro,
    required this.sections,
    required this.contactTitle,
    required this.contacts,
    required this.signatures,
    required this.text,
  });

  factory TermsData.fromJson(Map<String, dynamic> j) {
    List<TermsSection> parseSections(dynamic v) {
      final out = <TermsSection>[];
      if (v is List) {
        for (final e in v) {
          if (e is Map) {
            out.add(TermsSection(
              title: _str(e['title'], _str(e['heading'])),
              content: _str(e['content'], _str(e['body'])),
            ));
          } else if (e != null) {
            out.add(TermsSection(title: '', content: e.toString()));
          }
        }
      }
      return out;
    }

    return TermsData(
      version: _str(j['version']),
      versionLabel: _str(j['version_label']),
      title: _str(j['title']),
      updatedAt: _str(j['updated_at']),
      intro: _str(j['intro']),
      sections: parseSections(j['sections']),
      contactTitle: _str(j['contact_title']),
      contacts: parseSections(j['contact']),
      signatures: (j['signature'] is List ? j['signature'] as List : const []).map((e) => e.toString()).toList(),
      text: _str(j['text']),
    );
  }
}

// ---------------- 消息 ----------------

class Conversation {
  final int convId;
  final int peerId;
  final String nickname;
  final String avatar;
  final String lastMessage;
  final String updatedAt;
  final int unread;
  final Map<String, dynamic> raw;
  Conversation({
    required this.convId,
    required this.peerId,
    required this.nickname,
    required this.avatar,
    required this.lastMessage,
    required this.updatedAt,
    required this.unread,
    required this.raw,
  });

  factory Conversation.fromJson(Map<String, dynamic> j) => Conversation(
        convId: _i(j['conv_id'], _i(j['id'])),
        peerId: _i(j['peer_id'], _i(j['user_id'])),
        nickname: _str(j['nickname'], '用户${_i(j['peer_id'], _i(j['user_id']))}'),
        avatar: _str(j['avatar']),
        lastMessage: _str(j['last_message'], _str(j['last_content'], _str(j['preview']))),
        updatedAt: _str(j['updated_at'], _str(j['last_time'])),
        unread: _i(j['unread'], _i(j['unread_count'])),
        raw: j,
      );
}

class ConversationList {
  final List<Conversation> list;
  final PageMeta meta;
  ConversationList({required this.list, required this.meta});

  factory ConversationList.fromJson(Map<String, dynamic> j) => ConversationList(
        list: parseList(j).map(Conversation.fromJson).toList(),
        meta: PageMeta.fromJson(j),
      );
}

class MessageItem {
  final int id;
  final int senderId;
  final String content;
  final String createdAt;
  final bool isMine;
  MessageItem({required this.id, required this.senderId, required this.content, required this.createdAt, required this.isMine});

  factory MessageItem.fromJson(Map<String, dynamic> j, int myUserId) => MessageItem(
        id: _i(j['id']),
        senderId: _i(j['sender_id'], _i(j['from_id'])),
        content: _str(j['content']),
        createdAt: _str(j['created_at']),
        isMine: _b(j['is_mine']) || (_i(j['sender_id'], _i(j['from_id'])) == myUserId && myUserId > 0),
      );
}

class MessageThread {
  final List<MessageItem> list;
  final PageMeta meta;
  MessageThread({required this.list, required this.meta});

  factory MessageThread.fromJson(Map<String, dynamic> j, int myUserId) => MessageThread(
        list: parseList(j).map((e) => MessageItem.fromJson(e, myUserId)).toList(),
        meta: PageMeta.fromJson(j),
      );
}

class SystemMessage {
  final int id;
  final String title;
  final String content;
  final String createdAt;
  final bool isRead;
  final Map<String, dynamic> raw;
  SystemMessage({required this.id, required this.title, required this.content, required this.createdAt, required this.isRead, required this.raw});

  factory SystemMessage.fromJson(Map<String, dynamic> j) => SystemMessage(
        id: _i(j['id']),
        title: _str(j['title']),
        content: _str(j['content']),
        createdAt: _str(j['created_at']),
        isRead: _b(j['is_read']),
        raw: j,
      );
}

class SystemMessageList {
  final List<SystemMessage> list;
  final PageMeta meta;
  SystemMessageList({required this.list, required this.meta});

  factory SystemMessageList.fromJson(Map<String, dynamic> j) => SystemMessageList(
        list: parseList(j).map(SystemMessage.fromJson).toList(),
        meta: PageMeta.fromJson(j),
      );
}

// ---------------- 商城 / 背包 / 头像框 ----------------

class ShopItem {
  final int id;
  final String name;
  final String description;
  final int price;
  final String icon;
  final String type;
  final Map<String, dynamic> raw;
  ShopItem({required this.id, required this.name, required this.description, required this.price, required this.icon, required this.type, required this.raw});

  factory ShopItem.fromJson(Map<String, dynamic> j) => ShopItem(
        id: _i(j['id']),
        name: _str(j['name'], _str(j['title'])),
        description: _str(j['description'], _str(j['desc'])),
        price: _i(j['price'], _i(j['coins'])),
        icon: _str(j['icon'], _str(j['icon_url'], _str(j['image']))),
        type: _str(j['type']),
        raw: j,
      );
}

class BackpackItem {
  final int id;
  final String name;
  final int count;
  final String icon;
  final String type;
  final Map<String, dynamic> raw;
  BackpackItem({required this.id, required this.name, required this.count, required this.icon, required this.type, required this.raw});

  factory BackpackItem.fromJson(Map<String, dynamic> j) => BackpackItem(
        id: _i(j['id']),
        name: _str(j['name'], _str(j['title'])),
        count: _i(j['count'], 1),
        icon: _str(j['icon'], _str(j['icon_url'], _str(j['image']))),
        type: _str(j['type']),
        raw: j,
      );
}

class FrameItem {
  final int id;
  final String name;
  final String image;
  final double frameW;
  final double frameX;
  final double frameY;
  final Map<String, dynamic> raw;
  FrameItem({required this.id, required this.name, required this.image, required this.frameW, required this.frameX, required this.frameY, required this.raw});

  factory FrameItem.fromJson(Map<String, dynamic> j) => FrameItem(
        id: _i(j['id']),
        name: _str(j['name'], _str(j['title'])),
        image: _str(j['image'], _str(j['frame_url'], _str(j['url']))),
        frameW: _d(j['frame_w'], 100),
        frameX: _d(j['frame_x']),
        frameY: _d(j['frame_y']),
        raw: j,
      );
}

// ---------------- 奖励 / 回复 / 更新 ----------------

class RewardInfo {
  final int coins;
  final bool claimed;
  final bool canClaim;
  final Map<String, dynamic> raw;
  RewardInfo({required this.coins, required this.claimed, required this.canClaim, required this.raw});

  factory RewardInfo.fromJson(Map<String, dynamic> j) => RewardInfo(
        coins: _i(j['coins'], _i(j['reward'])),
        claimed: _bv(j['claimed'], _b(j['is_claimed'])),
        canClaim: _bv(j['can_claim'], !_bv(j['claimed'], _b(j['is_claimed']))),
        raw: j,
      );
}

class ReplyItem {
  final int id;
  final int appId;
  final String appTitle;
  final String content;
  final String createdAt;
  final Map<String, dynamic> raw;
  ReplyItem({required this.id, required this.appId, required this.appTitle, required this.content, required this.createdAt, required this.raw});

  factory ReplyItem.fromJson(Map<String, dynamic> j) => ReplyItem(
        id: _i(j['id']),
        appId: _i(j['app_id']),
        appTitle: _str(j['app_title'], _str(j['title'])),
        content: _str(j['content']),
        createdAt: _str(j['created_at']),
        raw: j,
      );
}

class ReplyList {
  final List<ReplyItem> list;
  final PageMeta meta;
  ReplyList({required this.list, required this.meta});

  factory ReplyList.fromJson(Map<String, dynamic> j) => ReplyList(
        list: parseList(j).map(ReplyItem.fromJson).toList(),
        meta: PageMeta.fromJson(j),
      );
}

class CheckUpdate {
  final String version;
  final int versionCode;
  final bool needUpdate;
  final bool forceUpdate;
  final int minSdk;
  final String updateTitle;
  final List<String> updateLog;
  final String downloadUrl;
  CheckUpdate({
    required this.version,
    required this.versionCode,
    required this.needUpdate,
    required this.forceUpdate,
    required this.minSdk,
    required this.updateTitle,
    required this.updateLog,
    required this.downloadUrl,
  });

  factory CheckUpdate.fromJson(Map<String, dynamic> j) => CheckUpdate(
        version: _str(j['version']),
        versionCode: _i(j['version_code']),
        needUpdate: _b(j['need_update']),
        forceUpdate: _b(j['force_update']),
        minSdk: _i(j['min_sdk'], 1),
        updateTitle: _str(j['update_title'], '发现新版本'),
        updateLog: (j['update_log'] is List ? j['update_log'] as List : const []).map((e) => e.toString()).toList(),
        downloadUrl: _str(j['download_url']),
      );
}
