import 'package:flutter/material.dart';
import 'package:greenhouse_monitor/models/daily_summary.dart';

/// Підсумок за добу.
class SummaryCard extends StatelessWidget {
  const SummaryCard({super.key, required this.summary});

  final DailySummary summary;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Підсумок за добу',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Середня температура: '
              '${summary.avgTemperature.toStringAsFixed(1)} °C',
            ),
            Text(
              'Середня вологість: '
              '${summary.avgHumidity.toStringAsFixed(1)} %',
            ),
            Text(
              'Середня освітленість: '
              '${summary.avgLight.toStringAsFixed(0)} лк',
            ),
            Text('Виходів за поріг: ${summary.alertsCount}'),
          ],
        ),
      ),
    );
  }
}
