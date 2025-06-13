import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../../utils/preferences.dart';
import 'display_state.dart';

class PlayerAnswersDisplay extends StatefulWidget {
  final String roomId;
  final Function setCurrentDisplayState;
  final Stream<dynamic> broadcastStream;

  const PlayerAnswersDisplay({
    super.key,
    required this.roomId,
    required this.setCurrentDisplayState,
    required this.broadcastStream,
  });

  @override
  State<PlayerAnswersDisplay> createState() => _PlayerAnswersDisplayState();
}

class _PlayerAnswersDisplayState extends State<PlayerAnswersDisplay> {
  bool showAnswer = false;
  List<Map<String, dynamic>> players = [];
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
      } else if (data.containsKey('show-players-answers')) {
        fetchPlayerAnswers();
        widget.setCurrentDisplayState(DisplayState.playerAnswers);
      }
    }, onError: (error) {
      print('WebSocket error: $error');
    }, onDone: () {
      print('WebSocket connection closed');
    });
  }

  Future<void> fetchPlayerAnswers() async {
    final serverIp = await getServerIpAddress();
    if (serverIp == null || serverIp.isEmpty) {
      return;
    }
    try {
      final response = await http.get(Uri.parse('http://$serverIp:8000/api/rooms/${widget.roomId}'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          players = List<Map<String, dynamic>>.from(data['players']);
        });
      } else {
        print('Failed to load player answers');
      }
    } catch (e) {
      print('Error fetching player answers: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.5),
              spreadRadius: 5,
              blurRadius: 7,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Player Answers',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            if (showAnswer && currentAnswer.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text(
                  'Answer: ${currentAnswer}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ),
            if (!showAnswer && currentAnswer.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      showAnswer = true;
                    });
                  },
                  child: const Text('Show Answer'),
                ),
              ),
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: players.length,
                itemBuilder: (context, index) {
                  final player = players[index];
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          player['name'],
                          style: const TextStyle(fontSize: 20),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          player['current_answer'] ?? 'No answer',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
