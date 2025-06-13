import 'dart:convert';
import 'package:flutter/material.dart';
import 'display_state.dart';

class ThemeAnswersDisplay extends StatefulWidget {
  final Function setCurrentDisplayState;
  final Stream<dynamic> broadcastStream;

  const ThemeAnswersDisplay({
    super.key,
    required this.setCurrentDisplayState,
    required this.broadcastStream,
  });

  @override
  State<ThemeAnswersDisplay> createState() => _ThemeAnswersDisplayState();
}

class _ThemeAnswersDisplayState extends State<ThemeAnswersDisplay> {
  List<dynamic> themeAnswers = [];
  double questionFontSize = 16;
  double answerFontSize = 14;
  double listWidth = 600;

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

  void increaseFontSize() {
    setState(() {
      questionFontSize += 2;
      answerFontSize += 2;
    });
  }

  void decreaseFontSize() {
    setState(() {
      questionFontSize = questionFontSize > 2 ? questionFontSize - 2 : questionFontSize;
      answerFontSize = answerFontSize > 2 ? answerFontSize - 2 : answerFontSize;
    });
  }

  @override
  Widget build(BuildContext context) {
    int correctCount = themeAnswers.where((answer) => answer['isCorrect']).length;

    return Stack(
      children: [
        Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Correct Answers: $correctCount',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onHorizontalDragUpdate: (DragUpdateDetails details) {
                      setState(() {
                        listWidth += details.primaryDelta!;
                        listWidth = listWidth.clamp(300, 800);
                      });
                    },
                    child: SizedBox(
                      width: listWidth,
                      child: ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: themeAnswers.length,
                        itemBuilder: (BuildContext context, int index) {
                          final answer = themeAnswers[index];
                          return ListTile(
                            title: Text(
                              answer['question'],
                              style: TextStyle(
                                fontSize: questionFontSize,
                                color: answer['isCorrect'] ? Colors.green : Colors.red,
                              ),
                            ),
                            subtitle: Text(
                              answer['answer'],
                              style: TextStyle(fontSize: answerFontSize),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 16.0,
          right: 16.0,
          child: Column(
            children: [
              FloatingActionButton(
                onPressed: increaseFontSize,
                child: const Icon(Icons.add),
                mini: true,
              ),
              const SizedBox(height: 8),
              FloatingActionButton(
                onPressed: decreaseFontSize,
                child: const Icon(Icons.remove),
                mini: true,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
