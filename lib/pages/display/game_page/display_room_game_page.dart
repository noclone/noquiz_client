import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/io.dart';
import 'question_display.dart';
import 'player_scores_dialog.dart';
import 'player_answers_dialog.dart';
import 'themes_dialog.dart';
import 'theme_answers_dialog.dart';

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
  late Stream<dynamic> broadcastStream;

  @override
  void initState() {
    super.initState();
    channel = IOWebSocketChannel.connect(
      Uri.parse('ws://localhost:8000/ws/${widget.roomId}'),
    );

    channel.ready.then((_) {
      channel.sink.add(jsonEncode({"name": "display_${widget.roomId}", "display": true}));
    });

    broadcastStream = channel.stream.asBroadcastStream();
    broadcastStream.listen((message) {
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
      } else if (data.containsKey('show-themes')) {
        ThemesDialog.show(context, List<String>.from(data['show-themes']));
      } else if (data.containsKey('theme-answers')) {
        showThemeAnswersDialog(data['theme-answers']);
      }
    }, onError: (error) {
      print('WebSocket error: $error');
    }, onDone: () {
      print('WebSocket connection closed');
    });
  }

  void showThemeAnswersDialog(List<dynamic> themeAnswers) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ThemeAnswersDialog(themeAnswers: themeAnswers);
      },
    );
  }

  @override
  void dispose() {
    channel.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Display Room'),
      ),
      body: Stack(
        children: [
          QuestionDisplay(
            question: currentQuestion,
            imageUrl: imageUrl,
            broadcastStream: broadcastStream,
          ),
          Positioned(
            bottom: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FloatingActionButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => PlayerAnswersDialog(
                        roomId: widget.roomId,
                        currentAnswer: currentAnswer,
                      ),
                    );
                  },
                  heroTag: 'answersButton',
                  child: const Icon(Icons.comment),
                ),
                const SizedBox(width: 10),
                FloatingActionButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => PlayerScoresDialog(
                        roomId: widget.roomId,
                      ),
                    );
                  },
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
