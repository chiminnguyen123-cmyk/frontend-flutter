class Student {
  final int id;
  final String studentCode;
  final String fullName;
  final String status;

  Student({
    required this.id,
    required this.studentCode,
    required this.fullName,
    required this.status,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'],
      studentCode: json['studentCode'],
      fullName: json['fullName'],
      status: json['status'] ?? 'Vắng',
    );
  }

  Map<String, dynamic> toJson() => {
    "id": id,
    "studentCode": studentCode,
    "fullName": fullName,
    "status": status,
  };
}