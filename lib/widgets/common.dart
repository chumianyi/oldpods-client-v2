import 'package:flutter/material.dart';

import '../theme/neu_theme.dart';
import 'neu.dart';

/// 轻提示
void showToast(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message, style: const TextStyle(color: Colors.white))),
  );
}

/// 确认对话框
Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  String? content,
  String confirmText = '确认',
  String cancelText = '取消',
  bool danger = false,
}) async {
  final p = NeuPalette.of(context);
  final result = await showDialog<bool>(
    context: context,
    builder: (BuildContext ctx) => AlertDialog(
      title: Text(title, style: TextStyle(color: p.text, fontWeight: FontWeight.w300)),
      content: content == null ? null : Text(content, style: TextStyle(color: p.subText, fontSize: 14)),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(cancelText, style: TextStyle(color: p.subText)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(
            confirmText,
            style: TextStyle(color: danger ? p.danger : p.accent, fontWeight: FontWeight.w300),
          ),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// 加载中
class LoadingView extends StatelessWidget {
  final String? message;
  const LoadingView({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    final p = NeuPalette.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SizedBox(
            width: 42,
            height: 42,
            child: CircularProgressIndicator(strokeWidth: 3, color: p.accent),
          ),
          if (message != null) ...<Widget>[
            const SizedBox(height: 14),
            Text(message!, style: TextStyle(color: p.subText, fontSize: 13)),
          ],
        ],
      ),
    );
  }
}

/// 加载失败
class ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  const ErrorView({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final p = NeuPalette.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            NeuBox(radius: 50, width: 84, height: 84, child: Icon(Icons.cloud_off, size: 38, color: p.subText)),
            const SizedBox(height: 18),
            Text(message, textAlign: TextAlign.center, style: TextStyle(color: p.subText, fontSize: 14)),
            if (onRetry != null) ...<Widget>[
              const SizedBox(height: 18),
              NeuButton(text: '重试', icon: Icons.refresh, onPressed: onRetry, compact: true),
            ],
          ],
        ),
      ),
    );
  }
}

/// 空状态
class EmptyView extends StatelessWidget {
  final String message;
  final IconData icon;
  const EmptyView({super.key, required this.message, this.icon = Icons.inbox});

  @override
  Widget build(BuildContext context) {
    final p = NeuPalette.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            NeuBox(inset: true, radius: 50, width: 84, height: 84, child: Icon(icon, size: 36, color: p.subText)),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center, style: TextStyle(color: p.subText, fontSize: 13.5)),
          ],
        ),
      ),
    );
  }
}

/// 网络图片容器
class NetworkImageBox extends StatelessWidget {
  final String? url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double radius;
  final Map<String, String>? headers;
  final IconData fallbackIcon;

  const NetworkImageBox({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.radius = 14,
    this.headers,
    this.fallbackIcon = Icons.image_not_supported,
  });

  @override
  Widget build(BuildContext context) {
    final p = NeuPalette.of(context);
    Widget fallback = Container(
      width: width,
      height: height,
      color: p.surfaceAlt,
      child: Icon(fallbackIcon, color: p.subText, size: 26),
    );
    if (url == null || url!.isEmpty) return fallback;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Image.network(
        url!,
        width: width,
        height: height,
        fit: fit,
        headers: headers,
        loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? progress) {
          if (progress == null) return child;
          return Container(
            width: width,
            height: height,
            color: p.surfaceAlt,
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: p.accent),
              ),
            ),
          );
        },
        errorBuilder: (BuildContext context, Object error, StackTrace? stack) => fallback,
      ),
    );
  }
}

/// 带头像框的头像
class AvatarFrame extends StatelessWidget {
  final String? avatar;
  final String? frame;
  final double size;
  final double frameW;
  final double frameX;
  final double frameY;
  final VoidCallback? onTap;

  const AvatarFrame({
    super.key,
    required this.avatar,
    this.frame,
    this.size = 44,
    this.frameW = 100,
    this.frameX = 0,
    this.frameY = 0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = NeuPalette.of(context);
    Widget avatarBox = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: p.surfaceAlt,
        boxShadow: <BoxShadow>[
          BoxShadow(color: p.shadowDark.withOpacity(0.35), offset: const Offset(2, 2), blurRadius: 4),
        ],
      ),
      child: ClipOval(
        child: (avatar != null && avatar!.isNotEmpty)
            ? Image.network(
                avatar!,
                fit: BoxFit.cover,
                width: size,
                height: size,
                errorBuilder: (BuildContext c, Object e, StackTrace? s) =>
                    Icon(Icons.person, color: p.subText, size: size * 0.55),
              )
            : Icon(Icons.person, color: p.subText, size: size * 0.55),
      ),
    );
    if (frame == null || frame!.isEmpty) {
      return GestureDetector(onTap: onTap, child: avatarBox);
    }
    final fw = size * (frameW <= 0 ? 100 : frameW) / 100.0;
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          avatarBox,
          Positioned(
            left: size * frameX / 100.0,
            top: size * frameY / 100.0,
            child: SizedBox(
              width: fw,
              height: fw,
              child: Image.network(
                frame!,
                fit: BoxFit.contain,
                errorBuilder: (BuildContext c, Object e, StackTrace? s) => const SizedBox.shrink(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 区块标题
class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionText;
  final VoidCallback? onAction;

  const SectionHeader({super.key, required this.title, this.actionText, this.onAction});

  @override
  Widget build(BuildContext context) {
    final p = NeuPalette.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 10),
      child: Row(
        children: <Widget>[
          Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(color: p.accent, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(title, style: TextStyle(color: p.text, fontSize: 16, fontWeight: FontWeight.w300)),
          ),
          if (actionText != null)
            GestureDetector(
              onTap: onAction,
              child: Row(
                children: <Widget>[
                  Text(actionText!, style: TextStyle(color: p.subText, fontSize: 12.5)),
                  const SizedBox(width: 2),
                  Icon(Icons.chevron_right, size: 16, color: p.subText),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// 星级评分
class StarRating extends StatelessWidget {
  final double value;
  final double size;
  final ValueChanged<int>? onTap;
  final Color? color;

  const StarRating({super.key, required this.value, this.size = 18, this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    final p = NeuPalette.of(context);
    final starColor = color ?? p.warning;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List<Widget>.generate(5, (int i) {
        final IconData icon;
        if (value >= i + 1) {
          icon = Icons.star;
        } else if (value > i) {
          icon = Icons.star_half;
        } else {
          icon = Icons.star_border;
        }
        final star = Icon(icon, size: size, color: value > i ? starColor : p.subText);
        if (onTap == null) return star;
        return GestureDetector(
          onTap: () => onTap!(i + 1),
          child: Padding(padding: const EdgeInsets.symmetric(horizontal: 1), child: star),
        );
      }),
    );
  }
}

/// 小标签
class MetaTag extends StatelessWidget {
  final String text;
  final Color? color;
  final IconData? icon;

  const MetaTag({super.key, required this.text, this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    final p = NeuPalette.of(context);
    final c = color ?? p.subText;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: 11, color: c),
            const SizedBox(width: 4),
          ],
          Text(text, style: TextStyle(color: c, fontSize: 11.5, fontWeight: FontWeight.w300)),
        ],
      ),
    );
  }
}

/// 信息行
class InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const InfoRow({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final p = NeuPalette.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(width: 92, child: Text(label, style: TextStyle(color: p.subText, fontSize: 13))),
          Expanded(child: Text(value, style: TextStyle(color: p.text, fontSize: 13.5))),
        ],
      ),
    );
  }
}

/// 去除 HTML 标签的纯文本
String stripHtml(String html) {
  var s = html;
  s = s.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n');
  s = s.replaceAll(RegExp(r'</p\s*>', caseSensitive: false), '\n');
  s = s.replaceAll(RegExp(r'<[^>]+>'), '');
  s = s
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll('&ldquo;', '“')
      .replaceAll('&rdquo;', '”')
      .replaceAll('&hellip;', '…')
      .replaceAll('&mdash;', '—');
  return s.trim();
}

/// 列表底部加载更多
class LoadMoreFooter extends StatelessWidget {
  final bool loading;
  final bool hasMore;
  const LoadMoreFooter({super.key, required this.loading, required this.hasMore});

  @override
  Widget build(BuildContext context) {
    final p = NeuPalette.of(context);
    if (loading) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2, color: p.accent),
          ),
        ),
      );
    }
    if (hasMore) return const SizedBox(height: 8);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(child: Text('— 没有更多了 —', style: TextStyle(color: p.subText, fontSize: 12))),
    );
  }
}
