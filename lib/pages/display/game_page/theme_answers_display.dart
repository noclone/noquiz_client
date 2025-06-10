import 'package:flutter/material.dart';

class ThemeAnswersDisplay extends StatelessWidget {
  final List<dynamic> themeAnswers;

  const ThemeAnswersDisplay({super.key, required this.themeAnswers});

  @override
  Widget build(BuildContext context) {
    int correctCount = themeAnswers.where((answer) => answer['isCorrect']).length;

    return Center(
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxWidth: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Correct Answers: $correctCount',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ListView.builder(
              shrinkWrap: true,
              itemCount: themeAnswers.length,
              itemBuilder: (BuildContext context, int index) {
                final answer = themeAnswers[index];
                return ListTile(
                  title: Text(
                    answer['question'],
                    style: TextStyle(
                      color: answer['isCorrect'] ? Colors.green : Colors.red,
                    ),
                  ),
                  subtitle: Text(answer['answer']),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
