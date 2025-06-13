import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../../utils/server.dart';

class ThemesSection extends StatefulWidget {
  final String roomId;
  final WebSocketChannel channel;

  const ThemesSection({
    Key? key,
    required this.roomId,
    required this.channel,
  }) : super(key: key);

  @override
  _ThemesSectionState createState() => _ThemesSectionState();
}

class _ThemesSectionState extends State<ThemesSection> {
  List<String> themes = [];
  List<Map<String, dynamic>> themeQuestions = [];
  Set<int> correctAnswers = {};
  Set<int> wrongAnswers = {};

  @override
  void initState() {
    super.initState();
    fetchThemes();
  }

  Future<void> fetchThemes() async {
    final serverIp = await getServerIpAddress();
    if (serverIp == null || serverIp.isEmpty) {
      return;
    }
    try {
      final response = await http.get(Uri.parse('http://$serverIp:8000/api/rooms/${widget.roomId}/themes'));
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

  Future<void> fetchThemeQuestions(String theme) async {
    final serverIp = await getServerIpAddress();
    if (serverIp == null || serverIp.isEmpty) {
      return;
    }
    try {
      final response = await http.get(Uri.parse('http://$serverIp:8000/api/rooms/${widget.roomId}/themes/$theme'));
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

  void showThemes() {
    widget.channel.sink.add(jsonEncode({
      "show-themes": themes
    }));
  }

  void sendThemeAnswers() {
    final relevantIndices = {...correctAnswers, ...wrongAnswers};

    final filteredQuestions = themeQuestions.where((question) {
      final index = themeQuestions.indexOf(question);
      return relevantIndices.contains(index);
    }).toList();

    final answers = filteredQuestions.map((question) {
      final index = themeQuestions.indexOf(question);
      return {
        'question': question['question'],
        'answer': question['answer'],
        'isCorrect': correctAnswers.contains(index),
      };
    }).toList();

    widget.channel.sink.add(jsonEncode({
      "theme-answers": answers,
    }));
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: themes.length + 2,
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
              } else if (index == themes.length) {
                return Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: IconButton(
                    icon: const Icon(Icons.screen_share),
                    onPressed: () => showThemes(),
                  ),
                );
              } else {
                return Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: () => sendThemeAnswers(),
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
    );
  }
}
