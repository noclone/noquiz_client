import 'package:flutter/material.dart';

class ThemeAnswersDialog extends StatelessWidget {
  final List<dynamic> themeAnswers;

  const ThemeAnswersDialog({Key? key, required this.themeAnswers}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    int correctCount = themeAnswers.where((answer) => answer['isCorrect']).length;

    return AlertDialog(
      title: Text('Correct Answers: $correctCount'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
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
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
