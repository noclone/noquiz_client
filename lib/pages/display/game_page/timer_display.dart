import 'dart:async';

import 'package:flutter/material.dart';
import 'package:noquiz_client/utils/socket.dart';

class TimerDisplay extends StatefulWidget {
  final Stream<dynamic> broadcastStream;

  const TimerDisplay({Key? key, required this.broadcastStream}) : super(key: key);

  @override
  _TimerDisplayState createState() => _TimerDisplayState();
}

class _TimerDisplayState extends State<TimerDisplay> {
  Timer? countdownTimer;
  int remainingTime = 0;

  @override
  void initState() {
    super.initState();
    widget.broadcastStream.listen((message) {
      MessageData data = decodeMessageData(message);
      if (data.subject == MessageSubject.TIMER) {
        if (data.action == "START") {
          startTimer(data.content['DURATION'] * 1000);
        } else if (data.action == "PAUSE") {
          pauseTimer();
        } else if (data.action == "RESET") {
          resetTimer();
        }
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
    setState(() {
      remainingTime = duration;
    });

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
    final screenWidth = MediaQuery.of(context).size.width;
    final double responsiveFontSize = screenWidth * 0.05;

    return Center(
      child: Text(
        formatTime(remainingTime),
        style: TextStyle(
          fontSize: responsiveFontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

