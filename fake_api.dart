import 'dart:math';

/// Імітація мережі: затримка та керована частота збоїв.
class FakeApi {
  FakeApi({this.failureRate = 0.2, Random? random})
      : _random = random ?? Random();

  /// Імовірність збою запиту: від 0.0 (ніколи) до 1.0 (завжди).
  final double failureRate;
  final Random _random;

  Future<T> request<T>(T Function() respond, {int delayMs = 800}) async {
    await Future<void>.delayed(Duration(milliseconds: delayMs));
    if (_random.nextDouble() < failureRate) {
      throw StateError('Сервер недоступний');
    }
    return respond();
  }
}
