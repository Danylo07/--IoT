import 'package:greenhouse_monitor/models/daily_summary.dart';
import 'package:greenhouse_monitor/models/sensor.dart';
import 'package:greenhouse_monitor/models/threshold.dart';

/// Усе, що завантажується під час відкриття екрана.
class GreenhouseData {
  const GreenhouseData({
    required this.sensors,
    required this.thresholds,
    required this.summary,
  });

  final List<Sensor> sensors;

  /// Порогові значення за id датчика.
  final Map<String, Threshold> thresholds;
  final DailySummary summary;

  bool get isEmpty => sensors.isEmpty;
}
