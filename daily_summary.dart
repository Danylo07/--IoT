/// Підсумок показань теплиці за добу.
class DailySummary {
  const DailySummary({
    required this.avgTemperature,
    required this.avgHumidity,
    required this.avgLight,
    required this.alertsCount,
  });

  final double avgTemperature;
  final double avgHumidity;
  final double avgLight;
  final int alertsCount;
}
