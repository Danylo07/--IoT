import 'dart:async';

import 'package:greenhouse_monitor/models/daily_summary.dart';
import 'package:greenhouse_monitor/models/greenhouse_data.dart';
import 'package:greenhouse_monitor/models/sensor.dart';
import 'package:greenhouse_monitor/models/threshold.dart';
import 'package:greenhouse_monitor/services/fake_api.dart';

/// Помилка початкового завантаження з повідомленням для користувача.
class GreenhouseLoadException implements Exception {
  const GreenhouseLoadException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Сервіс даних теплиці (імітація мережі через [FakeApi]).
class GreenhouseService {
  GreenhouseService({required FakeApi api, this.emptyGreenhouse = false})
      : _api = api;

  final FakeApi _api;

  /// Якщо true, сервер повертає порожній список датчиків.
  final bool emptyGreenhouse;

  /// Спільний тайм-аут початкового завантаження.
  static const Duration loadTimeout = Duration(seconds: 3);

  static const List<Sensor> _sensors = [
    Sensor(
      id: 'temp',
      name: 'Температура',
      kind: SensorKind.temperature,
      unit: '°C',
      initialValue: 24,
      noise: 1.2,
      minPossible: 5,
      maxPossible: 45,
    ),
    Sensor(
      id: 'hum',
      name: 'Вологість',
      kind: SensorKind.humidity,
      unit: '%',
      initialValue: 65,
      noise: 4,
      minPossible: 10,
      maxPossible: 100,
    ),
    Sensor(
      id: 'light',
      name: 'Освітленість',
      kind: SensorKind.light,
      unit: 'лк',
      initialValue: 6000,
      noise: 700,
      minPossible: 0,
      maxPossible: 15000,
    ),
  ];

  static const List<Threshold> _thresholds = [
    Threshold(sensorId: 'temp', min: 18, max: 28),
    Threshold(sensorId: 'hum', min: 50, max: 80),
    Threshold(sensorId: 'light', min: 3000, max: 9000),
  ];

  Future<List<Sensor>> fetchSensors() {
    return _api.request<List<Sensor>>(
      () => emptyGreenhouse ? const <Sensor>[] : _sensors,
      delayMs: 700,
    );
  }

  Future<Map<String, Threshold>> fetchThresholds() {
    return _api.request<Map<String, Threshold>>(
      () => {for (final t in _thresholds) t.sensorId: t},
      delayMs: 900,
    );
  }

  Future<DailySummary> fetchDailySummary() {
    return _api.request<DailySummary>(
      () => const DailySummary(
        avgTemperature: 23.4,
        avgHumidity: 66.0,
        avgLight: 5800,
        alertsCount: 3,
      ),
      delayMs: 1200,
    );
  }

  /// Паралельно завантажує датчики, пороги та підсумок за добу.
  /// Якщо відповіді немає довше за [loadTimeout] — тайм-аут.
  Future<GreenhouseData> loadAll() async {
    try {
      final (sensors, thresholds, summary) = await (
        fetchSensors(),
        fetchThresholds(),
        fetchDailySummary(),
      ).wait.timeout(loadTimeout);

      return GreenhouseData(
        sensors: sensors,
        thresholds: thresholds,
        summary: summary,
      );
    } on TimeoutException {
      throw const GreenhouseLoadException('Сервер не відповів за 3 с');
    } catch (_) {
      throw const GreenhouseLoadException('Сервер недоступний');
    }
  }
}
