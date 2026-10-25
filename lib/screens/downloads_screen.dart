import 'dart:io';

import 'package:flutter/material.dart';

import '../services/device_bridge.dart';
import '../services/download_manager.dart';
import '../services/storage.dart';
import '../theme/neu_theme.dart';
import '../widgets/common.dart';
import '../widgets/neu.dart';

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  @override
  void initState() {
    super.initState();
    DownloadManager.instance.addListener(_onChanged);
  }

  @override
  void dispose() {
    DownloadManager.instance.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  int _filter = 0;

  String _statusText(DownloadTask t) {
    switch (t.status) {
      case DownloadStatus.queued:
        return t.error ?? '等待下载';
      case DownloadStatus.resolving:
        return '解析链接中';
      case DownloadStatus.downloading:
        return '下载中';
      case DownloadStatus.completed:
        return '已完成';
      case DownloadStatus.failed:
        return t.error ?? '下载失败';
      case DownloadStatus.canceled:
        return '已取消';
    }
  }

  Color _statusColor(DownloadTask t, NeuPalette p) {
    switch (t.status) {
      case DownloadStatus.queued:
      case DownloadStatus.resolving:
      case DownloadStatus.downloading:
        return p.accent;
      case DownloadStatus.completed:
        return p.success;
      case DownloadStatus.failed:
        return p.danger;
      case DownloadStatus.canceled:
        return p.subText;
    }
  }

  Future<void> _deleteRecord(String filePath) async {
    final ok = await confirmDialog(context, title: '删除下载文件', content: '此操作会删除本地文件与记录，确定继续？', confirmText: '删除');
    if (!ok) return;
    try {
      final file = File(filePath);
      if (file.existsSync()) await file.delete();
    } catch (_) {}
    final records = Storage.instance.downloadRecords;
    records.removeWhere((r) => r['filePath'] == filePath);
    await Storage.instance.saveDownloadRecords(records);
    if (!mounted) return;
    setState(() {});
    showToast(context, '已删除');
  }

  @override
  Widget build(BuildContext context) {
    final p = NeuPalette.of(context);
    final tasks = DownloadManager.instance.tasks;
    final records = Storage.instance.downloadRecords;
    final visible = tasks.where((t) => _filter == 0 || (_filter == 1 ? t.isActive : !t.isActive)).toList();
    return Scaffold(
      appBar: NeuAppBar(
        title: '下载管理',
        leading: NeuIconButton(icon: Icons.arrow_back, size: 40, onPressed: () => Navigator.pop(context)),
      ),
      body: (tasks.isEmpty && records.isEmpty)
          ? const EmptyView(message: '还没有下载任务\n去应用详情页试试下载吧', icon: Icons.download_outlined)
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: <Widget>[
                NeuBox(
                  color: p.accentSoft, radius: 24, padding: const EdgeInsets.all(22),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('下载中心', style: TextStyle(color: p.text, fontSize: 26)),
                    const SizedBox(height: 8),
                    Text('${tasks.where((t) => t.isActive).length} 个正在下载 · ${tasks.where((t) => t.status == DownloadStatus.completed).length} 个已完成', style: TextStyle(color: p.text)),
                    const SizedBox(height: 8),
                    Text('网页确认后开始，离开应用也能继续下载。', style: TextStyle(color: p.subText, fontSize: 12)),
                  ]),
                ),
                const SizedBox(height: 18),
                NeuSegmented<int>(values: const [0, 1, 2], labels: const ['全部', '进行中', '已结束'], value: _filter, onChanged: (v) => setState(() => _filter = v)),
                const SizedBox(height: 18),
                if (visible.isEmpty) const Padding(padding: EdgeInsets.all(20), child: Text('这个分组暂时没有任务')),
                if (tasks.isNotEmpty) ...<Widget>[
                  SectionHeader(title: '任务列表（${visible.length}）'),
                  ...visible.map((DownloadTask t) => _taskCard(t, p)),
                ],
                if (records.isNotEmpty) ...<Widget>[
                  SectionHeader(title: '下载记录（${records.length}）'),
                  ...records.map((Map<String, dynamic> r) => _recordCard(r, p)),
                ],
              ],
            ),
    );
  }

  Widget _taskCard(DownloadTask t, NeuPalette p) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: NeuBox(
        radius: 20,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    t.appTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: p.text, fontSize: 14.5, fontWeight: FontWeight.w300),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(child: Text(_statusText(t), maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: _statusColor(t, p), fontSize: 11.5))),
              ],
            ),
            const SizedBox(height: 10),
            if (t.isActive)
              ClipRRect(borderRadius: BorderRadius.circular(6), child: LinearProgressIndicator(
                value: t.total > 0 ? t.progress : null, minHeight: 8,
                backgroundColor: p.accentSoft, color: p.accent)),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    t.total > 0
                        ? '${(t.received / 1024 / 1024).toStringAsFixed(1)} MB / ${(t.total / 1024 / 1024).toStringAsFixed(1)} MB'
                        : t.fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: p.subText, fontSize: 11.5),
                  ),
                ),
                if (t.isActive)
                  NeuIconButton(
                    icon: Icons.close,
                    size: 32,
                    onPressed: () => DownloadManager.instance.cancelTask(t),
                  ),
                if (t.status == DownloadStatus.completed) ...<Widget>[
                  NeuButton(
                    text: t.isApk ? '安装' : '已完成',
                    compact: true,
                    onPressed: t.isApk ? () async {
                      final ok = await DownloadManager.instance.open(t);
                      if (mounted && !ok) showToast(context, '文件不可用或暂时无法启动安装');
                    } : null,
                  ),
                  const SizedBox(width: 8),
                  NeuIconButton(
                    icon: Icons.delete_outline,
                    size: 32,
                    onPressed: () => DownloadManager.instance.forgetTask(t),
                  ),
                ],
                if (t.status == DownloadStatus.failed || t.status == DownloadStatus.canceled) ...<Widget>[
                  NeuButton(
                    text: '重试',
                    compact: true,
                    onPressed: () async {
                      try {
                        await DownloadManager.instance.browse(appId: t.appId, appTitle: t.appTitle,
                          url: t.sourceUrl, dark: Theme.of(context).brightness == Brightness.dark);
                      } catch (e) { if (mounted) showToast(context, '重试未开始：$e'); }
                    },
                  ),
                  const SizedBox(width: 8),
                  NeuIconButton(
                    icon: Icons.delete_outline,
                    size: 32,
                    onPressed: () => DownloadManager.instance.forgetTask(t),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _recordCard(Map<String, dynamic> r, NeuPalette p) {
    final filePath = (r['filePath'] ?? '').toString();
    final exists = filePath.isNotEmpty && File(filePath).existsSync();
    final total = r['total'];
    final totalText = total is int && total > 0 ? '${(total / 1024 / 1024).toStringAsFixed(1)} MB' : '';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: NeuBox(
        radius: 20,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    (r['appTitle'] ?? '应用').toString(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: p.text, fontSize: 14.5, fontWeight: FontWeight.w300),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    [
                      (r['fileName'] ?? '').toString(),
                      if (totalText.isNotEmpty) totalText,
                      if (!exists) '文件已不存在',
                    ].where((String s) => s.isNotEmpty).join(' · '),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: p.subText, fontSize: 11.5),
                  ),
                ],
              ),
            ),
            if (exists) ...<Widget>[
              NeuIconButton(
                icon: Icons.install_mobile_outlined,
                size: 36,
                onPressed: () => DeviceBridge.instance.openApk(filePath),
              ),
              const SizedBox(width: 8),
            ],
            NeuIconButton(
              icon: Icons.delete_outline,
              size: 36,
              onPressed: () => _deleteRecord(filePath),
            ),
          ],
        ),
      ),
    );
  }
}
