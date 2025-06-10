import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PlayerAnswersDialog extends StatefulWidget {
  final String roomId;
  final String currentAnswer;

  const PlayerAnswersDialog({
    Key? key,
    required this.roomId,
    required this.currentAnswer,
  }) : super(key: key);

  @override
  _PlayerAnswersDialogState createState() => _PlayerAnswersDialogState();
}

class _PlayerAnswersDialogState extends State<PlayerAnswersDialog> {
  bool showAnswer = false;
  List<Map<String, dynamic>> players = [];

  @override
  void initState() {
    super.initState();
    fetchPlayerAnswers();
  }

  Future<void> fetchPlayerAnswers() async {
    try {
      final response = await http.get(Uri.parse('http://localhost:8000/api/rooms/${widget.roomId}'));
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
    return AlertDialog(
      title: const Text('Player Answers'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showAnswer && widget.currentAnswer.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text(
                  'Answer: ${widget.currentAnswer}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ),
            if (!showAnswer && widget.currentAnswer.isNotEmpty)
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
      actions: <Widget>[
        TextButton(
          child: const Text('Close'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}
