import 'package:flutter/material.dart';

class QuestionDisplay extends StatelessWidget {
  final String question;
  final String? imageUrl;
  final int remainingTime;
  final String Function(int) formatTime;

  const QuestionDisplay({
    super.key,
    required this.question,
    this.imageUrl,
    required this.remainingTime,
    required this.formatTime,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (remainingTime <= 0)
          Center(
            child: Text(
              question,
              style: const TextStyle(fontSize: 24),
              textAlign: TextAlign.center,
            ),
          ),
        if (remainingTime > 0)
          Center(
            child: Text(
              formatTime(remainingTime),
              style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
            ),
          ),
        if (imageUrl != null && remainingTime <= 0)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Image.network(imageUrl!),
          ),
      ],
    );
  }
}
