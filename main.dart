import 'package:flutter/material.dart';
import 'package:greenhouse_monitor/screens/greenhouse_screen.dart';
import 'package:greenhouse_monitor/services/fake_api.dart';
import 'package:greenhouse_monitor/services/greenhouse_service.dart';

// Параметри демонстрації (без зміни коду віджетів):
//   flutter run --dart-define=FAILURE_RATE=0.5
//   flutter run --dart-define=SENSOR_FAILURE_RATE=0.4
//   flutter run --dart-define=EMPTY=true
const String _failureRateRaw = String.fromEnvironment('FAILURE_RATE');
const String _sensorFailureRateRaw =
    String.fromEnvironment('SENSOR_FAILURE_RATE');
const bool _empty = bool.fromEnvironment('EMPTY');

void main() {
  final service = GreenhouseService(
    api: FakeApi(failureRate: double.tryParse(_failureRateRaw) ?? 0.0),
    emptyGreenhouse: _empty,
  );

  runApp(
    GreenhouseApp(
      service: service,
      sensorFailureRate: double.tryParse(_sensorFailureRateRaw) ?? 0.08,
    ),
  );
}

class GreenhouseApp extends StatelessWidget {
  const GreenhouseApp({
    super.key,
    required this.service,
    this.sensorFailureRate = 0.08,
  });

  final GreenhouseService service;
  final double sensorFailureRate;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Моніторинг теплиці',
      theme: ThemeData(colorSchemeSeed: Colors.green, useMaterial3: true),
      home: GreenhouseScreen(
        service: service,
        sensorFailureRate: sensorFailureRate,
      ),
    );
  }
}
