import 'api.dart';
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import 'models/student.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final String _baseUrl =
  (dotenv.env['BASE_URL'] ?? 'http://127.0.0.1:5041/api/').trim();

  List<Student> _students = [];
  bool _isLoading = true;
  bool _isWorking = false;
  String? _loadError;

  Uri _studentUrl([int? id]) {
    final base = _baseUrl.endsWith('/') ? _baseUrl : '$_baseUrl/';
    return Uri.parse('${base}Students${id == null ? '' : '/$id'}');
  }

  @override
  void initState() {
    super.initState();
    _fetchStudents();
  }

  void _showMessage(String message, {bool success = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: success ? Colors.green : Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  String _apiError(http.Response response) {
    try {
      final data = jsonDecode(response.body);
      if (data is Map && data['message'] != null) {
        return data['message'].toString();
      }
      if (data is Map && data['title'] != null) {
        return data['title'].toString();
      }
    } catch (_) {
      // Không có thông báo JSON.
    }
    return 'API trả về lỗi ${response.statusCode}';
  }

  Future<void> _fetchStudents() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final response = await http
          .get(_studentUrl(), headers: Api.headers)
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        throw Exception(_apiError(response));
      }

      final data = jsonDecode(response.body) as List<dynamic>;
      final loaded = data
          .map((item) => Student.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();

      if (!mounted) return;
      setState(() => _students = loaded);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadError = 'Không tải được danh sách: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Mở form. Form tự quản lý TextEditingController, và trả dữ liệu về
  // sau khi đóng; yêu cầu POST/PUT không chạy bên trong hộp thoại nữa.
  Future<void> _showStudentDialog({Student? student}) async {
    if (_isWorking) return;

    final formData = await showDialog<_StudentFormData>(
      context: context,
      builder: (_) => _StudentFormDialog(student: student),
    );
    if (!mounted || formData == null) return;

    await _saveStudent(student: student, formData: formData);
  }

  Future<void> _saveStudent({
    required Student? student,
    required _StudentFormData formData,
  }) async {
    if (_isWorking || !mounted) return;
    setState(() => _isWorking = true);

    try {
      final body = <String, dynamic>{
        'studentCode': formData.studentCode,
        'fullName': formData.fullName,
        'status': formData.status,
      };

      late final http.Response response;
      if (student == null) {
        response = await http
            .post(
          _studentUrl(),
          headers: Api.headers,
          body: jsonEncode(body),
        )
            .timeout(const Duration(seconds: 15));
      } else {
        body['id'] = student.id;
        response = await http
            .put(
          _studentUrl(student.id),
          headers: Api.headers,
          body: jsonEncode(body),
        )
            .timeout(const Duration(seconds: 15));
      }

      final ok = student == null
          ? response.statusCode == 201
          : response.statusCode == 204 || response.statusCode == 200;

      if (!ok) {
        _showMessage(_apiError(response));
        return;
      }

      _showMessage(
        student == null ? 'Thêm sinh viên thành công!' : 'Sửa sinh viên thành công!',
        success: true,
      );
      await _fetchStudents();
    } on TimeoutException {
      _showMessage('Kết nối quá thời gian. Kiểm tra API trên laptop.');
    } catch (e) {
      _showMessage('Không thể lưu sinh viên: $e');
    } finally {
      if (mounted) setState(() => _isWorking = false);
    }
  }

  Future<void> _deleteStudent(Student student) async {
    if (_isWorking) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa ${student.fullName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true || _isWorking) return;

    setState(() => _isWorking = true);
    try {
      final response = await http
          .delete(_studentUrl(student.id), headers: Api.headers)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 204 || response.statusCode == 200) {
        _showMessage('Xóa sinh viên thành công!', success: true);
        await _fetchStudents();
      } else {
        _showMessage(_apiError(response));
      }
    } on TimeoutException {
      _showMessage('Kết nối quá thời gian. Kiểm tra API trên laptop.');
    } catch (e) {
      _showMessage('Không thể xóa sinh viên: $e');
    } finally {
      if (mounted) setState(() => _isWorking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Admin - Quản lý Điểm danh',
          style: TextStyle(fontSize: 18),
        ),
        backgroundColor: Colors.red.shade200,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Tải lại danh sách',
            onPressed: _isLoading || _isWorking ? null : _fetchStudents,
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: _isWorking ? null : () => _showStudentDialog(),
        backgroundColor: Colors.red.shade200,
        tooltip: 'Thêm sinh viên',
        child: _isWorking
            ? const SizedBox(
          height: 22,
          width: 22,
          child: CircularProgressIndicator(strokeWidth: 2),
        )
            : const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off, color: Colors.red, size: 48),
              const SizedBox(height: 12),
              Text(_loadError!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _fetchStudents,
                icon: const Icon(Icons.refresh),
                label: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchStudents,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 90),
        itemCount: _students.isEmpty ? 2 : _students.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                'Tổng số sinh viên: ${_students.length}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            );
          }

          if (_students.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('Chưa có sinh viên nào. Hãy thêm mới!')),
            );
          }

          final student = _students[index - 1];
          final present = student.status == 'Có mặt';
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: present ? Colors.green : Colors.grey,
                child: const Icon(Icons.person, color: Colors.white),
              ),
              title: Text(
                student.fullName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Mã SV: ${student.studentCode}'),
                  Text(
                    'Trạng thái: ${student.status}',
                    style: TextStyle(color: present ? Colors.green : Colors.red),
                  ),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Sửa',
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: _isWorking
                        ? null
                        : () => _showStudentDialog(student: student),
                  ),
                  IconButton(
                    tooltip: 'Xóa',
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: _isWorking ? null : () => _deleteStudent(student),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// Dữ liệu form không chứa TextEditingController.
class _StudentFormData {
  const _StudentFormData({
    required this.studentCode,
    required this.fullName,
    required this.status,
  });

  final String studentCode;
  final String fullName;
  final String status;
}

// Form Thêm/Sửa có vòng đời riêng; controller chỉ dispose khi form được hủy.
class _StudentFormDialog extends StatefulWidget {
  const _StudentFormDialog({this.student});

  final Student? student;

  @override
  State<_StudentFormDialog> createState() => _StudentFormDialogState();
}

class _StudentFormDialogState extends State<_StudentFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _codeController;
  late final TextEditingController _nameController;
  late String _status;

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController(text: widget.student?.studentCode ?? '');
    _nameController = TextEditingController(text: widget.student?.fullName ?? '');
    final currentStatus = widget.student?.status ?? 'Vắng';
    _status = ['Có mặt', 'Vắng'].contains(currentStatus) ? currentStatus : 'Vắng';
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      _StudentFormData(
        studentCode: _codeController.text.trim(),
        fullName: _nameController.text.trim(),
        status: _status,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.student == null ? 'Thêm sinh viên mới' : 'Sửa thông tin sinh viên'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _codeController,
                maxLength: 20,
                decoration: const InputDecoration(
                  labelText: 'Mã sinh viên',
                  prefixIcon: Icon(Icons.badge),
                  border: OutlineInputBorder(),
                ),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Vui lòng nhập mã sinh viên'
                    : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _nameController,
                maxLength: 100,
                decoration: const InputDecoration(
                  labelText: 'Họ và tên',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Vui lòng nhập họ tên'
                    : null,
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: _status,
                decoration: const InputDecoration(
                  labelText: 'Trạng thái điểm danh',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'Có mặt', child: Text('Có mặt')),
                  DropdownMenuItem(value: 'Vắng', child: Text('Vắng')),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _status = value);
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Lưu lại'),
        ),
      ],
    );
  }
}

