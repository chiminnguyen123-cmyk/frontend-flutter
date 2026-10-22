import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

class PressureScreen extends StatefulWidget {
  const PressureScreen({super.key});
  @override
  State<PressureScreen> createState() => _PressureScreenState();
}
class _PressureScreenState extends State<PressureScreen> with WidgetsBindingObserver {
  StreamSubscription<BarometerEvent>? _subscription;
  Timer? _timeout;
  double? _pressure;
  double? _min, _max;
  String? _error;
  bool _running = false;
  @override
  void initState() { super.initState(); WidgetsBinding.instance.addObserver(this); }
  Future<void> _start() async {
    await _stop();
    if (!mounted) return;
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android && defaultTargetPlatform != TargetPlatform.iOS) {
      setState(() => _error = 'Đo áp suất cần điện thoại Android/iOS có cảm biến khí áp.'); return;
    }
    setState(() { _running = true; _error = null; _pressure = null; _min = null; _max = null; });
    try {
      _subscription = barometerEventStream(samplingPeriod: const Duration(seconds: 1)).listen((event) {
        if (!mounted || !_running || !event.pressure.isFinite) return;
        _timeout?.cancel();
        setState(() { _pressure = event.pressure; _min = _min == null || event.pressure < _min! ? event.pressure : _min; _max = _max == null || event.pressure > _max! ? event.pressure : _max; });
      }, onError: (Object e) { _unsupported(); }, cancelOnError: true);
      _timeout = Timer(const Duration(seconds: 10), _unsupported);
    } catch (_) { _unsupported(); }
  }
  void _unsupported() {
    _stop();
    if (mounted) setState(() => _error = 'Không đọc được cảm biến áp suất. Thiết bị có thể không hỗ trợ.');
  }
  Future<void> _stop() async {
    _timeout?.cancel();
    await _subscription?.cancel();
    _subscription = null;
    if (mounted) setState(() => _running = false);
  }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) { if (state != AppLifecycleState.resumed) _stop(); }
  @override
  void dispose() { WidgetsBinding.instance.removeObserver(this); _timeout?.cancel(); _subscription?.cancel(); super.dispose(); }
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Đo áp suất khí quyển')),
    body: Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.speed, size: 80),
      Text(_pressure == null ? 'Chưa có số đo' : '${_pressure!.toStringAsFixed(2)} hPa', style: const TextStyle(fontSize: 36)),
      if (_pressure != null) Text('${(_pressure! / 10).toStringAsFixed(3)} kPa'),
      if (_min != null) Text('Thấp nhất: ${_min!.toStringAsFixed(2)} • Cao nhất: ${_max!.toStringAsFixed(2)} hPa'),
      if (_error != null) Text(_error!, textAlign: TextAlign.center),
      const Text('Số đo trực tiếp từ cảm biến thiết bị; chỉ đọc khi bật đo, không gửi lên máy chủ.'),
      const SizedBox(height: 20),
      FilledButton(onPressed: _running ? _stop : _start, child: Text(_running ? 'Dừng đo' : 'Bắt đầu đo')),
    ]))),
  );
}
