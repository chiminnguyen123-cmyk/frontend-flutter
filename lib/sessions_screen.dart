import 'dart:async';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'api.dart';
import 'location_service.dart';

class SessionsScreen extends StatefulWidget {
  const SessionsScreen({super.key, required this.canManage});
  final bool canManage;
  @override
  State<SessionsScreen> createState() => _SessionsScreenState();
}

class _SessionsScreenState extends State<SessionsScreen> {
  final _title = TextEditingController(),
      _radius = TextEditingController(text: '100'),
      _minutes = TextEditingController(text: '5');
  bool _busy = false;
  String? _error;
  List<dynamic> _sessions = [];
  Map<String, dynamic>? _created;
  Timer? _clock;
  String? _location;
  int get _remaining => _created == null
      ? 0
      : DateTime.parse(_created!['expiresUtc'])
            .difference(DateTime.now())
            .inSeconds;
  @override
  void initState() {
    super.initState();
    _load();
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _created != null) setState(() {});
    });
  }

  Future<void> _load() async {
    try {
      final data = await Api.call('GET', 'attendance/sessions');
      if (mounted) setState(() => _sessions = data);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    }
  }

  Future<void> _create() async {
    if (!widget.canManage || _busy) return;
    final radius = int.tryParse(_radius.text),
        minutes = int.tryParse(_minutes.text);
    if (_title.text.trim().isEmpty ||
        radius == null ||
        radius < 20 ||
        radius > 1000 ||
        minutes == null ||
        minutes < 1 ||
        minutes > 30) {
      setState(
        () => _error =
            'Nhập tên phiên, bán kính 20–1000 m và thời hạn 1–30 phút.',
      );
      return;
    }
    final consent = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Dùng vị trí làm tâm điểm danh?'),
        content: const Text(
          'Máy chủ lưu vị trí hiện tại làm tâm và bán kính kiểm tra cho phiên này.',
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
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final p = await currentPosition();
      if (p.accuracy > radius) {
        throw Exception('Vị trí tâm chưa đủ chính xác. Hãy thử lại.');
      }
      final data = await Api.call('POST', 'attendance/sessions', {
        'title': _title.text.trim(),
        'minutes': minutes,
        'radiusMeters': radius,
        'latitude': p.latitude,
        'longitude': p.longitude,
      });
      if (mounted) {
        setState(() {
          _created = Map<String, dynamic>.from(data);
          _location =
              'Tâm phiên: ${p.latitude.toStringAsFixed(5)}, ${p.longitude.toStringAsFixed(5)}\nĐộ chính xác GPS: ${p.accuracy.round()} m • Bán kính: $radius m';
        });
      }
      await _load();
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _close(int id) async {
    if (!widget.canManage || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await Api.call('POST', 'attendance/sessions/$id/close');
      if (_created?['id'] == id && mounted) setState(() => _created = null);
      await _load();
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _records(int id) async {
    try {
      final data =
          await Api.call('GET', 'attendance/sessions/$id/records') as List;
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('Danh sách đã điểm danh'),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (data.isEmpty) const Text('Chưa có lượt điểm danh.'),
                  for (final r in data)
                    ListTile(
                      title: Text('${r['studentCode']} – ${r['fullName']}'),
                      subtitle: Text('${r['checkedInUtc']} UTC'),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c),
              child: const Text('Đóng'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    }
  }

  @override
  void dispose() {
    _clock?.cancel();
    _title.dispose();
    _radius.dispose();
    _minutes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Quản lý phiên điểm danh'),
      actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))],
    ),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (widget.canManage) ...[
          TextField(
            controller: _title,
            maxLength: 100,
            decoration: const InputDecoration(labelText: 'Tên lớp / phiên'),
          ),
          TextField(
            controller: _radius,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Bán kính (m)'),
          ),
          TextField(
            controller: _minutes,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Hết hạn sau (phút)'),
          ),
          FilledButton(
            onPressed: _busy ? null : _create,
            child: Text(_busy ? 'Đang xử lý...' : 'Chia sẻ vị trí và tạo QR'),
          ),
        ],
        if (_error != null)
          Text(_error!, style: const TextStyle(color: Colors.red)),
        if (_created != null) ...[
          if (_location != null) Text(_location!),
          if (_remaining > 0) ...[
            Center(
              child: QrImageView(
                data: _created!['payload'],
                size: 260,
                backgroundColor: Colors.white,
              ),
            ),
            Text(
              'QR còn hiệu lực: ${_remaining ~/ 60} phút ${_remaining % 60} giây',
            ),
            const Text(
              'Sinh viên dùng điện thoại khác quét mã này và chia sẻ vị trí trong bán kính phiên.',
            ),
          ] else
            const Text(
              'QR đã hết hạn. Tạo phiên mới để tiếp tục điểm danh.',
              style: TextStyle(color: Colors.red),
            ),
          Text(
            'Hết hạn: ${_created!['expiresUtc']} UTC. QR chỉ hiện tại lần tạo phiên.',
          ),
        ],
        for (final s in _sessions)
          Card(
            child: ListTile(
              title: Text('${s['title']}'),
              subtitle: Text(
                s['closed'] == true
                    ? 'Đã đóng'
                    : 'Hết hạn: ${s['expiresUtc']} UTC',
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Xem điểm danh',
                    onPressed: () => _records(s['id']),
                    icon: const Icon(Icons.list),
                  ),
                  if (widget.canManage)
                    IconButton(
                      tooltip: 'Đóng phiên',
                      onPressed: _busy || s['closed'] == true
                          ? null
                          : () => _close(s['id']),
                      icon: const Icon(Icons.stop_circle),
                    ),
                ],
              ),
            ),
          ),
      ],
    ),
  );
}
