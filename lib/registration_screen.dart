import 'package:flutter/material.dart';
import 'api.dart';
import 'otp_screen.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});
  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}
class _RegistrationScreenState extends State<RegistrationScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController(), _email = TextEditingController(), _password = TextEditingController(), _initials = TextEditingController();
  bool _busy = false, _show = false;
  String? _message;
  Map<String, String> get _credentials => {'username': _name.text.trim(), 'password': _password.text};
  Future<void> _submit({bool resend = false}) async {
    if (_busy || (!resend && !_form.currentState!.validate())) return;
    setState(() { _busy = true; _message = null; });
    try {
      final data = await Api.call('POST', 'Authenticate/${resend ? 'resend-verification' : 'register'}', resend ? _credentials : {
        ..._credentials, 'email': _email.text.trim(), 'initials': _initials.text.trim(),
      });
      if (!mounted) return;
      final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => OtpScreen(challengeId: data['challengeId'], login: false,
        resend: () => Api.call('POST', 'Authenticate/resend-verification', _credentials))));
      if (!mounted) return;
      if (result != null) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã xác minh email. Hãy đăng nhập.'))); Navigator.pop(context); }
    } catch (e) { if (mounted) setState(() => _message = '$e'); }
    finally { if (mounted) setState(() => _busy = false); }
  }
  @override
  void dispose() { for (final c in [_name, _email, _password, _initials]) { c.dispose(); } super.dispose(); }
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Đăng ký bằng email')),
    body: SingleChildScrollView(padding: const EdgeInsets.all(24), child: Form(key: _form, child: Column(children: [
      TextFormField(controller: _name, decoration: const InputDecoration(labelText: 'Tên đăng nhập'), validator: (s) => s == null || s.trim().isEmpty ? 'Nhập tên đăng nhập' : null),
      TextFormField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email'), validator: (s) => s == null || !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(s.trim()) ? 'Email không hợp lệ' : null),
      TextFormField(controller: _password, obscureText: !_show, decoration: InputDecoration(labelText: 'Mật khẩu: chữ hoa, thường, số, ký tự đặc biệt', suffixIcon: IconButton(icon: Icon(_show ? Icons.visibility : Icons.visibility_off), onPressed: () => setState(() => _show = !_show))), validator: (s) => s == null || s.length < 6 ? 'Ít nhất 6 ký tự' : null),
      TextFormField(controller: _initials, maxLength: 5, decoration: const InputDecoration(labelText: 'Tên viết tắt')),
      if (_message != null) Text(_message!, style: const TextStyle(color: Colors.red)),
      FilledButton(onPressed: _busy ? null : () => _submit(), child: const Text('Đăng ký và nhận OTP')),
      TextButton(onPressed: _busy ? null : () => _submit(resend: true), child: const Text('Đã đăng ký: gửi lại xác minh (nhập tên và mật khẩu)')),
    ]))),
  );
}
