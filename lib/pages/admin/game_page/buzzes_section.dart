import 'package:flutter/material.dart';

class BuzzesSection extends StatelessWidget {
  final List<Map<String, dynamic>> buzzes;
  final VoidCallback onResetBuzzers;

  const BuzzesSection({
    super.key,
    required this.buzzes,
    required this.onResetBuzzers,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      decoration: const BoxDecoration(
        border: Border(left: BorderSide(width: 1)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: onResetBuzzers,
            child: const Text('Reset Buzzers'),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: buzzes.length,
              itemBuilder: (context, index) {
                final buzz = buzzes[index];
                return ListTile(
                  title: Text(buzz['name']),
                  subtitle: Text(buzz['time'].toString()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
