import 'package:flutter/material.dart';

import '../theme/neu_theme.dart';

/// 新拟态基础容器：凸起 / 按压 / 凹陷三种形态
class NeuBox extends StatefulWidget {
  final Widget? child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double radius;
  final Color? color;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool inset;
  final List<BoxShadow>? shadows;
  final Border? border;
  final bool animate;

  const NeuBox({
    super.key,
    this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.radius = 18,
    this.color,
    this.onTap,
    this.onLongPress,
    this.inset = false,
    this.shadows,
    this.border,
    this.animate = true,
  });

  @override
  State<NeuBox> createState() => _NeuBoxState();
}

class _NeuBoxState extends State<NeuBox> {
  bool _pressed = false;

  List<BoxShadow> _shadows(NeuPalette p) {
    if (widget.shadows != null) return widget.shadows!;
    if (widget.inset) {
      return <BoxShadow>[
        BoxShadow(color: p.shadowDark, offset: const Offset(2, 2), blurRadius: 5, spreadRadius: -1),
        BoxShadow(color: p.shadowLight, offset: const Offset(-2, -2), blurRadius: 5, spreadRadius: -1),
      ];
    }
    if (_pressed) {
      return <BoxShadow>[
        BoxShadow(color: p.shadowDark.withOpacity(0.5), offset: const Offset(2, 2), blurRadius: 6),
        BoxShadow(color: p.shadowLight.withOpacity(0.7), offset: const Offset(-2, -2), blurRadius: 6),
      ];
    }
    return <BoxShadow>[
      BoxShadow(color: p.shadowDark.withOpacity(0.18), offset: const Offset(0, 5), blurRadius: 20, spreadRadius: -5),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final p = NeuPalette.of(context);
    final content = AnimatedContainer(
      duration: widget.animate ? const Duration(milliseconds: 140) : Duration.zero,
      width: widget.width,
      height: widget.height,
      padding: widget.padding,
      margin: widget.margin,
      decoration: BoxDecoration(
        color: widget.color ?? p.surface,
        borderRadius: BorderRadius.circular(widget.radius),
        border: widget.border ?? Border.all(color: p.divider.withOpacity(0.5), width: 0.7),
        boxShadow: _shadows(p),
      ),
      child: widget.child,
    );
    if (widget.onTap == null && widget.onLongPress == null) return content;
    return GestureDetector(
      onTapDown: (_) {
        if (widget.animate) setState(() => _pressed = true);
      },
      onTapUp: (_) {
        if (widget.animate) setState(() => _pressed = false);
      },
      onTapCancel: () {
        if (widget.animate) setState(() => _pressed = false);
      },
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: content,
    );
  }
}

/// 新拟态按钮
class NeuButton extends StatelessWidget {
  final String? text;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool primary;
  final bool danger;
  final bool compact;
  final bool loading;
  final double? width;
  final Color? color;

  const NeuButton({
    super.key,
    this.text,
    this.icon,
    this.onPressed,
    this.primary = false,
    this.danger = false,
    this.compact = false,
    this.loading = false,
    this.width,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final p = NeuPalette.of(context);
    final bg = color ?? (primary ? p.accent : (danger ? p.danger : p.surface));
    final fg = danger ? p.onAccent : (primary ? (Theme.of(context).brightness == Brightness.dark ? p.bg : p.onAccent) : p.text);
    final enabled = onPressed != null && !loading;
    return Semantics(
      button: true,
      enabled: enabled,
      label: loading ? '${text ?? ''}，处理中' : text,
      child: AnimatedOpacity(
      opacity: !enabled && !loading ? 0.5 : 1,
      duration: const Duration(milliseconds: 160),
      child: NeuBox(
      onTap: loading ? null : onPressed,
      radius: compact ? 14 : 18,
      color: bg,
      padding: EdgeInsets.symmetric(horizontal: compact ? 14 : 20, vertical: compact ? 12 : 15),
      width: width,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          if (loading)
            SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: fg))
          else if (icon != null)
            Icon(icon, size: compact ? 16 : 18, color: fg),
          if (loading) const SizedBox(width: 8),
          if (!loading && icon != null && text != null) const SizedBox(width: 6),
          if (text != null)
            Flexible(child: Text(text!, maxLines: 2, overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center, style: TextStyle(color: fg, fontSize: compact ? 13 : 15, fontWeight: FontWeight.w300))),
        ],
      ),
    )));
  }
}

/// 新拟态图标按钮
class NeuIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final double size;
  final Color? iconColor;
  final Color? color;
  final String? tooltip;
  final bool badge;

  const NeuIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.size = 46,
    this.iconColor,
    this.color,
    this.tooltip,
    this.badge = false,
  });

  @override
  Widget build(BuildContext context) {
    final p = NeuPalette.of(context);
    return Tooltip(
      message: tooltip ?? '',
      child: NeuBox(
        onTap: onPressed,
        radius: size / 2,
        color: color,
        width: size < 44 ? 44 : size,
        height: size < 44 ? 44 : size,
        child: Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            Center(child: Icon(icon, size: size * 0.45, color: iconColor ?? p.text)),
            if (badge)
              Positioned(
                right: size * 0.2,
                top: size * 0.16,
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(color: p.danger, shape: BoxShape.circle),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 新拟态输入框
class NeuTextField extends StatelessWidget {
  final TextEditingController controller;
  final String? hint;
  final IconData? prefixIcon;
  final Widget? suffix;
  final bool obscure;
  final TextInputType? keyboardType;
  final int maxLines;
  final int? maxLength;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputAction? textInputAction;
  final bool enabled;
  final bool autofocus;

  const NeuTextField({
    super.key,
    required this.controller,
    this.hint,
    this.prefixIcon,
    this.suffix,
    this.obscure = false,
    this.keyboardType,
    this.maxLines = 1,
    this.maxLength,
    this.onChanged,
    this.onSubmitted,
    this.textInputAction,
    this.enabled = true,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    final p = NeuPalette.of(context);
    return NeuBox(
      inset: true,
      radius: 16,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: <Widget>[
          if (prefixIcon != null) ...<Widget>[
            Icon(prefixIcon, color: p.subText, size: 20),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: obscure,
              keyboardType: keyboardType,
              maxLines: obscure ? 1 : maxLines,
              maxLength: maxLength,
              enabled: enabled,
              autofocus: autofocus,
              onChanged: onChanged,
              onSubmitted: onSubmitted,
              textInputAction: textInputAction,
              cursorColor: p.accent,
              style: TextStyle(color: p.text, fontSize: 15),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(color: p.subText, fontSize: 14),
                border: InputBorder.none,
                counterText: '',
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                suffixIcon: suffix,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 新拟态开关
class NeuSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;

  const NeuSwitch({super.key, required this.value, this.onChanged});

  @override
  Widget build(BuildContext context) {
    final p = NeuPalette.of(context);
    return GestureDetector(
      onTap: onChanged == null ? null : () => onChanged!(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 52,
        height: 30,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: value ? p.accent : p.surface,
          borderRadius: BorderRadius.circular(15),
          boxShadow: value
              ? <BoxShadow>[]
              : <BoxShadow>[
                  BoxShadow(color: p.shadowDark, offset: const Offset(2, 2), blurRadius: 4, spreadRadius: -1),
                  BoxShadow(color: p.shadowLight, offset: const Offset(-2, -2), blurRadius: 4, spreadRadius: -1),
                ],
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 160),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: value ? Colors.white : p.subText,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}

/// 新拟态标签
class NeuChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final IconData? icon;
  final Color? selectedColor;

  const NeuChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
    this.icon,
    this.selectedColor,
  });

  @override
  Widget build(BuildContext context) {
    final p = NeuPalette.of(context);
    return NeuBox(
      onTap: onTap,
      radius: 16,
      color: selected ? (selectedColor ?? p.accent) : p.surface,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: 14, color: selected ? Colors.white : p.subText),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : p.text,
              fontSize: 13,
              fontWeight: FontWeight.w300,
            ),
          ),
        ],
      ),
    );
  }
}

/// 新拟态进度条
class NeuProgress extends StatelessWidget {
  final double value;
  final double height;
  final Color? color;
  final double? width;

  const NeuProgress({super.key, required this.value, this.height = 12, this.color, this.width});

  @override
  Widget build(BuildContext context) {
    final p = NeuPalette.of(context);
    return NeuBox(
      inset: true,
      radius: height / 2,
      padding: EdgeInsets.zero,
      width: width,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(height / 2),
        child: Stack(
          children: <Widget>[
            Positioned.fill(child: Container(color: p.surface)),
            FractionallySizedBox(
              widthFactor: value.clamp(0.0, 1.0),
              child: Container(height: height, color: color ?? p.accent),
            ),
          ],
        ),
      ),
    );
  }
}

/// 新拟态分段选择器
class NeuSegmented<T> extends StatelessWidget {
  final List<T> values;
  final List<String> labels;
  final T value;
  final ValueChanged<T> onChanged;

  const NeuSegmented({
    super.key,
    required this.values,
    required this.labels,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final p = NeuPalette.of(context);
    return NeuBox(
      inset: true,
      radius: 16,
      padding: const EdgeInsets.all(4),
      child: Row(
        children: List<Widget>.generate(values.length, (int i) {
          final selected = values[i] == value;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(values[i]),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: selected ? p.accent : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: selected
                      ? <BoxShadow>[
                          BoxShadow(color: p.accent.withOpacity(0.4), offset: const Offset(0, 2), blurRadius: 6),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    labels[i],
                    style: TextStyle(
                      color: selected ? Colors.white : p.subText,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// 新拟态顶栏
class NeuAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final List<Widget>? actions;
  final Widget? leading;

  const NeuAppBar({super.key, this.title, this.actions, this.leading});

  @override
  Size get preferredSize => const Size.fromHeight(62);

  @override
  Widget build(BuildContext context) {
    final p = NeuPalette.of(context);
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
        child: Row(
          children: <Widget>[
            if (leading != null) leading! else const SizedBox(width: 4),
            Expanded(
              child: Center(
                child: Text(
                  title ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: p.text, fontSize: 18, fontWeight: FontWeight.w300),
                ),
              ),
            ),
            if (actions != null) ...actions! else const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }
}

/// 未读数字角标
class NeuBadge extends StatelessWidget {
  final int count;
  final double size;

  const NeuBadge({super.key, required this.count, this.size = 18});

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();
    final p = NeuPalette.of(context);
    final text = count > 99 ? '99+' : '$count';
    return Container(
      constraints: BoxConstraints(minWidth: size),
      height: size,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      alignment: Alignment.center,
      decoration: BoxDecoration(color: p.danger, borderRadius: BorderRadius.circular(size / 2)),
      child: Text(
        text,
        style: TextStyle(color: Colors.white, fontSize: size * 0.62, fontWeight: FontWeight.w300),
      ),
    );
  }
}
