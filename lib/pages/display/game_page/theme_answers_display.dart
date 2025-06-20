import 'package:flutter/material.dart';
import 'package:noquiz_client/pages/display/game_page/display_state.dart';
import 'package:noquiz_client/utils/socket.dart';

class ThemeAnswersDisplay extends StatefulWidget {
  final Function setCurrentDisplayState;
  final Stream<dynamic> broadcastStream;

  const ThemeAnswersDisplay({
    super.key,
    required this.setCurrentDisplayState,
    required this.broadcastStream,
  });

  @override
  State<ThemeAnswersDisplay> createState() => _ThemeAnswersDisplayState();
}

class _ThemeAnswersDisplayState extends State<ThemeAnswersDisplay> {
  List<dynamic> themeAnswers = [];

  @override
  void initState() {
    super.initState();

    widget.broadcastStream.listen((message) {
      MessageData data = decodeMessageData(message);
      if (data.subject == MessageSubject.THEMES && data.action == 'ANSWERS') {
        setState(() {
          themeAnswers = data.content['ANSWERS'];
        });
        widget.setCurrentDisplayState(DisplayState.themeAnswers);
      }
    }, onError: (error) {
      print('WebSocket error: $error');
    }, onDone: () {
      print('WebSocket connection closed');
    });
  }

  @override
  Widget build(BuildContext context) {
    int correctCount =
        themeAnswers.where((answer) => answer['isCorrect']).length;

    final screenWidth = MediaQuery.of(context).size.width;

    return Stack(
      children: [
        Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Correct Answers: $correctCount',
                    style: TextStyle(
                        fontSize: screenWidth * 0.03,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: screenWidth * 0.7,
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: themeAnswers.length,
                      itemBuilder: (BuildContext context, int index) {
                        final answer = themeAnswers[index];
                        return Card(
                            margin: const EdgeInsets.all(8.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20.0),
                            ),
                            child: ListTile(
                              title: Text(
                                textAlign: TextAlign.center,
                                answer['question'],
                                style: TextStyle(
                                  fontSize: screenWidth * 0.04,
                                  color: answer['isCorrect']
                                      ? Colors.green
                                      : Colors.red,
                                ),
                              ),
                              subtitle: Text(
                                textAlign: TextAlign.center,
                                answer['answer'],
                                style: TextStyle(fontSize: screenWidth * 0.04),
                              ),
                            ));
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
