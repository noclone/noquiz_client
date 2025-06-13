import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../utils/preferences.dart';

class RightOrderSection extends StatefulWidget {
  final String roomId;
  final WebSocketChannel channel;

  const RightOrderSection({
    Key? key,
    required this.roomId,
    required this.channel,
  }) : super(key: key);

  @override
  _RightOrderSectionState createState() => _RightOrderSectionState();
}

class _RightOrderSectionState extends State<RightOrderSection> {
  List<Map<String, dynamic>> questions = [];
  Set<int> sentQuestionIndices = {};

  @override
  void initState() {
    super.initState();
    fetchQuestions();
  }

  Future<void> fetchQuestions() async {
    final serverIp = await getServerIpAddress();
    if (serverIp == null || serverIp.isEmpty) {
      return;
    }
    try {
      final response = await http.get(Uri.parse('http://$serverIp:8000/api/rooms/${widget.roomId}/right-order'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          questions = List<Map<String, dynamic>>.from(data);
          sentQuestionIndices.clear();
        });
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
  }

  void sendQuestionToSocket(int index) {
    final question = questions[index];
    var dict = {
      "right-order": question['title'],
      "data": question['data']
    };
    widget.channel.sink.add(jsonEncode(dict));

    setState(() {
      sentQuestionIndices.add(index);
    });
  }

  void sendShowAnswersToSocket(int index) {
    final question = questions[index];
    widget.channel.sink.add(jsonEncode({
      "show-right-order-answer": question['title'],
      "data": question['data']
    }));
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ListView.builder(
          itemCount: questions.length,
          itemBuilder: (context, index) {
            final question = questions[index];
            return Card(
              margin: const EdgeInsets.all(8.0),
              color: sentQuestionIndices.contains(index) ? Colors.green : null,
              child: ListTile(
                title: Text(question['title']),
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
                    IconButton(
                      icon: const Icon(Icons.visibility),
                      onPressed: () => sendShowAnswersToSocket(index),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        Positioned(
          bottom: 16.0,
          right: 16.0,
          child: FloatingActionButton(
            onPressed: () {
              widget.channel.sink.add(jsonEncode({"send-right-order-answer": true}));
            },
            child: Icon(Icons.check),
          ),
        ),
      ],
    );
  }
}

