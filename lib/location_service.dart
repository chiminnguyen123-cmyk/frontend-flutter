import 'package:geolocator/geolocator.dart';

Future<Position> currentPosition() async {
  if (!await Geolocator.isLocationServiceEnabled()) {
    throw Exception('Hãy bật dịch vụ vị trí trên thiết bị.');
  }
  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }
  if (permission == LocationPermission.denied ||
      permission == LocationPermission.deniedForever) {
    throw Exception(
      'Chưa cấp quyền vị trí. Bạn có thể cấp trong cài đặt ứng dụng.',
    );
  }
  final p = await Geolocator.getCurrentPosition(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.high,
      timeLimit: Duration(seconds: 20),
    ),
  );
  if (p.isMocked) throw Exception('Không chấp nhận vị trí giả lập.');
  if (!p.latitude.isFinite ||
      !p.longitude.isFinite ||
      !p.accuracy.isFinite ||
      p.accuracy < 0) {
    throw Exception('Vị trí chưa hợp lệ. Hãy thử lại ở nơi thoáng hơn.');
  }
  return p;
}
