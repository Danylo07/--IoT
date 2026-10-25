/// Допустимий діапазон показань датчика.
class Threshold {
  const Threshold({
    required this.sensorId,
    required this.min,
    required this.max,
  });

  final String sensorId;
  final double min;
  final double max;

  /// true, якщо значення виходить за поріг.
  bool isOutside(double value) => value < min || value > max;
}
