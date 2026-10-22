import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Đảm bảo bạn đã có file login_screen.dart trong thư mục lib/screens/
import 'login_screen.dart';

// Hàm main thêm 'async' vì cần đợi load file .env xong mới chạy app
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Đọc file .env
  await dotenv.load(fileName: ".env");



  // Khởi chạy ứng dụng
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'App Điểm Danh - Nguyễn Huy Trường', // Đổi tên để thầy Hùng chấm điểm
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      // Điều hướng màn hình đầu tiên là trang Đăng nhập
      home: const LoginScreen(),
    );
  }
}
