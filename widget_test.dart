import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greenhouse_monitor/main.dart';
import 'package:greenhouse_monitor/services/fake_api.dart';
import 'package:greenhouse_monitor/services/greenhouse_service.dart';

void main() {
  testWidgets('показує завантаження, а потім картки датчиків', (tester) async {
    final service = GreenhouseService(api: FakeApi(failureRate: 0));

    await tester.pumpWidget(
      GreenhouseApp(service: service, sensorFailureRate: 0),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    expect(find.text('Температура'), findsOneWidget);

    // Видаляємо віджет, щоб dispose() зупинив усі таймери.
    await tester.pumpWidget(const SizedBox());
  });
}
