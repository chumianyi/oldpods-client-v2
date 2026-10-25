import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/neu_theme.dart';
import '../widgets/common.dart';
import '../widgets/neu.dart';

class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  final ApiService _api = ApiService.instance;

  List<Announcement> _items = <Announcement>[];
  bool _loading = true;
  String? _error;
  final Set<int> _expanded = <int>{};

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
      final items = await _api.announcements();
      if (!mounted) return;
      setState(() {
        _items = items;
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

  @override
  Widget build(BuildContext context) {
    final p = NeuPalette.of(context);
    return Scaffold(
      appBar: NeuAppBar(
        title: '公告',
        leading: NeuIconButton(icon: Icons.arrow_back, size: 40, onPressed: () => Navigator.pop(context)),
      ),
      body: RefreshIndicator(
        color: p.accent,
        backgroundColor: p.surface,
        onRefresh: _load,
        child: _loading && _items.isEmpty
            ? ListView(children: const <Widget>[SizedBox(height: 240, child: LoadingView())])
            : (_error != null && _items.isEmpty
                ? ListView(children: <Widget>[SizedBox(height: 300, child: ErrorView(message: _error!, onRetry: _load))])
                : (_items.isEmpty
                    ? ListView(children: const <Widget>[SizedBox(height: 300, child: EmptyView(message: '暂无公告', icon: Icons.campaign_outlined))])
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                        itemCount: _items.length,
                        itemBuilder: (BuildContext context, int i) {
                          final item = _items[i];
                          final expanded = _expanded.contains(item.id);
                          final text = stripHtml(item.content);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: NeuBox(
                              radius: 20,
                              padding: const EdgeInsets.all(16),
                              onTap: () => setState(() {
                                if (expanded) {
                                  _expanded.remove(item.id);
                                } else {
                                  _expanded.add(item.id);
                                }
                              }),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Row(
                                    children: <Widget>[
                                      NeuBox(inset: true, radius: 12, width: 36, height: 36, padding: EdgeInsets.zero, child: Icon(Icons.campaign, size: 18, color: p.accent)),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          item.title,
                                          style: TextStyle(color: p.text, fontSize: 14.5, fontWeight: FontWeight.w300),
                                        ),
                                      ),
                                      Icon(expanded ? Icons.expand_less : Icons.expand_more, color: p.subText),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  AnimatedCrossFade(
                                    duration: const Duration(milliseconds: 200),
                                    crossFadeState: expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                                    firstChild: Text(
                                      text,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(color: p.subText, fontSize: 13, height: 1.5),
                                    ),
                                    secondChild: SelectableText(
                                      text,
                                      style: TextStyle(color: p.subText, fontSize: 13, height: 1.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ))),
      ),
    );
  }
}
