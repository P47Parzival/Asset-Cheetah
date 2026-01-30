import 'package:flutter/material.dart';

class OverviewScreen extends StatelessWidget {
  const OverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Padding(
        padding: EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Text('Dashboard Overview', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
             SizedBox(height: 24),
             Row(
               children: [
                 _StatCard(title: 'Total Assets', value: '124'),
                 SizedBox(width: 16),
                 _StatCard(title: 'In Maintenance', value: '3', color: Colors.orange),
                 SizedBox(width: 16),
                 _StatCard(title: 'Synced Events', value: '1,024', color: Colors.blue),
               ],
             )
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _StatCard({required this.title, required this.value, this.color = Colors.green});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }
}
