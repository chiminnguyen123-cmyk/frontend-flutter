import 'package:flutter/material.dart';
import 'api.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key, required this.challengeId, required this.login, required this.resend});
  final String challengeId;
  final bool login;
  final Future<dynamic> Function() resend;
  @override
  State<OtpScreen> createState() => _OtpScreenState();
}
class _OtpScreenState extends State<OtpScreen> {
  final _code = TextEditingController();
  late String _challenge;
  bool _busy = false;
  String? _message;
  DateTime _nextSend = DateTime.now().add(const Duration(seconds: 60));
  @override
  void initState() { super.initState(); _challenge = widget.challengeId; }
  Future<void> _verify() async {
    if (!RegExp(r'^\d{6}$').hasMatch(_code.text)) { setState(() => _message = 'Nhập đúng 6 chữ số.'); return; }
    setState(() => _busy = true);
    try {
      final data = await Api.call('POST', 'Authenticate/${widget.login ? 'verify-login' : 'verify-email'}', {'challengeId': _challenge, 'code': _code.text});
      if (mounted) Navigator.pop(context, Map<String, dynamic>.from(data));
    } catch (e) { if (mounted) setState(() => _message = '$e'); }
    finally { if (mounted) setState(() => _busy = false); }
  }
  Future<void> _resend() async {
    if (DateTime.now().isBefore(_nextSend)) { setState(() => _message = 'Chờ 60 giây giữa các lần gửi.'); return; }
    setState(() => _busy = true);
    try {
      final data = await widget.resend();
      if (!mounted) return;
      setState(() { _challenge = data['challengeId']; _nextSend = DateTime.now().add(const Duration(seconds: 60)); _message = 'Đã gửi mã mới.'; _code.clear(); });
    } catch (e) { if (mounted) setState(() => _message = '$e'); }
    finally { if (mounted) setState(() => _busy = false); }
  }
  @override
  void dispose() { _code.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Xác minh OTP qua email')),
    body: Padding(padding: const EdgeInsets.all(24), child: Column(children: [
      const Text('Mã có hiệu lực 5 phút, tối đa 5 lần thử. Kiểm tra cả thư rác.'),
      TextField(controller: _code, keyboardType: TextInputType.number, maxLength: 6, decoration: const InputDecoration(labelText: 'OTP 6 chữ số')),
      if (_message != null) Text(_message!),
      FilledButton(onPressed: _busy ? null : _verify, child: const Text('Xác minh')),
      TextButton(onPressed: _busy ? null : _resend, child: const Text('Gửi lại OTP (sau 60 giây)')),
    ])),
  );
}
