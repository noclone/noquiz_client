import 'dart:convert';

import 'package:flutter/material.dart';
import 'dart:async';

class QuestionDisplay extends StatefulWidget {
  final String question;
  final String? imageUrl;
  final Stream<dynamic> broadcastStream;

  const QuestionDisplay({
    Key? key,
    required this.question,
    required this.broadcastStream,
    this.imageUrl,
  }) : super(key: key);

  @override
  _QuestionDisplayState createState() => _QuestionDisplayState();
}

class _QuestionDisplayState extends State<QuestionDisplay> {
  Timer? countdownTimer;
  int remainingTime = 0;

  @override
  void initState() {
    super.initState();

    widget.broadcastStream.listen((message) {
      final data = jsonDecode(message);
      if (data.containsKey('start-timer')) {
        startTimer(data['start-timer'] * 1000);
      } else if (data.containsKey('pause-timer')) {
        pauseTimer();
      } else if (data.containsKey('reset-timer')) {
        resetTimer();
      }
    }, onError: (error) {
      print('WebSocket error: $error');
    }, onDone: () {
      print('WebSocket connection closed');
    });
  }

  @override
  void dispose() {
    countdownTimer?.cancel();
    super.dispose();
  }

  void startTimer(int duration) {
    if (remainingTime == 0) {
      setState(() {
        remainingTime = duration;
      });
    }

    countdownTimer?.cancel();

    const oneMs = Duration(milliseconds: 10);
    countdownTimer = Timer.periodic(oneMs, (timer) {
      setState(() {
        if (remainingTime > 0) {
          remainingTime -= 10;
        } else {
          countdownTimer?.cancel();
        }
      });
    });
  }

  void pauseTimer() {
    countdownTimer?.cancel();
  }

  void resetTimer() {
    countdownTimer?.cancel();
    setState(() {
      remainingTime = 0;
    });
  }

  String formatTime(int milliseconds) {
    int hundreds = (milliseconds / 10).truncate();
    int seconds = (hundreds / 100).truncate();
    int minutes = (seconds / 60).truncate();

    String minutesStr = (minutes % 60).toString().padLeft(2, '0');
    String secondsStr = (seconds % 60).toString().padLeft(2, '0');
    String hundredsStr = (hundreds % 100).toString().padLeft(2, '0');

    return "$minutesStr:$secondsStr:$hundredsStr";
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (remainingTime <= 0)
          Center(
            child: Text(
              widget.question,
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
        if (widget.imageUrl != null && widget.imageUrl!.isNotEmpty && remainingTime <= 0)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Image.network(widget.imageUrl!),
          ),
      ],
    );
  }
}
