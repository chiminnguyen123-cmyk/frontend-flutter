import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nguyenhuytruongbai6/login_screen.dart';
import 'package:nguyenhuytruongbai6/dashboard_screen.dart';
import 'package:nguyenhuytruongbai6/motion_screen.dart';

void main() {
  testWidgets('Admin only sees administration and results', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: DashboardScreen(role: 'Admin')));
    expect(find.text('Quản trị'), findsOneWidget);
    expect(find.text('Quản lý sinh viên (CRUD)'), findsOneWidget);
    expect(find.text('Xem các phiên và kết quả điểm danh'), findsOneWidget);
    expect(find.text('Tạo phiên QR, đóng phiên và xem điểm danh'), findsNothing);
    expect(find.text('Quét QR/Barcode, chia sẻ vị trí và xem lịch sử'), findsNothing);
  });
  testWidgets('Student cannot access administration or create sessions', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: DashboardScreen(role: 'User')));
    expect(find.text('Sinh viên'), findsOneWidget);
    expect(find.text('Quét QR/Barcode, chia sẻ vị trí và xem lịch sử'), findsOneWidget);
    expect(find.text('Quản lý sinh viên (CRUD)'), findsNothing);
    expect(find.text('Tài khoản, quyền và liên kết sinh viên'), findsNothing);
    expect(find.text('Tạo phiên QR, đóng phiên và xem điểm danh'), findsNothing);
  });
  testWidgets('Login hides password until eye is tapped', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
    expect(
      tester.widgetList<TextField>(find.byType(TextField)).last.obscureText,
      isTrue,
    );
    await tester.tap(find.byTooltip('Hiện mật khẩu'));
    await tester.pump();
    expect(
      tester.widgetList<TextField>(find.byType(TextField)).last.obscureText,
      isFalse,
    );
  });
  testWidgets(
    'Employee sees session workflow and motion, without student CRUD',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: DashboardScreen(role: 'Employee')),
      );
      expect(
        find.text('Tạo phiên QR, đóng phiên và xem điểm danh'),
        findsOneWidget,
      );
      expect(find.text('Đo chuyển động'), findsOneWidget);
      expect(find.text('Giảng viên'), findsOneWidget);
      expect(find.text('Tài khoản, quyền và liên kết sinh viên'), findsNothing);
      expect(find.text('Quét QR/Barcode, chia sẻ vị trí và xem lịch sử'), findsNothing);
      expect(find.text('Quản lý sinh viên (CRUD)'), findsNothing);
    },
  );
  testWidgets('Motion never invents an initial sensor reading', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: MotionScreen()));
    expect(find.text('Chưa có số đo'), findsOneWidget);
    expect(find.text('Bắt đầu đo'), findsOneWidget);
    expect(find.textContaining('1013'), findsNothing);
  });
}
