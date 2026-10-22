import 'package:flutter/material.dart';

import 'api.dart';

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});
  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  List<dynamic> _accounts = [], _students = [];
  String? _error;
  bool _busy = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final accounts = await Api.call('GET', 'accounts');
      final students = await Api.call('GET', 'Students');
      if (mounted) {
        setState(() {
          _accounts = accounts;
          _students = students;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    }
  }

  Future<void> _update(String path, Object body) async {
    setState(() => _busy = true);
    try {
      await Api.call('PUT', path, body);
      await _load();
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _link(dynamic a) async {
    final id = await showDialog<int>(
      context: context,
      builder: (c) => SimpleDialog(
        title: const Text('Chọn sinh viên cho tài khoản'),
        children: [
          for (final s in _students)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(c, s['id']),
              child: Text('${s['studentCode']} – ${s['fullName']}'),
            ),
        ],
      ),
    );
    if (id != null && mounted) {
      await _update('accounts/${a['id']}/student', {'studentId': id});
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Tài khoản và phân quyền'),
      actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))],
    ),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Admin hiện có được bảo toàn. Chỉ Admin được gán giảng viên/sinh viên và liên kết mã sinh viên.',
        ),
        if (_error != null)
          Text(_error!, style: const TextStyle(color: Colors.red)),
        for (final a in _accounts)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${a['userName']} • ${(a['roles'] as List).join(', ')}'),
                  if (!(a['roles'] as List).contains('Admin'))
                    Wrap(
                      spacing: 12,
                      children: [
                        TextButton(
                          onPressed: _busy
                              ? null
                              : () => _update('accounts/${a['id']}/role', {
                                  'role': 'Employee',
                                }),
                          child: const Text('Gán giảng viên'),
                        ),
                        TextButton(
                          onPressed: _busy
                              ? null
                              : () => _update('accounts/${a['id']}/role', {
                                  'role': 'User',
                                }),
                          child: const Text('Gán sinh viên'),
                        ),
                        if ((a['roles'] as List).contains('User'))
                          TextButton(
                            onPressed: _busy || a['studentId'] != null
                                ? null
                                : () => _link(a),
                            child: Text(
                              a['studentId'] == null
                                  ? 'Liên kết sinh viên'
                                  : 'Đã liên kết SV #${a['studentId']}',
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ),
      ],
    ),
  );
}
