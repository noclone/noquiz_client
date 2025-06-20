import 'package:flutter/material.dart';
import 'package:noquiz_client/pages/display/game_page/display_state.dart';
import 'package:noquiz_client/utils/socket.dart';


class AnswerDisplay extends StatefulWidget {
  final Function setCurrentDisplayState;
  final Stream<dynamic> broadcastStream;

  const AnswerDisplay(
      {super.key, required this.setCurrentDisplayState, required this.broadcastStream});

  @override
  State<AnswerDisplay> createState() => _AnswerDisplayState();
}

class _AnswerDisplayState extends State<AnswerDisplay> {

  String currentAnswer = '';

  @override
  void initState() {
    super.initState();

    widget.broadcastStream.listen((message) {
      MessageData data = decodeMessageData(message);
      if (data.subject == MessageSubject.QUESTION) {
        if (data.action == 'SEND') {
          setState(() {
            currentAnswer = data.content['ANSWER'] ?? '';
          });
        } else if (data.action == 'SHOW_ANSWER') {
          widget.setCurrentDisplayState(DisplayState.answer);
        }
      }
    }, onError: (error) {
      print('WebSocket error: $error');
    }, onDone: () {
      print('WebSocket connection closed');
    });
  }

  @override
  Widget build(BuildContext context) {

    final screenWidth = MediaQuery.of(context).size.width;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Answer:',
            style: TextStyle(fontSize: screenWidth * 0.05, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(
            currentAnswer.isNotEmpty ? currentAnswer : 'Answer not available.',
            style: TextStyle(fontSize: screenWidth * 0.05, fontWeight: FontWeight.bold, color: Colors.green),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
