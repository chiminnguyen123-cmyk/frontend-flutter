import 'package:flutter/material.dart';

class MainHomeScreen extends StatelessWidget {
  const MainHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trang chủ'),
        backgroundColor: Colors.blue.shade200,
      ),
      body: const Center(
        child: Text('Đăng nhập thành công! Đây là màn hình chính.'),
      ),
    );
  }
}