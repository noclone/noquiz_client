import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/io.dart';

class QuestionsSection extends StatefulWidget {
  final String roomId;
  final IOWebSocketChannel channel;

  const QuestionsSection({
    super.key,
    required this.roomId,
    required this.channel,
  });

  @override
  State<QuestionsSection> createState() => _QuestionsSectionState();
}

class _QuestionsSectionState extends State<QuestionsSection> {
  List<Map<String, dynamic>> questions = [];
  Set<int> sentQuestionIndices = {};
  List<String> themes = [];
  List<Map<String, dynamic>> themeQuestions = [];

  Set<int> correctAnswers = {};
  Set<int> wrongAnswers = {};

  @override
  void initState() {
    super.initState();
    fetchThemes();
    for (int i = 0; i < 3; i++) {
      fetchQuestion();
    }
  }

  Future<void> fetchThemes() async {
    try {
      final response = await http.get(Uri.parse('http://localhost:8000/api/rooms/${widget.roomId}/themes'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          themes = List<String>.from(data);
        });
      } else {
        print('Failed to load themes');
      }
    } catch (e) {
      print('Error fetching themes: $e');
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

  Future<void> fetchThemeQuestions(String theme) async {
    try {
      final response = await http.get(Uri.parse('http://localhost:8000/api/rooms/${widget.roomId}/themes/$theme'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          themeQuestions = List<Map<String, dynamic>>.from(data);
          correctAnswers.clear();
          wrongAnswers.clear();
        });
      } else {
        print('Failed to load theme questions');
      }
    } catch (e) {
      print('Error fetching theme questions: $e');
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

  void markAsCorrect(int index) {
    setState(() {
     wrongAnswers.remove(index);
     correctAnswers.add(index);
    });
  }

  void markAsWrong(int index) {
    setState(() {
     correctAnswers.remove(index);
     wrongAnswers.add(index);
    });
  }

  void showThemes() {
    widget.channel.sink.add(jsonEncode({
      "show-themes": themes
    }));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: DefaultTabController(
            length: 2,
            child: Column(
              children: [
                Expanded(
                  child: TabBarView(
                    children: [
                      ListView.builder(
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
                      ),
                      Column(
                        children: [
                          SizedBox(
                            height: 50,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: themes.length + 1,
                              itemBuilder: (context, index) {
                                if (index < themes.length) {
                                  final theme = themes[index];
                                  return Padding(
                                    padding: const EdgeInsets.all(4.0),
                                    child: ElevatedButton(
                                      onPressed: () => fetchThemeQuestions(theme),
                                      child: Text(theme),
                                    ),
                                  );
                                } else {
                                  return Padding(
                                    padding: const EdgeInsets.all(4.0),
                                    child: IconButton(
                                      icon: const Icon(Icons.screen_share),
                                      onPressed: () => showThemes(),
                                    ),
                                  );
                                }
                              },
                            ),
                          ),
                          Expanded(
                            child: ListView.builder(
                              itemCount: themeQuestions.length,
                              itemBuilder: (context, index) {
                                final question = themeQuestions[index];
                                return Card(
                                  margin: const EdgeInsets.all(8.0),
                                  color: correctAnswers.contains(index)
                                      ? Colors.green
                                      : wrongAnswers.contains(index)
                                      ? Colors.red
                                      : null,
                                  child: ListTile(
                                    title: Text(question['question']),
                                    subtitle: Text('Answer: ${question['answer']}'),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.check, color: Colors.green),
                                          onPressed: () => markAsCorrect(index),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.close, color: Colors.red),
                                          onPressed: () => markAsWrong(index),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const TabBar(
                  tabs: [
                    Tab(text: 'Questions'),
                    Tab(text: 'Themes'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
