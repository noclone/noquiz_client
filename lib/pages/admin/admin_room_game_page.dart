import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/io.dart';

class AdminRoomGamePage extends StatefulWidget {
  final String roomId;
  final IOWebSocketChannel channel;
  final Stream<dynamic> broadcastStream;

  const AdminRoomGamePage({
    super.key,
    required this.roomId,
    required this.channel,
    required this.broadcastStream,
  });

  @override
  State<AdminRoomGamePage> createState() => _AdminRoomGamePageState();
}

class _AdminRoomGamePageState extends State<AdminRoomGamePage> {
  List<Map<String, dynamic>> buzzes = [];
  List<Map<String, dynamic>> questions = [];
  Set<int> sentQuestionIndices = {};

  @override
  void initState() {
    super.initState();

    for (int i = 0; i < 3; i++) {
      fetchQuestion();
    }

    widget.broadcastStream.listen((message) {
      final data = jsonDecode(message);
      if (data.containsKey('buzz')) {
        setState(() {
          buzzes.add({
            'name': data['buzz'][0],
            'time': data['buzz'][1],
          });
          buzzes.sort((a, b) => a['time'].compareTo(b['time']));
        });
      }
    });
  }

  Future<void> fetchQuestion() async {
    try {
      final response = await http.get(Uri.parse('http://localhost:8000/api/rooms/${widget.roomId}/questions/next'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (!data.containsKey('end-of-questions')) {
          setState(() {
            questions.add(data);
          });
        }
      } else {
        print('Failed to load question');
      }
    } catch (e) {
      print('Error fetching question: $e');
    }
  }

  void skipQuestion(int index) {
    setState(() {
      questions.removeAt(index);
      sentQuestionIndices.clear();
    });
    fetchQuestion();
  }

  void sendQuestionToSocket(int index) {
    _resetBuzzers();
    final question = questions[index];
    widget.channel.sink.add(jsonEncode({
      "new-question": question['question'],
      "expected_answer_type": question['expected_answer_type']
    }));

    setState(() {
      sentQuestionIndices.add(index);
    });
  }

  void _resetBuzzers() {
    setState(() {
      buzzes.clear();
    });
    widget.channel.sink.add(jsonEncode({"reset-buzzer": true}));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Game Room: ${widget.roomId}'),
      ),
      body: Row(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: questions.length,
              itemBuilder: (context, index) {
                final question = questions[index];
                return Card(
                  margin: const EdgeInsets.all(8.0),
                  color: sentQuestionIndices.contains(index) ? Colors.green : null,
                  child: ListTile(
                    title: Text(question['question']),
                    subtitle: Text('Answer Type: ${question['expected_answer_type']}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.skip_next),
                          onPressed: () => skipQuestion(index),
                        ),
                        IconButton(
                          icon: const Icon(Icons.send),
                          onPressed: () => sendQuestionToSocket(index),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            width: 200,
            decoration: const BoxDecoration(
              border: Border(left: BorderSide(width: 1)),
            ),
            child: Column(
              children: [
                ElevatedButton(
                  onPressed: _resetBuzzers,
                  child: const Text('Reset Buzzers'),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: buzzes.length,
                    itemBuilder: (context, index) {
                      final buzz = buzzes[index];
                      return ListTile(
                        title: Text(buzz['name']),
                        subtitle: Text(buzz['time'].toString()),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
