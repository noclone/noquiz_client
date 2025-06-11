import 'dart:convert';

import 'package:flutter/material.dart';

import 'display_state.dart';

class AnswerDisplay extends StatefulWidget {
  final Function setCurrentDisplayState;
  final Stream<dynamic> broadcastStream;

  const AnswerDisplay(
      {super.key, required this.setCurrentDisplayState, required this.broadcastStream});

  @override
  State<AnswerDisplay> createState() => _AnswerDisplayState();
}

class _AnswerDisplayState extends State<AnswerDisplay> {

  String currentAnswer = '';

  @override
  void initState() {
    super.initState();

    widget.broadcastStream.listen((message) {
      final data = jsonDecode(message);
      if (data.containsKey('new-question')) {
        setState(() {
          currentAnswer = data['answer'] ?? '';
        });
      } else if (data.containsKey('show-answer')) {
        widget.setCurrentDisplayState(DisplayState.answer);
      }
    }, onError: (error) {
      print('WebSocket error: $error');
    }, onDone: () {
      print('WebSocket connection closed');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Answer:',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(
            currentAnswer.isNotEmpty ? currentAnswer : 'Answer not available.',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
