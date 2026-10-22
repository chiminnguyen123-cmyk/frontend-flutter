import 'dart:convert';
import 'dart:async';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class Api {
  // Session token stays in memory and is removed on logout.
  static String? token;
  static String get baseUrl {
    final value = (dotenv.env['BASE_URL'] ?? 'http://10.0.2.2:5041/api/')
        .trim();
    return value.endsWith('/') ? value : '$value/';
  }

  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };
  static Future<dynamic> call(
    String method,
    String path, [
    Object? body,
  ]) async {
    final request = http.Request(method, Uri.parse('$baseUrl$path'));
    request.headers.addAll(headers);
    if (body != null) request.body = jsonEncode(body);
    late http.Response response;
    try {
      response = await (() async => http.Response.fromStream(
        await request.send(),
      ))().timeout(const Duration(seconds: 25));
    } on http.ClientException {
      throw Exception(
        'Không kết nối được máy chủ. Kiểm tra API đang chạy và kết nối USB/Wi-Fi. Nếu vừa cắm lại USB, cần nối lại cổng 5041.',
      );
    } on TimeoutException {
      throw Exception(
        'Máy chủ phản hồi quá lâu. Kiểm tra kết nối rồi thử lại.',
      );
    }
    dynamic data;
    try {
      data = jsonDecode(response.body);
    } catch (_) {
      data = null;
    }
    if (response.statusCode >= 400) {
      throw Exception(
        data is Map
            ? data['message'] ?? data['title'] ?? 'Lỗi ${response.statusCode}'
            : 'Lỗi ${response.statusCode}',
      );
    }
    return data;
  }
}
