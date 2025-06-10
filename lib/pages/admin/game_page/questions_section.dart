import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

class QuestionsSection extends StatefulWidget {
  final String roomId;
  final WebSocketChannel channel;

  const QuestionsSection({
    Key? key,
    required this.roomId,
    required this.channel,
  }) : super(key: key);

  @override
  _QuestionsSectionState createState() => _QuestionsSectionState();
}

class _QuestionsSectionState extends State<QuestionsSection> {
  List<Map<String, dynamic>> questions = [];
  Set<int> sentQuestionIndices = {};

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < 3; i++) {
      fetchQuestion();
    }
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
    final question = questions[index];
    var dict = {
      "new-question": question['question'],
      "answer": question['answer'],
      "expected_answer_type": question['expected_answer_type']
    };
    if (question.containsKey("image")) {
      dict["image"] = question["image"];
    }
    widget.channel.sink.add(jsonEncode(dict));

    setState(() {
      sentQuestionIndices.add(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: questions.length,
      itemBuilder: (context, index) {
        final question = questions[index];
        return Card(
          margin: const EdgeInsets.all(8.0),
          color: sentQuestionIndices.contains(index) ? Colors.green : null,
          child: ListTile(
            title: Text(question['question']),
            subtitle: Text('Answer: ${question['answer']} -- Answer Type: ${question['expected_answer_type']}'),
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
    );
  }
}
