import 'dart:async';

import 'package:flutter/material.dart';
import 'package:greenhouse_monitor/models/greenhouse_data.dart';
import 'package:greenhouse_monitor/models/sensor.dart';
import 'package:greenhouse_monitor/models/sensor_reading.dart';
import 'package:greenhouse_monitor/models/threshold.dart';
import 'package:greenhouse_monitor/services/greenhouse_service.dart';
import 'package:greenhouse_monitor/services/sensor_simulator.dart';
import 'package:greenhouse_monitor/widgets/sensor_card.dart';
import 'package:greenhouse_monitor/widgets/state_views.dart';
import 'package:greenhouse_monitor/widgets/summary_card.dart';

/// Панель моніторингу теплиці.
class GreenhouseScreen extends StatefulWidget {
  const GreenhouseScreen({
    super.key,
    required this.service,
    this.sensorFailureRate = 0.08,
  });

  final GreenhouseService service;

  /// Імовірність збою окремого показання датчика.
  final double sensorFailureRate;

  @override
  State<GreenhouseScreen> createState() => _GreenhouseScreenState();
}

class _GreenhouseScreenState extends State<GreenhouseScreen> {
  /// Мінімальний інтервал між SnackBar для одного датчика.
  static const Duration _alertCooldown = Duration(seconds: 10);

  late final SensorSimulator _simulator;

  /// Future створюється в initState/_retry, а не в build().
  late Future<GreenhouseData> _dataFuture;

  final List<StreamSubscription<SensorReading>> _subscriptions = [];
  final Map<String, DateTime> _lastAlertAt = {};
  bool _monitoring = false;

  @override
  void initState() {
    super.initState();
    _simulator = SensorSimulator(failureRate: widget.sensorFailureRate);
    _dataFuture = _load();
  }

  Future<GreenhouseData> _load() async {
    final data = await widget.service.loadAll();
    // Після await віджет міг бути видалений з дерева.
    if (!mounted) return data;
    _startMonitoring(data);
    return data;
  }

  void _startMonitoring(GreenhouseData data) {
    _cancelSubscriptions();
    _lastAlertAt.clear();
    _simulator.start(data.sensors);

    for (final sensor in data.sensors) {
      final threshold = data.thresholds[sensor.id];
      final subscription = _simulator.streamFor(sensor.id).listen(
            (reading) => _checkThreshold(sensor, threshold, reading),
            // Збій датчика показує його картка, тут помилку ігноруємо.
            onError: (Object error) {},
          );
      _subscriptions.add(subscription);
    }

    setState(() => _monitoring = data.sensors.isNotEmpty);
  }

  void _checkThreshold(
    Sensor sensor,
    Threshold? threshold,
    SensorReading reading,
  ) {
    if (threshold == null || !threshold.isOutside(reading.value)) return;

    // SnackBar для одного датчика — не частіше ніж раз на 10 с.
    final last = _lastAlertAt[sensor.id];
    if (last != null && reading.timestamp.difference(last) < _alertCooldown) {
      return;
    }
    _lastAlertAt[sensor.id] = reading.timestamp;

    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            '${sensor.name}: ${sensor.format(reading.value)} ${sensor.unit} '
            '— поза нормою (${sensor.format(threshold.min)}–'
            '${sensor.format(threshold.max)})',
          ),
        ),
      );
  }

  void _togglePause() {
    setState(() {
      if (_simulator.isPaused) {
        _simulator.resume();
      } else {
        _simulator.pause();
      }
    });
  }

  void _retry() {
    setState(() {
      _monitoring = false;
      _dataFuture = _load();
    });
  }

  void _cancelSubscriptions() {
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    _subscriptions.clear();
  }

  @override
  void dispose() {
    _cancelSubscriptions();
    _simulator.dispose(); // таймери + StreamController
    super.dispose();
  }

  String _errorMessage(Object? error) {
    if (error is GreenhouseLoadException) return error.message;
    return 'Не вдалося завантажити дані';
  }

  @override
  Widget build(BuildContext context) {
    final paused = _simulator.isPaused;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Моніторинг теплиці'),
        actions: [
          TextButton.icon(
            onPressed: _monitoring ? _togglePause : null,
            icon: Icon(paused ? Icons.play_arrow : Icons.pause),
            label: Text(paused ? 'Продовжити' : 'Пауза'),
          ),
        ],
      ),
      body: FutureBuilder<GreenhouseData>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const LoadingView();
          }
          if (snapshot.hasError) {
            return ErrorView(
              message: _errorMessage(snapshot.error),
              onRetry: _retry,
            );
          }
          final data = snapshot.requireData;
          if (data.isEmpty) {
            return EmptyView(onRefresh: _retry);
          }
          return _buildDashboard(data, paused);
        },
      ),
    );
  }

  Widget _buildDashboard(GreenhouseData data, bool paused) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (paused) const _PausedBanner(),
        SummaryCard(summary: data.summary),
        const SizedBox(height: 8),
        for (final sensor in data.sensors)
          SensorCard(
            key: ValueKey(sensor.id),
            sensor: sensor,
            threshold: data.thresholds[sensor.id],
            stream: _simulator.streamFor(sensor.id),
          ),
      ],
    );
  }
}

class _PausedBanner extends StatelessWidget {
  const _PausedBanner();

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.amber.shade100,
      child: const Padding(
        padding: EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.pause_circle_outline),
            SizedBox(width: 8),
            Text('Оновлення призупинено'),
          ],
        ),
      ),
    );
  }
}
