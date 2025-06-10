import 'dart:convert';
import 'package:flutter/material.dart';
import 'dart:async';

enum DisplayType { timer, question, rightOrder }

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
  DisplayType currentDisplay = DisplayType.question;
  String? currentRightOrder;
  List<List<dynamic>> imageData = [];
  bool showLabels = false;

  @override
  void initState() {
    super.initState();

    widget.broadcastStream.listen((message) {
      final data = jsonDecode(message);
      if (data.containsKey('start-timer')) {
        setState(() {
          currentDisplay = DisplayType.timer;
        });
        startTimer(data['start-timer'] * 1000);
      } else if (data.containsKey('pause-timer')) {
        pauseTimer();
      } else if (data.containsKey('reset-timer')) {
        resetTimer();
      } else if (data.containsKey('new-question')) {
        setState(() {
          currentDisplay = DisplayType.question;
        });
      } else if (data.containsKey('right-order')) {
        setState(() {
          currentDisplay = DisplayType.rightOrder;
          currentRightOrder = data['right-order'];
          imageData = List<List<dynamic>>.from(data['data'] ?? [])..shuffle();
          showLabels = false;
        });
      } else if (data.containsKey('show-right-order-answer')) {
        setState(() {
          currentDisplay = DisplayType.rightOrder;
          currentRightOrder = data['show-right-order-answer'];
          imageData = List<List<dynamic>>.from(data['data'] ?? []);
          showLabels = true;
        });
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
    switch (currentDisplay) {
      case DisplayType.timer:
        return Center(
          child: Text(
            formatTime(remainingTime),
            style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
          ),
        );
      case DisplayType.rightOrder:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Center(
              child: Text(
                currentRightOrder ?? '',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            if (imageData.isNotEmpty)
              LayoutBuilder(
                builder: (context, constraints) {
                  double imageWidth = constraints.maxWidth / imageData.length - 16;

                  return Center(
                    child: SizedBox(
                      height: 250, // Increased height to accommodate labels
                      child: ListView.builder(
                        shrinkWrap: true,
                        scrollDirection: Axis.horizontal,
                        itemCount: imageData.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: SizedBox(
                              width: imageWidth,
                              child: Column(
                                children: [
                                  Image.network(
                                    imageData[index][0],
                                    fit: BoxFit.contain,
                                    height: 200,
                                  ),
                                  if (showLabels)
                                    Text(
                                      imageData[index][1],
                                      style: const TextStyle(fontSize: 20),
                                      textAlign: TextAlign.center,
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
          ],
        );

      default:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Center(
              child: Text(
                widget.question,
                style: const TextStyle(fontSize: 24),
                textAlign: TextAlign.center,
              ),
            ),
            if (widget.imageUrl != null && widget.imageUrl!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Image.network(widget.imageUrl!),
              ),
          ],
        );
    }
  }
}
