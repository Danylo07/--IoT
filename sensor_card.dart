import 'package:flutter/material.dart';
import 'package:greenhouse_monitor/models/sensor.dart';
import 'package:greenhouse_monitor/models/sensor_reading.dart';
import 'package:greenhouse_monitor/models/threshold.dart';

/// Картка датчика: власний StreamBuilder, тому збій одного датчика
/// не впливає на решту карток.
class SensorCard extends StatelessWidget {
  const SensorCard({
    super.key,
    required this.sensor,
    required this.threshold,
    required this.stream,
  });

  final Sensor sensor;
  final Threshold? threshold;
  final Stream<SensorReading> stream;

  IconData get _icon => switch (sensor.kind) {
        SensorKind.temperature => Icons.thermostat,
        SensorKind.humidity => Icons.water_drop,
        SensorKind.light => Icons.light_mode,
      };

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SensorReading>(
      stream: stream,
      builder: (context, snapshot) {
        final textTheme = Theme.of(context).textTheme;

        // Збій датчика: показується лише на цій картці.
        if (snapshot.hasError) {
          return _CardShell(
            icon: Icons.sensors_off,
            title: sensor.name,
            color: Colors.orange.shade100,
            borderColor: Colors.orange,
            body: Text('Збій: ${snapshot.error}', style: textTheme.bodyLarge),
          );
        }

        final reading = snapshot.data;

        // Очікування першого показання.
        if (reading == null) {
          return _CardShell(
            icon: _icon,
            title: sensor.name,
            body: const Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 8),
                Text('Очікування першого показання…'),
              ],
            ),
          );
        }

        final limit = threshold;
        final outside = limit?.isOutside(reading.value) ?? false;

        return _CardShell(
          icon: _icon,
          title: sensor.name,
          color: outside ? Colors.red.shade100 : null,
          borderColor: outside ? Colors.red : null,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${sensor.format(reading.value)} ${sensor.unit}',
                style: textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              if (limit != null)
                Text(
                  'Норма: ${sensor.format(limit.min)}–'
                  '${sensor.format(limit.max)} ${sensor.unit}',
                  style: textTheme.bodySmall,
                ),
              if (outside)
                Text(
                  'Вихід за поріг!',
                  style: textTheme.bodyMedium?.copyWith(
                    color: Colors.red.shade900,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _CardShell extends StatelessWidget {
  const _CardShell({
    required this.icon,
    required this.title,
    required this.body,
    this.color,
    this.borderColor,
  });

  final IconData icon;
  final String title;
  final Widget body;
  final Color? color;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final border = borderColor;

    return Card(
      color: color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: border == null
            ? BorderSide.none
            : BorderSide(color: border, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, size: 36),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  body,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
