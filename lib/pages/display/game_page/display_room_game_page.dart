import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/io.dart';
import 'question_display.dart';
import 'player_scores_dialog.dart';
import 'player_answers_dialog.dart';

class DisplayRoomGamePage extends StatefulWidget {
  final String roomId;

  const DisplayRoomGamePage({super.key, required this.roomId});

  @override
  State<DisplayRoomGamePage> createState() => _DisplayRoomGamePageState();
}

class _DisplayRoomGamePageState extends State<DisplayRoomGamePage> {
  late IOWebSocketChannel channel;
  String currentQuestion = 'Waiting for a question...';
  String currentAnswer = '';
  String? imageUrl;
  List<Map<String, dynamic>> players = [];
  Timer? countdownTimer;
  int remainingTime = 0;

  @override
  void initState() {
    super.initState();
    channel = IOWebSocketChannel.connect(
      Uri.parse('ws://localhost:8000/ws/${widget.roomId}'),
    );

    channel.ready.then((_) {
      channel.sink.add(jsonEncode({"name": "display_${widget.roomId}", "display": true}));
    });

    channel.stream.listen((message) {
      final data = jsonDecode(message);
      if (data.containsKey('room-deleted')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Admin left the room')),
        );
        Navigator.popUntil(context, ModalRoute.withName('/'));
      } else if (data.containsKey('new-question')) {
        setState(() {
          currentQuestion = data['new-question'];
          currentAnswer = data['answer'] ?? '';
          imageUrl = data['image'];
        });
      } else if (data.containsKey('start-timer')) {
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
  void dispose() {
    countdownTimer?.cancel();
    channel.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Display Room: ${widget.roomId}'),
      ),
      body: Stack(
        children: [
          QuestionDisplay(
            question: remainingTime > 0 ? '' : currentQuestion,
            imageUrl: imageUrl,
            remainingTime: remainingTime,
            formatTime: formatTime,
          ),
          Positioned(
            bottom: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FloatingActionButton(
                  onPressed: () => PlayerAnswersDialog.show(context, players, currentAnswer),
                  heroTag: 'answersButton',
                  child: const Icon(Icons.comment),
                ),
                const SizedBox(width: 10),
                FloatingActionButton(
                  onPressed: () => PlayerScoresDialog.show(context, players),
                  heroTag: 'scoresButton',
                  child: const Icon(Icons.score),
                ),
                const SizedBox(width: 10),
                FloatingActionButton(
                  onPressed: () => showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      content: Text(
                        currentAnswer.isNotEmpty ? currentAnswer : 'Answer not available.',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  ),
                  heroTag: 'showAnswerButton',
                  child: const Icon(Icons.lightbulb),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
