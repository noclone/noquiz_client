import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../utils/preferences.dart';

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
  List<String> categories = [];
  List<Map<String, dynamic>> categoryQuestions = [];
  Set<int> sentQuestionIndices = {};

  @override
  void initState() {
    super.initState();
    fetchQuestionsCategories();
  }

  Future<void> fetchQuestionsCategories() async {
    final serverIp = await getServerIpAddress();
    if (serverIp == null || serverIp.isEmpty) {
      return;
    }
    try {
      final response = await http.get(Uri.parse('http://$serverIp:8000/api/rooms/${widget.roomId}/questions_categories'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          categories = List<String>.from(data);
        });
      } else {
        print('Failed to load questions categories');
      }
    } catch (e) {
      print('Error fetching questions categories: $e');
    }
  }

  Future<void> fetchCategoryQuestions(String category) async {
    final serverIp = await getServerIpAddress();
    if (serverIp == null || serverIp.isEmpty) {
      return;
    }
    try {
      final response = await http.get(Uri.parse('http://$serverIp:8000/api/rooms/${widget.roomId}/questions_categories/$category'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          categoryQuestions = List<Map<String, dynamic>>.from(data);
          sentQuestionIndices.clear();
        });
      } else {
        print('Failed to load category questions');
      }
    } catch (e) {
      print('Error fetching category questions: $e');
    }
  }

  void skipQuestion(int index) {
    setState(() {
      categoryQuestions.removeAt(index);
      sentQuestionIndices.clear();
    });
  }

  void sendQuestionToSocket(int index) {
    final question = categoryQuestions[index];
    widget.channel.sink.add(jsonEncode({
      "new-question": question['question'],
      "answer": question['answer'],
      "expected_answer_type": question['expected_answer_type'],
      "images": question["images"],
    }));

    setState(() {
      sentQuestionIndices.add(index);
    });
  }

  void sendShowAnswersToSocket(int index) {
    widget.channel.sink.add(jsonEncode({
      "show-answer": true,
    }));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final theme = categories[index];
              return Padding(
                padding: const EdgeInsets.all(4.0),
                child: ElevatedButton(
                  onPressed: () => fetchCategoryQuestions(theme),
                  child: Text(theme),
                ),
              );
            },
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: categoryQuestions.length,
            itemBuilder: (context, index) {
              final question = categoryQuestions[index];
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
        ),
      ],
    );
  }
}
