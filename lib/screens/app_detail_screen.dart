import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/api_client.dart';
import '../services/api_service.dart';
import '../services/download_manager.dart';
import '../services/lanzou.dart';
import '../services/lanzou_link.dart';
import '../state/app_state.dart';
import '../theme/neu_theme.dart';
import '../widgets/common.dart';
import '../widgets/neu.dart';

class AppDetailScreen extends StatefulWidget {
  final int appId;
  const AppDetailScreen({super.key, required this.appId});

  @override
  State<AppDetailScreen> createState() => _AppDetailScreenState();
}

class _AppDetailScreenState extends State<AppDetailScreen> with SingleTickerProviderStateMixin {
  final ApiService _api = ApiService.instance;

  AppDetail? _detail;
  CommentList? _comments;
  bool _loading = true;
  bool _commentsLoading = true;
  String? _error;
  bool _descExpanded = false;
  bool _submittingComment = false;
  bool _openingDownload = false;
  String? _openingButton;
  final Map<String, DownloadLinkData> _authorizedLinks = <String, DownloadLinkData>{};
  final Map<String, int> _buttonTasks = <String, int>{};
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
    _loadComments();
    DownloadManager.instance.addListener(_onDownloadChanged);
  }

  @override
  void dispose() {
    DownloadManager.instance.removeListener(_onDownloadChanged);
    _commentController.dispose();
    super.dispose();
  }

  void _onDownloadChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final detail = await _api.appDetail(widget.appId);
      if (!mounted) return;
      setState(() {
        _detail = detail;
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

  Future<void> _loadComments() async {
    setState(() => _commentsLoading = true);
    try {
      final list = await _api.comments(appId: widget.appId, page: 1, perPage: 50);
      if (!mounted) return;
      setState(() {
        _comments = list;
        _commentsLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _commentsLoading = false);
    }
  }

  Future<void> _toggleFavorite() async {
    if (!AppState.instance.loggedIn) {
      _promptLogin();
      return;
    }
    try {
      await _api.toggleFavorite(widget.appId);
      if (!mounted) return;
      showToast(context, '操作成功');
      _load();
    } on ApiException catch (e) {
      if (mounted) showToast(context, e.message);
    }
  }

  Future<void> _showRateDialog() async {
    if (!AppState.instance.loggedIn) {
      _promptLogin();
      return;
    }
    final p = NeuPalette.of(context);
    int rating = _detail?.myRating ?? 5;
    final result = await showDialog<int>(
      context: context,
      builder: (BuildContext ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return AlertDialog(
              title: Text('为应用评分', style: TextStyle(color: p.text, fontWeight: FontWeight.w300)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  StarRating(
                    value: rating.toDouble(),
                    size: 36,
                    onTap: (int v) => setDialogState(() => rating = v),
                  ),
                  const SizedBox(height: 8),
                  Text('$rating 分', style: TextStyle(color: p.accent, fontSize: 15, fontWeight: FontWeight.w300)),
                ],
              ),
              actions: <Widget>[
                TextButton(onPressed: () => Navigator.pop(ctx), child: Text('取消', style: TextStyle(color: p.subText))),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, rating),
                  child: Text('提交', style: TextStyle(color: p.accent, fontWeight: FontWeight.w300)),
                ),
              ],
            );
          },
        );
      },
    );
    if (result == null || result <= 0) return;
    try {
      await _api.rateApp(appId: widget.appId, rating: result);
      if (!mounted) return;
      showToast(context, '评分成功');
      _load();
    } on ApiException catch (e) {
      if (mounted) showToast(context, e.message);
    }
  }

  void _promptLogin() {
    showToast(context, '请先登录');
    Navigator.pushNamed(context, '/login');
  }

  Future<void> _postComment() async {
    if (!AppState.instance.loggedIn) {
      _promptLogin();
      return;
    }
    final content = _commentController.text.trim();
    if (content.isEmpty) {
      showToast(context, '请输入评论内容');
      return;
    }
    setState(() => _submittingComment = true);
    try {
      await _api.postComment(appId: widget.appId, content: content);
      if (!mounted) return;
      _commentController.clear();
      showToast(context, '评论已发布');
      _loadComments();
    } on ApiException catch (e) {
      if (mounted) showToast(context, e.message);
    } finally {
      if (mounted) setState(() => _submittingComment = false);
    }
  }

  Future<void> _deleteComment(Comment comment) async {
    if (comment.userId != AppState.instance.userId) return;
    final p = NeuPalette.of(context);
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final go = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: Text('删除评论', style: TextStyle(color: p.text, fontWeight: FontWeight.w300)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text('删除评论需要验证账号密码（建立 Web 会话）', style: TextStyle(color: p.subText, fontSize: 12.5)),
              const SizedBox(height: 12),
              NeuTextField(
                controller: emailController,
                hint: '邮箱',
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 10),
              NeuTextField(
                controller: passwordController,
                hint: '密码',
                prefixIcon: Icons.lock_outline,
                obscure: true,
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('取消', style: TextStyle(color: p.subText))),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('删除', style: TextStyle(color: p.danger, fontWeight: FontWeight.w300))),
          ],
        );
      },
    );
    final email = emailController.text.trim();
    final password = passwordController.text;
    emailController.dispose();
    passwordController.dispose();
    if (!mounted) return;
    if (go != true || email.isEmpty || password.isEmpty) return;
    try {
      await _api.deleteComment(appId: widget.appId, commentId: comment.id, email: email, password: password);
      if (!mounted) return;
      showToast(context, '评论已删除');
      _loadComments();
      _load();
    } on ApiException catch (e) {
      if (mounted) showToast(context, e.message);
    }
  }

  bool _isLanzou(DownloadButton button) =>
      '${button.text} ${button.kind} ${button.kindName} ${button.channel} ${button.type}'.toLowerCase().contains('lanz') ||
      '${button.text} ${button.kindName}'.contains('蓝奏');

  Future<void> _download(DownloadButton button, {bool backup = false, bool original = false}) async {
    if (_openingDownload) return;
    if (!AppState.instance.loggedIn) {
      _promptLogin();
      return;
    }
    final identity = button.identity;
    setState(() { _openingDownload = true; _openingButton = identity; });
    try {
      if (button.coins > 0 && (button.payEveryTime || (button.needPay && !button.isUnlocked))) {
        final go = await confirmDialog(
          context,
          title: '付费下载',
          content: '该下载项需要 ${button.coins} 硬币，确定继续？',
        );
        if (!go) return;
      }
      if (!mounted) return;
      final cached = button.payEveryTime ? null : _authorizedLinks[identity];
      final data = cached ?? await _api.getDownloadLink(appId: widget.appId, btnIndex: button.seq, button: button);
      if (!mounted) return;
      if (!button.payEveryTime) _authorizedLinks[identity] = data;
      var url = data.url.replaceAll('&amp;', '&').trim();
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        url = Uri.parse(ApiClient.baseUrl).resolve(url).toString();
      }
      final target = Uri.tryParse(url);
      if (target == null || !['http', 'https'].contains(target.scheme) || target.host.isEmpty || target.userInfo.isNotEmpty) {
        throw const FormatException('该线路没有返回可打开的 HTTP(S) 地址');
      }
      if (LanzouResolver.isLanzouUrl(url)) {
        final link = LanzouLink.parse(url, password: data.password);
        if (!mounted) return;
        if (backup) {
          final controller = TextEditingController(text: link.password);
          final code = await showDialog<String>(context: context, builder: (ctx) => AlertDialog(
            title: const Text('备用解析'),
            content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
              const Text('将分享链接和可选提取码交给制作者的备用服务处理。此服务使用 HTTP，请仅用于公开分享文件。'),
              const SizedBox(height: 16),
              TextField(controller: controller, decoration: const InputDecoration(labelText: '提取码（可不填）', hintText: '无密码直接继续')),
            ])),
            actions: <Widget>[
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
              TextButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: const Text('继续解析')),
            ],
          ));
          controller.dispose();
          if (code == null || !mounted) return;
          url = LanzouLink(link.url, code).backupUrl.toString();
        } else if (original) {
          url = link.url.toString();
        } else {
          final direct = await LanzouResolver.instance.resolve(link.url.toString(), password: link.password);
          if (!mounted) return;
          if (direct == null) showToast(context, '主解析未完成，已打开原分享页，也可返回选择备用解析');
          url = direct ?? link.url.toString();
        }
      } else if (backup) {
        throw const FormatException('该线路返回的不是蓝奏分享链接，请使用主下载按钮打开有效地址');
      }
      if (!mounted) return;
      final task = await DownloadManager.instance.browse(
        appId: widget.appId, appTitle: _detail?.title ?? '应用',
        url: url,
        dark: Theme.of(context).brightness == Brightness.dark,
      );
      if (!mounted || task == null) return;
      setState(() { _buttonTasks[identity] = task.nativeId; });
      showToast(context, '已添加到下载列表');
      _showDownloadSheet();
    } catch (e) {
      if (mounted) showToast(context, '下载未开始：$e');
    } finally {
      if (mounted) setState(() { _openingDownload = false; _openingButton = null; });
    }
  }

  void _showDownloadSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext ctx) {
        return _DownloadSheet(appId: widget.appId, title: _detail?.title ?? '应用');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = NeuPalette.of(context);
    return Scaffold(
      appBar: NeuAppBar(
        title: _detail?.title ?? '应用详情',
        leading: NeuIconButton(icon: Icons.arrow_back, size: 40, onPressed: () => Navigator.pop(context)),
        actions: <Widget>[
          if (_detail != null)
            NeuIconButton(
              icon: _detail!.isFavorited ? Icons.star : Icons.star_border,
              iconColor: _detail!.isFavorited ? p.warning : null,
              size: 40,
              tooltip: '收藏',
              onPressed: _toggleFavorite,
            ),
          const SizedBox(width: 4),
          NeuIconButton(
            icon: Icons.download_outlined,
            size: 40,
            tooltip: '下载管理',
            onPressed: () => Navigator.pushNamed(context, '/downloads'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _loading
          ? const LoadingView(message: '正在加载详情…')
          : (_error != null
              ? ErrorView(message: _error!, onRetry: _load)
              : _buildDetail(p)),
    );
  }

  Widget _buildDetail(NeuPalette p) {
    final d = _detail!;
    return RefreshIndicator(
      color: p.accent,
      backgroundColor: p.surface,
      onRefresh: () async {
        await _load();
        await _loadComments();
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: <Widget>[
          _buildHeaderCard(p, d),
          const SizedBox(height: 14),
          _buildActionRow(p, d),
          const SizedBox(height: 14),
          if (d.screenshots.isNotEmpty) ...<Widget>[
            SectionHeader(title: '截图'),
            _buildScreenshots(p, d),
            const SizedBox(height: 14),
          ],
          _buildInfoCard(p, d),
          const SizedBox(height: 14),
          _buildDownloadCard(p, d),
          const SizedBox(height: 14),
          _buildDescriptionCard(p, d),
          const SizedBox(height: 18),
          SectionHeader(title: '评论（${_comments?.meta.total ?? 0}）'),
          _buildCommentInput(p),
          const SizedBox(height: 10),
          _buildComments(p),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(NeuPalette p, AppDetail d) {
    return NeuBox(
      radius: 22,
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          NetworkImageBox(url: d.iconUrl, width: 72, height: 72, radius: 20, fallbackIcon: Icons.android),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(d.title, style: TextStyle(color: p.text, fontSize: 17, fontWeight: FontWeight.w300)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 5,
                  children: <Widget>[
                    ...d.categories.map((String c) => MetaTag(text: c, color: p.accent)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: <Widget>[
                    StarRating(value: d.ratingAvg, size: 14),
                    const SizedBox(width: 5),
                    Text('${d.ratingAvg.toStringAsFixed(1)}（${d.ratingCount} 人评分）', style: TextStyle(color: p.subText, fontSize: 11.5)),
                  ],
                ),
                const SizedBox(height: 6),
                Text('${d.downloads} 次下载', style: TextStyle(color: p.subText, fontSize: 11.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionRow(NeuPalette p, AppDetail d) {
    return Row(
      children: <Widget>[
        Expanded(
          child: NeuButton(
            text: d.isFavorited ? '已收藏' : '收藏',
            icon: d.isFavorited ? Icons.star : Icons.star_border,
            compact: true,
            color: d.isFavorited ? p.accentSoft : null,
            onPressed: _toggleFavorite,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: NeuButton(
            text: '评分',
            icon: Icons.star_half,
            compact: true,
            onPressed: _showRateDialog,
          ),
        ),
      ],
    );
  }

  Widget _buildScreenshots(NeuPalette p, AppDetail d) {
    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: d.screenshots.length,
        itemBuilder: (BuildContext context, int i) {
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: () => _openScreenshot(d.screenshots, i),
              child: NetworkImageBox(url: d.screenshots[i], width: 300, height: 180, radius: 16),
            ),
          );
        },
      ),
    );
  }

  void _openScreenshot(List<String> urls, int initial) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (BuildContext ctx) => _ScreenshotViewer(urls: urls, initial: initial),
      ),
    );
  }

  Widget _buildInfoCard(NeuPalette p, AppDetail d) {
    return NeuBox(
      radius: 22,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('应用信息', style: TextStyle(color: p.text, fontSize: 15, fontWeight: FontWeight.w300)),
          const SizedBox(height: 8),
          InfoRow(label: '系统要求', value: d.systemRequirements),
          InfoRow(label: '文件大小', value: d.fileSize),
          InfoRow(label: '架构', value: d.architecture),
          InfoRow(label: '下载次数', value: '${d.downloads}'),
          if (d.createdAt.isNotEmpty) InfoRow(label: '发布时间', value: d.createdAt),
          if (d.submitter != null) ...<Widget>[
            const Divider(height: 20),
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/profile', arguments: <String, dynamic>{'userId': d.submitter!.id}),
              child: Row(
                children: <Widget>[
                  AvatarFrame(
                    avatar: d.submitter!.avatar,
                    frame: d.submitter!.frame,
                    frameW: d.submitter!.frameW,
                    frameX: d.submitter!.frameX,
                    frameY: d.submitter!.frameY,
                    size: 36,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Text(d.submitter!.nickname, style: TextStyle(color: p.text, fontSize: 13.5, fontWeight: FontWeight.w300)),
                            if (d.submitter!.isVerified) ...<Widget>[
                              const SizedBox(width: 4),
                              Icon(Icons.verified, size: 13, color: p.accent),
                            ],
                          ],
                        ),
                        if (d.submitter!.verifyBadge.isNotEmpty)
                          Text(d.submitter!.verifyBadge, style: TextStyle(color: p.subText, fontSize: 11)),
                      ],
                    ),
                  ),
                  Text('主页', style: TextStyle(color: p.accent, fontSize: 12)),
                  Icon(Icons.chevron_right, size: 16, color: p.accent),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDownloadCard(NeuPalette p, AppDetail d) {
    return NeuBox(
      radius: 22,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('获取应用', style: TextStyle(color: p.text, fontSize: 18, fontWeight: FontWeight.w300)),
          const SizedBox(height: 6),
          Text('选择下载线路 · 确认文件后进入后台队列', style: TextStyle(color: p.subText, fontSize: 12, height: 1.5)),
          const SizedBox(height: 12),
          if (d.downloadButtons.isEmpty)
            Text('该应用暂无可下载项', style: TextStyle(color: p.subText, fontSize: 13))
          else
            ...d.downloadButtons.map((DownloadButton b) {
              DownloadTask? selectedTask;
              final nativeId = _buttonTasks[b.identity];
              if (nativeId != null) {
                for (final candidate in DownloadManager.instance.tasks) {
                  if (candidate.nativeId == nativeId) { selectedTask = candidate; break; }
                }
              }
              final task = selectedTask;
              final active = task != null && task.isActive;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    NeuButton(
                      text: b.text,
                      icon: Icons.download,
                      width: double.infinity,
                      primary: true,
                      loading: _openingDownload && _openingButton == b.identity,
                      onPressed: _openingDownload ? null : () => _download(b),
                    ),
                    if (_isLanzou(b)) ...<Widget>[
                      const SizedBox(height: 8),
                      Row(children: <Widget>[
                        Expanded(child: NeuButton(text: '备用解析', icon: Icons.alt_route, compact: true,
                          onPressed: _openingDownload ? null : () => _download(b, backup: true))),
                        const SizedBox(width: 8),
                        Expanded(child: NeuButton(text: '原分享页', icon: Icons.link, compact: true,
                          onPressed: _openingDownload ? null : () => _download(b, original: true))),
                      ]),
                    ],
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: <Widget>[
                        MetaTag(text: b.kindName.isEmpty ? b.kind : b.kindName),
                        if (b.coins > 0) ...<Widget>[
                          MetaTag(text: '${b.coins} 硬币', color: p.warning),
                        ],
                        if (!b.isUnlocked) ...<Widget>[
                          MetaTag(text: '未解锁', color: p.danger),
                        ],
                      ],
                    ),
                    if (active) ...<Widget>[
                      const SizedBox(height: 8),
                      NeuProgress(value: task!.progress, height: 10),
                      const SizedBox(height: 4),
                      Text(
                        task!.status == DownloadStatus.resolving
                            ? '正在解析下载链接…'
                            : '${(task.progress * 100).toStringAsFixed(0)}%  ${_formatBytes(task.received)} / ${_formatBytes(task.total)}',
                        style: TextStyle(color: p.subText, fontSize: 11.5),
                      ),
                    ],
                    if (task != null && task.status == DownloadStatus.completed) ...<Widget>[
                      const SizedBox(height: 8),
                      NeuButton(
                        text: '安装',
                        icon: Icons.install_mobile,
                        compact: true,
                        onPressed: () => DownloadManager.instance.open(task),
                      ),
                    ],
                    if (task != null && task.status == DownloadStatus.failed) ...<Widget>[
                      const SizedBox(height: 6),
                      Text(task.error ?? '下载失败', style: TextStyle(color: p.danger, fontSize: 11.5)),
                    ],
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0B';
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}K';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / 1024 / 1024).toStringAsFixed(1)}M';
    return '${(bytes / 1024 / 1024 / 1024).toStringAsFixed(2)}G';
  }

  Widget _buildDescriptionCard(NeuPalette p, AppDetail d) {
    final text = d.description.trim();
    return NeuBox(
      radius: 22,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text('应用简介', style: TextStyle(color: p.text, fontSize: 15, fontWeight: FontWeight.w300)),
              ),
              GestureDetector(
                onTap: () => setState(() => _descExpanded = !_descExpanded),
                child: Text(
                  _descExpanded ? '收起' : '展开',
                  style: TextStyle(color: p.accent, fontSize: 12.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            crossFadeState: _descExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            firstChild: Text(
              text,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: p.subText, fontSize: 13, height: 1.6),
            ),
            secondChild: SelectableText(
              text,
              style: TextStyle(color: p.subText, fontSize: 13, height: 1.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentInput(NeuPalette p) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        Expanded(
          child: NeuTextField(
            controller: _commentController,
            hint: '说点什么吧…',
            maxLines: 3,
          ),
        ),
        const SizedBox(width: 10),
        NeuButton(
          text: '发布',
          compact: true,
          loading: _submittingComment,
          onPressed: _postComment,
        ),
      ],
    );
  }

  Widget _buildComments(NeuPalette p) {
    if (_commentsLoading && _comments == null) {
      return const Padding(padding: EdgeInsets.all(24), child: LoadingView());
    }
    final list = _comments?.list ?? <Comment>[];
    if (list.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: EmptyView(message: '还没有评论，来抢沙发', icon: Icons.chat_bubble_outline),
      );
    }
    // 父评论 + 子回复分组
    final parents = list.where((Comment c) => c.parentId == 0).toList();
    final children = <int, List<Comment>>{};
    for (final c in list) {
      if (c.parentId != 0) {
        children.putIfAbsent(c.parentId, () => <Comment>[]).add(c);
      }
    }
    return Column(
      children: <Widget>[
        ...parents.map((Comment c) {
          return _CommentItem(
            comment: c,
            replies: children[c.id] ?? <Comment>[],
            onDelete: () => _deleteComment(c),
            onTapUser: () => Navigator.pushNamed(context, '/profile', arguments: <String, dynamic>{'userId': c.userId}),
          );
        }),
        // 孤立回复（父评论被删或不在本页）
        ...list.where((Comment c) => c.parentId != 0 && !parents.any((Comment p2) => p2.id == c.parentId)).map((Comment c) {
          return _CommentItem(
            comment: c,
            replies: const <Comment>[],
            onDelete: () => _deleteComment(c),
            onTapUser: () => Navigator.pushNamed(context, '/profile', arguments: <String, dynamic>{'userId': c.userId}),
          );
        }),
      ],
    );
  }
}

class _CommentItem extends StatelessWidget {
  final Comment comment;
  final List<Comment> replies;
  final VoidCallback onDelete;
  final VoidCallback onTapUser;

  const _CommentItem({required this.comment, required this.replies, required this.onDelete, required this.onTapUser});

  @override
  Widget build(BuildContext context) {
    final p = NeuPalette.of(context);
    final myUserId = AppState.instance.userId;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          GestureDetector(
            onTap: onTapUser,
            child: AvatarFrame(
              avatar: comment.avatar,
              frame: comment.frame,
              frameW: comment.frameW,
              frameX: comment.frameX,
              frameY: comment.frameY,
              size: 38,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    GestureDetector(
                      onTap: onTapUser,
                      child: Text(
                        comment.deleted ? '已删除' : comment.nickname,
                        style: TextStyle(
                          color: comment.deleted ? p.subText : p.text,
                          fontSize: 13,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ),
                    if (comment.isVerified && !comment.deleted) ...<Widget>[
                      const SizedBox(width: 3),
                      Icon(Icons.verified, size: 12, color: p.accent),
                    ],
                    if (comment.isMember && !comment.deleted) ...<Widget>[
                      const SizedBox(width: 5),
                      MetaTag(text: comment.isMemberPermanent ? '永久会员' : '会员', color: p.warning),
                    ],
                    const Spacer(),
                    if (comment.userId == myUserId && myUserId > 0 && !comment.deleted)
                      GestureDetector(
                        onTap: onDelete,
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(Icons.delete_outline, size: 15, color: p.subText),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                if (comment.deleted)
                  Text('该评论已删除', style: TextStyle(color: p.subText, fontSize: 13, fontStyle: FontStyle.italic))
                else
                  Text(
                    comment.content,
                    style: TextStyle(color: p.text, fontSize: 13.5, height: 1.45),
                  ),
                const SizedBox(height: 3),
                Text(
                  comment.createdAtCst.isNotEmpty ? comment.createdAtCst : comment.createdAt,
                  style: TextStyle(color: p.subText, fontSize: 11),
                ),
                if (replies.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
                    decoration: BoxDecoration(
                      color: p.surfaceAlt,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: replies.map((Comment r) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              AvatarFrame(
                                avatar: r.avatar,
                                frame: r.frame,
                                frameW: r.frameW,
                                frameX: r.frameX,
                                frameY: r.frameY,
                                size: 26,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      r.deleted ? '已删除' : r.nickname,
                                      style: TextStyle(color: p.text, fontSize: 12, fontWeight: FontWeight.w300),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      r.deleted ? '该回复已删除' : r.content,
                                      style: TextStyle(color: p.subText, fontSize: 12.5, height: 1.4),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScreenshotViewer extends StatefulWidget {
  final List<String> urls;
  final int initial;
  const _ScreenshotViewer({required this.urls, required this.initial});

  @override
  State<_ScreenshotViewer> createState() => _ScreenshotViewerState();
}

class _ScreenshotViewerState extends State<_ScreenshotViewer> {
  late final PageController _controller = PageController(initialPage: widget.initial);
  late int _index = widget.initial;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = NeuPalette.of(context);
    return Scaffold(
      backgroundColor: Colors.black87,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('${_index + 1} / ${widget.urls.length}', style: const TextStyle(color: Colors.white, fontSize: 15)),
        leading: NeuIconButton(
          icon: Icons.close,
          size: 40,
          color: Colors.white24,
          iconColor: Colors.white,
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: PageView.builder(
        controller: _controller,
        itemCount: widget.urls.length,
        onPageChanged: (int i) => setState(() => _index = i),
        itemBuilder: (BuildContext context, int i) {
          return InteractiveViewer(
            minScale: 0.5,
            maxScale: 4,
            child: Center(
              child: Image.network(
                widget.urls[i],
                errorBuilder: (BuildContext c, Object e, StackTrace? s) => Icon(Icons.broken_image, color: p.subText, size: 48),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DownloadSheet extends StatelessWidget {
  final int appId;
  final String title;
  const _DownloadSheet({required this.appId, required this.title});

  @override
  Widget build(BuildContext context) {
    final p = NeuPalette.of(context);
    return Container(
      decoration: BoxDecoration(color: p.surface, borderRadius: BorderRadius.circular(24)),
      padding: const EdgeInsets.all(20),
      child: SafeArea(
        top: false,
        child: AnimatedBuilder(
          animation: DownloadManager.instance,
          builder: (BuildContext context, Widget? _) {
            final task = DownloadManager.instance.taskOf(appId);
            if (task == null) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text('下载已取消', style: TextStyle(color: p.subText)),
                ],
              );
            }
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: p.text, fontSize: 15, fontWeight: FontWeight.w300))),
                    NeuIconButton(
                      icon: Icons.close,
                      size: 36,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                NeuProgress(value: task!.progress, height: 12),
                const SizedBox(height: 10),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        _statusText(task),
                        style: TextStyle(color: p.subText, fontSize: 12.5),
                      ),
                    ),
                    if (task.isActive)
                      NeuButton(
                        text: '取消',
                        danger: true,
                        compact: true,
                        onPressed: () {
                          DownloadManager.instance.cancel(appId);
                          Navigator.pop(context);
                        },
                      ),
                    if (task.status == DownloadStatus.completed) ...<Widget>[
                      NeuButton(
                        text: '安装',
                        icon: Icons.install_mobile,
                        compact: true,
                        primary: true,
                        onPressed: () => DownloadManager.instance.open(task),
                      ),
                      const SizedBox(width: 8),
                      NeuButton(
                        text: '后台下载',
                        compact: true,
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                    if (task.status == DownloadStatus.failed) ...<Widget>[
                      NeuButton(
                        text: '重试',
                        compact: true,
                        onPressed: () {
                          Navigator.pop(context);
                          DownloadManager.instance.browse(appId: appId, appTitle: title, url: task.sourceUrl);
                        },
                      ),
                    ],
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _statusText(DownloadTask task) {
    switch (task.status) {
      case DownloadStatus.resolving:
        return '正在解析下载链接…';
      case DownloadStatus.downloading:
        return '${(task.progress * 100).toStringAsFixed(0)}%';
      case DownloadStatus.completed:
        return '下载完成，可安装';
      case DownloadStatus.failed:
        return task.error ?? '下载失败';
      default:
        return '准备中…';
    }
  }
}
