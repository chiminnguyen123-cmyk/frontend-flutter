import 'package:flutter/material.dart';

import 'api.dart';
import 'scanner_screen.dart';
import 'location_service.dart';

class StudentScreen extends StatefulWidget {
  const StudentScreen({super.key});
  @override
  State<StudentScreen> createState() => _StudentScreenState();
}

class _StudentScreenState extends State<StudentScreen> {
  bool _busy = false;
  String? _message;
  List<dynamic> _history = [];
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await Api.call('GET', 'attendance/mine');
      if (mounted) setState(() => _history = data);
    } catch (e) {
      if (mounted) setState(() => _message = '$e');
    }
  }

  Future<void> _scan() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final payload = await Navigator.push<String>(
        context,
        MaterialPageRoute(builder: (_) => const ScannerScreen()),
      );
      if (!mounted || payload == null) return;
      if (!payload.startsWith('ATTEND:')) {
        setState(
          () => _message = 'Đã quét: $payload\nMã này không phải mã điểm danh.',
        );
        return;
      }
      final consent = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('Chia sẻ vị trí để điểm danh'),
          content: const Text(
            'Gửi vị trí hiện tại một lần tới máy chủ để kiểm tra bán kính lớp học. Máy chủ lưu thời gian và khoảng cách điểm danh. Không theo dõi nền.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('Đồng ý'),
            ),
          ],
        ),
      );
      if (!mounted || consent != true) return;
      final position = await currentPosition();
      final data = await Api.call('POST', 'attendance/check-in', {
        'payload': payload,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': position.accuracy,
      });
      if (mounted) {
        setState(
          () => _message =
              '${data['message']}\nKhoảng cách đến tâm phiên: ${data['distanceMeters']} m.\nĐộ chính xác GPS: ${position.accuracy.round()} m.',
        );
      }
      await _load();
    } catch (e) {
      if (mounted) setState(() => _message = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Sinh viên – Điểm danh của tôi'),
      actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))],
    ),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Trước khi quét, nhờ Admin liên kết tài khoản với hồ sơ sinh viên. Bật vị trí và đứng trong bán kính phiên của giảng viên.',
        ),
        FilledButton.icon(
          onPressed: _busy ? null : _scan,
          icon: const Icon(Icons.qr_code_scanner),
          label: Text(_busy ? 'Đang xử lý...' : 'Quét QR/Barcode và điểm danh'),
        ),
        if (_message != null)
          Padding(padding: const EdgeInsets.all(16), child: Text(_message!)),
        const Text('Lịch sử điểm danh', style: TextStyle(fontSize: 20)),
        if (_history.isEmpty) const Text('Chưa có lượt điểm danh.'),
        for (final r in _history)
          ListTile(
            title: Text('${r['title']}'),
            subtitle: Text(
              '${r['checkedInUtc']} UTC • ${(r['distanceMeters'] as num).round()} m',
            ),
          ),
      ],
    ),
  );
}
