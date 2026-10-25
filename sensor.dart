/// Тип вимірювання датчика.
enum SensorKind { temperature, humidity, light }

/// Опис датчика теплиці.
class Sensor {
  const Sensor({
    required this.id,
    required this.name,
    required this.kind,
    required this.unit,
    required this.initialValue,
    required this.noise,
    required this.minPossible,
    required this.maxPossible,
  });

  final String id;
  final String name;
  final SensorKind kind;
  final String unit;

  /// Типове («нормальне») значення, навколо якого коливаються показання.
  final double initialValue;

  /// Амплітуда випадкових коливань за один крок.
  final double noise;

  /// Фізичні межі показань датчика.
  final double minPossible;
  final double maxPossible;

  /// Значення для відображення (освітленість — без десяткових).
  String format(double value) =>
      value.toStringAsFixed(kind == SensorKind.light ? 0 : 1);
}
