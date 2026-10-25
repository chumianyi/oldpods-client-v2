import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/api_client.dart';
import '../services/api_service.dart';
import '../state/app_state.dart';
import '../theme/neu_theme.dart';
import '../widgets/common.dart';
import '../widgets/neu.dart';

class LoginScreen extends StatefulWidget {
  final int initialTab;
  const LoginScreen({super.key, this.initialTab = 0});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final ApiService _api = ApiService.instance;

  int _tab = 0;
  bool _submitting = false;
  bool _obscure = true;
  String _termsVersion = '1';
  bool _agreed = false;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _password2Controller = TextEditingController();
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tab = widget.initialTab;
    _loadTermsVersion();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _password2Controller.dispose();
    _nicknameController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _loadTermsVersion() async {
    try {
      final terms = await _api.terms();
      if (mounted && terms.version.isNotEmpty) {
        setState(() => _termsVersion = terms.version);
      }
    } catch (_) {}
  }

  String get _email => _emailController.text.trim();
  String get _password => _passwordController.text;

  Future<void> _submit() async {
    if (_email.isEmpty || _password.isEmpty) {
      showToast(context, '请输入邮箱和密码');
      return;
    }
    setState(() => _submitting = true);
    try {
      final data = await _api.login(_email, _password);
      final apiKey = data['api_key'] ?? data['token'] ?? data['key'] ?? '';
      if (apiKey.toString().isEmpty) {
        throw ApiException('登录成功但未获取到 api_key');
      }
      await AppState.instance.applyLogin(
        apiKey: apiKey.toString(),
        userId: data['user_id'] is int ? data['user_id'] as int : int.tryParse('${data['user_id']}'),
        nickname: data['nickname']?.toString(),
        avatar: data['avatar']?.toString(),
        email: _email,
      );
      await AppState.instance.refreshUser();
      if (!mounted) return;
      showToast(context, '登录成功');
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) showToast(context, e.message);
    } catch (e) {
      if (mounted) showToast(context, '登录失败：$e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _register() async {
    final nickname = _nicknameController.text.trim();
    final code = _codeController.text.trim();
    if (_email.isEmpty || nickname.isEmpty || code.isEmpty || _password.isEmpty) {
      showToast(context, '请填写完整注册信息');
      return;
    }
    if (_password != _password2Controller.text) {
      showToast(context, '两次输入的密码不一致');
      return;
    }
    if (!_agreed) {
      showToast(context, '请先同意用户协议');
      return;
    }
    setState(() => _submitting = true);
    try {
      await _api.register(
        email: _email,
        password: _password,
        nickname: nickname,
        code: code,
        termsVersion: _termsVersion,
      );
      if (!mounted) return;
      showToast(context, '注册成功，请登录');
      setState(() {
        _tab = 0;
        _submitting = false;
      });
    } on ApiException catch (e) {
      if (mounted) showToast(context, e.message);
    } catch (e) {
      if (mounted) showToast(context, '注册失败：$e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _sendRegisterCode() async {
    if (_email.isEmpty) {
      showToast(context, '请先输入邮箱');
      return;
    }
    try {
      await _api.sendCode(_email);
      showToast(context, '验证码已发送');
    } on ApiException catch (e) {
      showToast(context, e.message);
    }
  }

  Future<void> _forgot() async {
    final code = _codeController.text.trim();
    if (_email.isEmpty || code.isEmpty || _password.isEmpty) {
      showToast(context, '请填写邮箱、验证码和新密码');
      return;
    }
    if (_password != _password2Controller.text) {
      showToast(context, '两次输入的密码不一致');
      return;
    }
    setState(() => _submitting = true);
    try {
      await _api.forgotSendCode(_email);
      await _api.forgotReset(
        email: _email,
        code: code,
        password: _password,
        password2: _password2Controller.text,
      );
      if (!mounted) return;
      showToast(context, '密码重置成功，请登录');
      setState(() {
        _tab = 0;
        _submitting = false;
      });
    } on ApiException catch (e) {
      if (mounted) showToast(context, e.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _sendForgotCode() async {
    if (_email.isEmpty) {
      showToast(context, '请先输入邮箱');
      return;
    }
    try {
      await _api.forgotSendCode(_email);
      showToast(context, '验证码已发送');
    } on ApiException catch (e) {
      showToast(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = NeuPalette.of(context);
    return Scaffold(
      appBar: NeuAppBar(
        title: '账号',
        leading: NeuIconButton(icon: Icons.close, size: 40, onPressed: () => Navigator.pop(context)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          children: <Widget>[
            NeuBox(
              radius: 22,
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('老豆荚账号', style: TextStyle(color: p.text, fontSize: 19, fontWeight: FontWeight.w300)),
                  const SizedBox(height: 4),
                  Text('登录即送 20 硬币，可兑换下载奖励', style: TextStyle(color: p.subText, fontSize: 12.5)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            NeuSegmented<int>(
              values: const <int>[0, 1, 2],
              labels: const <String>['登录', '注册', '找回密码'],
              value: _tab,
              onChanged: (int v) => setState(() => _tab = v),
            ),
            const SizedBox(height: 18),
            if (_tab == 0) ..._buildLoginForm(p),
            if (_tab == 1) ..._buildRegisterForm(p),
            if (_tab == 2) ..._buildForgotForm(p),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildLoginForm(NeuPalette p) {
    return <Widget>[
      NeuTextField(
        controller: _emailController,
        hint: '邮箱',
        prefixIcon: Icons.email_outlined,
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.next,
      ),
      const SizedBox(height: 12),
      NeuTextField(
        controller: _passwordController,
        hint: '密码',
        prefixIcon: Icons.lock_outline,
        obscure: _obscure,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _submit(),
        suffix: IconButton(
          icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: p.subText, size: 19),
          onPressed: () => setState(() => _obscure = !_obscure),
        ),
      ),
      const SizedBox(height: 8),
      Align(
        alignment: Alignment.centerRight,
        child: TextButton(
          onPressed: () => setState(() => _tab = 2),
          child: Text('忘记密码？', style: TextStyle(color: p.accent, fontSize: 12.5)),
        ),
      ),
      const SizedBox(height: 6),
      NeuButton(
        text: '登录',
        icon: Icons.login,
        primary: true,
        width: double.infinity,
        loading: _submitting,
        onPressed: _submit,
      ),
    ];
  }

  List<Widget> _buildRegisterForm(NeuPalette p) {
    return <Widget>[
      NeuTextField(
        controller: _emailController,
        hint: '邮箱',
        prefixIcon: Icons.email_outlined,
        keyboardType: TextInputType.emailAddress,
      ),
      const SizedBox(height: 12),
      NeuTextField(
        controller: _nicknameController,
        hint: '昵称',
        prefixIcon: Icons.person_outline,
        maxLength: 20,
      ),
      const SizedBox(height: 12),
      Row(
        children: <Widget>[
          Expanded(
            child: NeuTextField(
              controller: _codeController,
              hint: '邮箱验证码',
              prefixIcon: Icons.mark_email_read_outlined,
              keyboardType: TextInputType.number,
            ),
          ),
          const SizedBox(width: 10),
          NeuButton(
            text: '发送验证码',
            compact: true,
            onPressed: _sendRegisterCode,
          ),
        ],
      ),
      const SizedBox(height: 12),
      NeuTextField(
        controller: _passwordController,
        hint: '密码（至少 6 位）',
        prefixIcon: Icons.lock_outline,
        obscure: _obscure,
        suffix: IconButton(
          icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: p.subText, size: 19),
          onPressed: () => setState(() => _obscure = !_obscure),
        ),
      ),
      const SizedBox(height: 12),
      NeuTextField(
        controller: _password2Controller,
        hint: '确认密码',
        prefixIcon: Icons.lock_outline,
        obscure: _obscure,
      ),
      const SizedBox(height: 8),
      Row(
        children: <Widget>[
          NeuSwitch(value: _agreed, onChanged: (bool v) => setState(() => _agreed = v)),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/terms'),
              child: Text.rich(
                TextSpan(
                  text: '我已阅读并同意',
                  style: TextStyle(color: p.subText, fontSize: 12.5),
                  children: <TextSpan>[
                    TextSpan(text: '《用户协议》', style: TextStyle(color: p.accent, fontSize: 12.5)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      NeuButton(
        text: '注册',
        icon: Icons.person_add,
        primary: true,
        width: double.infinity,
        loading: _submitting,
        onPressed: _register,
      ),
    ];
  }

  List<Widget> _buildForgotForm(NeuPalette p) {
    return <Widget>[
      NeuTextField(
        controller: _emailController,
        hint: '注册邮箱',
        prefixIcon: Icons.email_outlined,
        keyboardType: TextInputType.emailAddress,
      ),
      const SizedBox(height: 12),
      Row(
        children: <Widget>[
          Expanded(
            child: NeuTextField(
              controller: _codeController,
              hint: '邮箱验证码',
              prefixIcon: Icons.mark_email_read_outlined,
              keyboardType: TextInputType.number,
            ),
          ),
          const SizedBox(width: 10),
          NeuButton(
            text: '发送验证码',
            compact: true,
            onPressed: _sendForgotCode,
          ),
        ],
      ),
      const SizedBox(height: 12),
      NeuTextField(
        controller: _passwordController,
        hint: '新密码',
        prefixIcon: Icons.lock_outline,
        obscure: _obscure,
        suffix: IconButton(
          icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: p.subText, size: 19),
          onPressed: () => setState(() => _obscure = !_obscure),
        ),
      ),
      const SizedBox(height: 12),
      NeuTextField(
        controller: _password2Controller,
        hint: '确认新密码',
        prefixIcon: Icons.lock_outline,
        obscure: _obscure,
      ),
      const SizedBox(height: 16),
      NeuButton(
        text: '重置密码',
        icon: Icons.lock_reset,
        primary: true,
        width: double.infinity,
        loading: _submitting,
        onPressed: _forgot,
      ),
    ];
  }
}
