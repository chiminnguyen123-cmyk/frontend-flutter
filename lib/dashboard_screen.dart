import 'package:flutter/material.dart';

import 'api.dart';
import 'admin_screen.dart';
import 'student_screen.dart';
import 'sessions_screen.dart';
import 'accounts_screen.dart';
import 'login_screen.dart';
import 'motion_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, required this.role});
  final String role;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(switch (role) {
        'Admin' => 'Quản trị',
        'Employee' => 'Giảng viên',
        'User' => 'Sinh viên',
        _ => 'Vai trò không được hỗ trợ',
      }),
      actions: [
        IconButton(
          tooltip: 'Đăng xuất',
          icon: const Icon(Icons.logout),
          onPressed: () {
            Api.token = null;
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
              (_) => false,
            );
          },
        ),
      ],
    ),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        if (role == 'Admin') ...[
          _entry(
            context,
            'Quản lý sinh viên (CRUD)',
            Icons.people,
            const AdminScreen(),
          ),
          _entry(
            context,
            'Tài khoản, quyền và liên kết sinh viên',
            Icons.manage_accounts,
            const AccountsScreen(),
          ),
        ],
        if (role == 'Admin')
          _entry(
            context,
            'Xem các phiên và kết quả điểm danh',
            Icons.list_alt,
            const SessionsScreen(canManage: false),
          ),
        if (role == 'Employee')
          _entry(
            context,
            'Tạo phiên QR, đóng phiên và xem điểm danh',
            Icons.qr_code,
            const SessionsScreen(canManage: true),
          ),
        if (role == 'User')
          _entry(
            context,
            'Quét QR/Barcode, chia sẻ vị trí và xem lịch sử',
            Icons.qr_code_scanner,
            const StudentScreen(),
          ),
        if (role == 'Employee')
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text('Giảng viên quản lý các phiên điểm danh do mình tạo.'),
          ),
        _entry(
          context,
          'Đo chuyển động',
          Icons.vibration,
          const MotionScreen(),
        ),
      ],
    ),
  );
  Widget _entry(BuildContext c, String text, IconData icon, Widget page) =>
      Card(
        child: ListTile(
          leading: Icon(icon),
          title: Text(text),
          trailing: const Icon(Icons.chevron_right),
          onTap: () =>
              Navigator.push(c, MaterialPageRoute(builder: (_) => page)),
        ),
      );
}
