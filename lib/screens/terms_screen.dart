import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/neu_theme.dart';
import '../widgets/common.dart';
import '../widgets/neu.dart';

class TermsScreen extends StatefulWidget {
  const TermsScreen({super.key});

  @override
  State<TermsScreen> createState() => _TermsScreenState();
}

class _TermsScreenState extends State<TermsScreen> {
  final ApiService _api = ApiService.instance;

  TermsData? _terms;
  bool _loading = true;
  String? _error;

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
      final terms = await _api.terms();
      if (!mounted) return;
      setState(() {
        _terms = terms;
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
        title: '用户协议',
        leading: NeuIconButton(icon: Icons.arrow_back, size: 40, onPressed: () => Navigator.pop(context)),
      ),
      body: _loading && _terms == null
          ? const LoadingView(message: '正在加载协议…')
          : (_error != null && _terms == null
              ? ErrorView(message: _error!, onRetry: _load)
              : _buildTerms(p)),
    );
  }

  Widget _buildTerms(NeuPalette p) {
    final t = _terms!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: <Widget>[
        NeuBox(
          radius: 22,
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(t.title, style: TextStyle(color: p.text, fontSize: 18, fontWeight: FontWeight.w300)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: <Widget>[
                  if (t.versionLabel.isNotEmpty) MetaTag(text: t.versionLabel, color: p.accent),
                  if (t.updatedAt.isNotEmpty) MetaTag(text: '更新于 ${t.updatedAt}'),
                ],
              ),
              if (t.intro.isNotEmpty) ...<Widget>[
                const SizedBox(height: 12),
                Text(t.intro, style: TextStyle(color: p.subText, fontSize: 13.5, height: 1.7)),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (t.sections.isNotEmpty)
          ...t.sections.map((TermsSection s) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: NeuBox(
                radius: 18,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    if (s.title.isNotEmpty) ...<Widget>[
                      Text(s.title, style: TextStyle(color: p.text, fontSize: 15, fontWeight: FontWeight.w300)),
                      const SizedBox(height: 8),
                    ],
                    SelectableText(s.content, style: TextStyle(color: p.subText, fontSize: 13.5, height: 1.7)),
                  ],
                ),
              ),
            );
          }),
        if (t.contactTitle.isNotEmpty && t.contacts.isNotEmpty) ...<Widget>[
          NeuBox(
            radius: 18,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(t.contactTitle, style: TextStyle(color: p.text, fontSize: 15, fontWeight: FontWeight.w300)),
                const SizedBox(height: 8),
                ...t.contacts.map((TermsSection s) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      [if (s.title.isNotEmpty) '${s.title}：', s.content].join(),
                      style: TextStyle(color: p.subText, fontSize: 13.5, height: 1.6),
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (t.signatures.isNotEmpty) ...<Widget>[
          NeuBox(
            radius: 18,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                ...t.signatures.map((String s) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(s, style: TextStyle(color: p.subText, fontSize: 13, height: 1.6)),
                  );
                }),
              ],
            ),
          ),
        ],
        if (t.sections.isEmpty && t.contacts.isEmpty && t.signatures.isEmpty && t.text.isNotEmpty) ...<Widget>[
          NeuBox(
            radius: 18,
            padding: const EdgeInsets.all(16),
            child: SelectableText(t.text, style: TextStyle(color: p.subText, fontSize: 13.5, height: 1.7)),
          ),
        ],
      ],
    );
  }
}
