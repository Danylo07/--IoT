import 'dart:async';
import 'dart:math';

import 'package:greenhouse_monitor/models/sensor.dart';
import 'package:greenhouse_monitor/models/sensor_reading.dart';

/// Збій окремого датчика (передається в потік через addError).
class SensorFailure implements Exception {
  const SensorFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Імітує датчики: кожен має власний потік і власний таймер.
///
/// Пауза зупиняє таймери (джерело подій), а не лише приховує дані в UI.
/// Збій датчика передається через addError і не закриває потік.
class SensorSimulator {
  SensorSimulator({double failureRate = 0.08, Random? random})
      : _failureRate = failureRate,
        _random = random ?? Random();

  final double _failureRate;
  final Random _random;

  final Map<String, StreamController<SensorReading>> _controllers = {};
  final Map<String, Timer> _timers = {};
  final Map<String, double> _values = {};

  List<Sensor> _sensors = const [];
  bool _paused = false;
  bool _disposed = false;

  bool get isPaused => _paused;

  /// Потік показань датчика (broadcast: на нього підписані і картка,
  /// і екран, який стежить за порогами).
  Stream<SensorReading> streamFor(String sensorId) {
    final controller = _controllers[sensorId];
    if (controller == null) {
      throw ArgumentError.value(sensorId, 'sensorId', 'Невідомий датчик');
    }
    return controller.stream;
  }

  /// Запускає оновлення для переданих датчиків.
  void start(List<Sensor> sensors) {
    if (_disposed) return;
    _stopTimers();
    _closeControllers();
    _sensors = sensors;
    _paused = false;
    for (final sensor in sensors) {
      _controllers[sensor.id] = StreamController<SensorReading>.broadcast();
      _values[sensor.id] = sensor.initialValue;
      _schedule(sensor);
    }
  }

  /// Зупиняє таймери: нових подій немає, доки не викликано [resume].
  void pause() {
    if (_paused || _disposed) return;
    _paused = true;
    _stopTimers();
  }

  /// Відновлює оновлення.
  void resume() {
    if (!_paused || _disposed) return;
    _paused = false;
    for (final sensor in _sensors) {
      _schedule(sensor);
    }
  }

  /// Зупиняє таймери та закриває всі потоки.
  void dispose() {
    _disposed = true;
    _paused = true;
    _stopTimers();
    _closeControllers();
  }

  void _schedule(Sensor sensor) {
    _timers[sensor.id]?.cancel();
    final delay = Duration(milliseconds: 1000 + _random.nextInt(1001));
    _timers[sensor.id] = Timer(delay, () => _tick(sensor));
  }

  void _tick(Sensor sensor) {
    final controller = _controllers[sensor.id];
    if (_paused || _disposed || controller == null || controller.isClosed) {
      return;
    }

    if (_random.nextDouble() < _failureRate) {
      // Збій передається як подія помилки; потік залишається відкритим.
      controller.addError(
        SensorFailure('Датчик «${sensor.name}» не відповідає'),
      );
    } else {
      controller.add(
        SensorReading(
          sensorId: sensor.id,
          value: _nextValue(sensor),
          timestamp: DateTime.now(),
        ),
      );
    }
    _schedule(sensor);
  }

  double _nextValue(Sensor sensor) {
    final previous = _values[sensor.id] ?? sensor.initialValue;
    final pull = (sensor.initialValue - previous) * 0.05; // повернення до норми
    final noise = (_random.nextDouble() * 2 - 1) * sensor.noise;
    final spike = _random.nextDouble() < 0.05
        ? (_random.nextBool() ? 1 : -1) * sensor.noise * 4
        : 0.0;

    final raw = (previous + pull + noise + spike)
        .clamp(sensor.minPossible, sensor.maxPossible)
        .toDouble();
    final value = (raw * 10).round() / 10;
    _values[sensor.id] = value;
    return value;
  }

  void _stopTimers() {
    for (final timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
  }

  void _closeControllers() {
    for (final controller in _controllers.values) {
      unawaited(controller.close());
    }
    _controllers.clear();
    _values.clear();
  }
}
