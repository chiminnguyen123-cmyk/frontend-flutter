import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:nguyenhuytruongbai6/api.dart';

void main() {
  test('API normalizes base URL and attaches session token', () {
    dotenv.loadFromString(envString: 'BASE_URL=http://localhost:5041/api');
    Api.token = 'session';
    expect(Api.baseUrl, 'http://localhost:5041/api/');
    expect(Api.headers['Authorization'], 'Bearer session');
    Api.token = null;
    expect(Api.headers.containsKey('Authorization'), isFalse);
  });
}

