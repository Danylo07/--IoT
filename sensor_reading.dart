/// Одне показання датчика.
class SensorReading {
  const SensorReading({
    required this.sensorId,
    required this.value,
    required this.timestamp,
  });

  final String sensorId;
  final double value;
  final DateTime timestamp;
}
