import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

class MotionScreen extends StatefulWidget {
  const MotionScreen({super.key});
  @override
  State<MotionScreen> createState() => _MotionScreenState();
}

class _MotionScreenState extends State<MotionScreen>
    with WidgetsBindingObserver {
  StreamSubscription<UserAccelerometerEvent>? _subscription;
  Timer? _timeout;
  bool _running = false, _moving = false;
  double? _x, _y, _z, _magnitude;
  double _peak = 0;
  String? _error;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  Future<void> _start() async {
    _stop();
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS)) {
      setState(
        () => _error = 'Hãy dùng điện thoại Android/iOS có cảm biến gia tốc.',
      );
      return;
    }
    final generation = _generation;
    setState(() {
      _running = true;
      _error = null;
      _x = _y = _z = _magnitude = null;
      _peak = 0;
      _moving = false;
    });
    void unavailable() {
      if (!mounted || generation != _generation) return;
      _stop();
      setState(
        () => _error = 'Không nhận được dữ liệu chuyển động. Thiết bị có thể không hỗ trợ cảm biến.',
      );
    }

    try {
      _timeout = Timer(const Duration(seconds: 5), unavailable);
      _subscription =
          userAccelerometerEventStream(
            samplingPeriod: const Duration(milliseconds: 100),
          ).listen(
            (event) {
              if (!mounted || !_running || generation != _generation) return;
              if (!event.x.isFinite || !event.y.isFinite || !event.z.isFinite) {
                return;
              }
              _timeout?.cancel();
              _timeout = Timer(const Duration(seconds: 5), unavailable);
              final magnitude = sqrt(
                event.x * event.x + event.y * event.y + event.z * event.z,
              );
              setState(() {
                _x = event.x;
                _y = event.y;
                _z = event.z;
                _magnitude = magnitude;
                _peak = max(_peak, magnitude);
                // Separate entry/exit thresholds reduce flicker near the boundary.
                if (magnitude >= 0.8) {
                  _moving = true;
                } else if (magnitude <= 0.3) {
                  _moving = false;
                }
              });
            },
            onError: (Object _) => unavailable(),
            onDone: unavailable,
            cancelOnError: true,
          );
    } catch (_) {
      unavailable();
    }
  }

  void _stop() {
    _generation++;
    _timeout?.cancel();
    final subscription = _subscription;
    _subscription = null;
    if (subscription != null) unawaited(subscription.cancel());
    if (mounted) setState(() => _running = false);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _stop();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _generation++;
    _timeout?.cancel();
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Đo chuyển động')),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Icon(Icons.vibration, size: 72),
        Text(
          _magnitude == null
              ? 'Chưa có số đo'
              : '${_magnitude!.toStringAsFixed(2)} m/s²',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 32),
        ),
        if (_magnitude != null) ...[
          Text(
            !_running
                ? 'Đã dừng đo'
                : _moving
                ? 'Đang chuyển động'
                : 'Gần đứng yên',
            textAlign: TextAlign.center,
          ),
          Text(
            'X: ${_x!.toStringAsFixed(2)} • Y: ${_y!.toStringAsFixed(2)} • Z: ${_z!.toStringAsFixed(2)} m/s²',
          ),
          Text('Gia tốc lớn nhất: ${_peak.toStringAsFixed(2)} m/s²'),
        ],
        const SizedBox(height: 16),
        const Text(
          'Gia tốc đã loại trọng lực. Đặt điện thoại trên bàn, sau đó nhấc hoặc di chuyển nhẹ để thử. Đây là gia tốc, không phải tốc độ di chuyển.',
        ),
        const Text(
          'Chỉ đọc khi bật đo; dừng khi app ra nền. Số đo không gửi lên máy chủ.',
        ),
        if (_error != null)
          Text(_error!, style: const TextStyle(color: Colors.red)),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _running ? _stop : _start,
          child: Text(_running ? 'Dừng đo' : 'Bắt đầu đo'),
        ),
      ],
    ),
  );
}
