import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:noquiz_client/components/box.dart';
import 'package:noquiz_client/components/color_manager.dart';
import 'package:noquiz_client/utils/preferences.dart';
import 'package:noquiz_client/utils/socket.dart';
import 'package:provider/provider.dart';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

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
      final response = await http.get(Uri.parse(
          'http://$serverIp:8000/api/rooms/${widget.roomId}/right-order'));
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
    sendToSocket(widget.channel, MessageSubject.RIGHT_ORDER, "SEND",
        {"TITLE": question["title"], "DATA": question["data"]});

    setState(() {
      sentQuestionIndices.add(index);
    });
  }

  void sendShowAnswersToSocket(int index) {
    final question = questions[index];
    sendToSocket(widget.channel, MessageSubject.RIGHT_ORDER, "SHOW_ANSWER",
        {"TITLE": question["title"], "DATA": question["data"]});
  }

  @override
  Widget build(BuildContext context) {
    final colorManager = Provider.of<ColorManager>(context);
    return Stack(
      children: [
        ListView.builder(
          itemCount: questions.length,
          itemBuilder: (context, index) {
            final question = questions[index];
            return Padding(
              padding: const EdgeInsets.all(4.0),
              child: NQBox(
                padding: const EdgeInsets.all(2.0),
                spreadRadius: 2,
                borderColor: sentQuestionIndices.contains(index)
                    ? Colors.green
                    : colorManager.currentColors.secondaryColor,
                child: ListTile(
                  title: Text(question['title'], style: TextStyle(color: colorManager.currentColors.textPrimaryColor)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.skip_next),
                        color: colorManager.currentColors.textPrimaryColor,
                        onPressed: () => skipQuestion(index),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send),
                        color: colorManager.currentColors.textPrimaryColor,
                        onPressed: () => sendQuestionToSocket(index),
                      ),
                      IconButton(
                        icon: const Icon(Icons.visibility),
                        color: colorManager.currentColors.textPrimaryColor,
                        onPressed: () => sendShowAnswersToSocket(index),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        Positioned(
          bottom: 16.0,
          right: 16.0,
          child: NQBox(borderColor: colorManager.currentColors.secondaryColor,
          child: FloatingActionButton(
            backgroundColor: colorManager.currentColors.primaryColor,
            onPressed: () {
              sendToSocket(widget.channel, MessageSubject.RIGHT_ORDER,
                  "REQUEST_PLAYERS_ANSWER", {});
            },
            child: Icon(Icons.check, color: colorManager.currentColors.secondaryColor,),
          ),)
        ),
      ],
    );
  }
}
