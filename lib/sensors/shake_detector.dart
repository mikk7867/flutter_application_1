import 'dart:async';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';

class ShakeDetector {
  final void Function() onShake;
  final double threshold;
  StreamSubscription? _subscription;

  ShakeDetector({required this.onShake, this.threshold = 15.0});

  void startListening() {
    _subscription = accelerometerEventStream().listen((event) {
      final gForce = sqrt(
        event.x * event.x + event.y * event.y + event.z * event.z,
      );

      if (gForce > threshold) {
        onShake();
      }
    });
  }

  void stopListening() {
    _subscription?.cancel();
  }
}
