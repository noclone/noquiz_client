import 'dart:convert';

import 'package:flutter/material.dart';

import 'display_state.dart';

class ThemeAnswersDisplay extends StatefulWidget {
  final Function setCurrentDisplayState;
  final Stream<dynamic> broadcastStream;

  const ThemeAnswersDisplay(
      {super.key, required this.setCurrentDisplayState, required this.broadcastStream});

  @override
  State<ThemeAnswersDisplay> createState() => _ThemeAnswersDisplayState();
}

class _ThemeAnswersDisplayState extends State<ThemeAnswersDisplay> {

  List<dynamic> themeAnswers = [];

  @override
  void initState() {
    super.initState();

    widget.broadcastStream.listen((message) {
      final data = jsonDecode(message);
      if (data.containsKey('theme-answers')) {
        setState(() {
          themeAnswers = data['theme-answers'];
        });
        widget.setCurrentDisplayState(DisplayState.themeAnswers);
      }
    }, onError: (error) {
      print('WebSocket error: $error');
    }, onDone: () {
      print('WebSocket connection closed');
    });
  }

  @override
  Widget build(BuildContext context) {
    int correctCount = themeAnswers.where((answer) => answer['isCorrect']).length;

    return Center(
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxWidth: 600),
        child: SingleChildScrollView(
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
                physics: const NeverScrollableScrollPhysics(),
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
      ),
    );
  }
}
