import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/io.dart';

class AdminRoomGamePage extends StatefulWidget {
  final String roomId;
  final IOWebSocketChannel channel;
  final Stream<dynamic> broadcastStream;
  final List<Map<String, dynamic>> players;

  const AdminRoomGamePage({
    super.key,
    required this.roomId,
    required this.channel,
    required this.broadcastStream,
    required this.players,
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

  Future<void> updatePlayerScore(int playerIndex) async {
    final player = widget.players[playerIndex];
    try {
      final response = await http.post(
        Uri.parse('http://localhost:8000/api/rooms/${widget.roomId}/player/score'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'player_id': player['id'],
          'score': player['score'],
        }),
      );

      if (response.statusCode != 200) {
        print('Failed to update player score: ${response.body}');
      }
    } catch (e) {
      print('Error updating player score: $e');
    }
  }

  void incrementScore(int index) {
    setState(() {
      widget.players[index]['score']++;
    });
    updatePlayerScore(index);
  }

  void decrementScore(int index) {
    setState(() {
      widget.players[index]['score']--;
    });
    updatePlayerScore(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Game Room: ${widget.roomId}'),
      ),
      body: Column(
        children: [
          Expanded(
            child: Row(
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
          ),
          Container(
            height: 150,
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(width: 1)),
            ),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: widget.players.length,
              itemBuilder: (context, index) {
                final player = widget.players[index];
                return Container(
                  width: 150,
                  margin: const EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () => incrementScore(index),
                      ),
                      Text(player['name']),
                      Text('Score: ${player['score']}'),
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: () => decrementScore(index),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
