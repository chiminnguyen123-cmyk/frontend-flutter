import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api.dart';
import 'registration_screen.dart';
import 'dashboard_screen.dart';
import 'otp_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _name = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false, _show = false;
  String? _error;
  Future<void> _login() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final data = await Api.call('POST', 'Authenticate/login', {
        'username': _name.text.trim(),
        'password': _password.text,
      });
      if (!mounted) return;
      final verified = await Navigator.push<Map<String, dynamic>>(
        context,
        MaterialPageRoute(
          builder: (_) => OtpScreen(
            challengeId: data['challengeId'],
            login: true,
            resend: () => Api.call('POST', 'Authenticate/login', {
              'username': _name.text.trim(),
              'password': _password.text,
            }),
          ),
        ),
      );
      if (!mounted || verified == null) return;
      final roles = List<String>.from(verified['roles']);
      final role = roles.contains('Admin')
          ? 'Admin'
          : roles.contains('Employee')
          ? 'Employee'
          : roles.contains('User')
          ? 'User'
          : null;
      if (role == null) {
        Api.token = null;
        throw Exception('Tài khoản chưa có vai trò phù hợp. Nhờ Admin kiểm tra quyền.');
      }
      Api.token = verified['token'] as String;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('jwt_token');
      await prefs.remove('user_role');
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => DashboardScreen(role: role)),
      );
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Đăng nhập điểm danh')),
    body: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.school, size: 72),
            TextField(
              controller: _name,
              decoration: const InputDecoration(
                labelText: 'Tên đăng nhập',
                helperText: 'Dùng tên đã đăng ký, không phải email. Mật khẩu là mật khẩu của app.',
              ),
              enabled: !_busy,
            ),
            TextField(
              controller: _password,
              obscureText: !_show,
              enabled: !_busy,
              decoration: InputDecoration(
                labelText: 'Mật khẩu',
                suffixIcon: IconButton(
                  tooltip: _show ? 'Ẩn mật khẩu' : 'Hiện mật khẩu',
                  icon: Icon(_show ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _show = !_show),
                ),
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _busy ? null : _login,
              child: Text(_busy ? 'Đang gửi...' : 'Tiếp tục nhận OTP'),
            ),
            TextButton(
              onPressed: _busy
                  ? null
                  : () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const RegistrationScreen(),
                      ),
                    ),
              child: const Text('Đăng ký / gửi lại xác minh email'),
            ),
          ],
        ),
      ),
    ),
  );
}
