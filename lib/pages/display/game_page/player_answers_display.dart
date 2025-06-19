import 'package:flutter/material.dart';
import 'package:noquiz_client/pages/display/game_page/display_state.dart';
import 'package:noquiz_client/utils/socket.dart';

class PlayerAnswersDisplay extends StatefulWidget {
  final String roomId;
  final Function setCurrentDisplayState;
  final Stream<dynamic> broadcastStream;

  const PlayerAnswersDisplay({
    super.key,
    required this.roomId,
    required this.setCurrentDisplayState,
    required this.broadcastStream,
  });

  @override
  State<PlayerAnswersDisplay> createState() => _PlayerAnswersDisplayState();
}

class _PlayerAnswersDisplayState extends State<PlayerAnswersDisplay> {
  bool showAnswer = false;
  List<Map<String, dynamic>> players = [];
  String currentAnswer = '';

  @override
  void initState() {
    super.initState();

    widget.broadcastStream.listen((message) {
      MessageData data = decodeMessageData(message);
      if (data.subject == MessageSubject.QUESTION && data.action == 'SEND') {
        setState(() {
          currentAnswer = data.content['ANSWER'] ?? '';
        });
      } else if (data.subject == MessageSubject.PLAYER_NUMBER_ANSWER && data.action == 'SHOW') {
        players = List<Map<String, dynamic>>.from(data.content['PLAYERS']);
        widget.setCurrentDisplayState(DisplayState.playerAnswers);
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
    final screenHeight = MediaQuery.of(context).size.height;

    int crossAxisCount = screenWidth > 600 ? 3 : 2;

    return Center(
      child: Container(
        padding: EdgeInsets.all(screenWidth * 0.05),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.5),
              spreadRadius: 5,
              blurRadius: 7,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        constraints: BoxConstraints(
          maxWidth: screenWidth * 0.9,
          maxHeight: screenHeight * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Player Answers',
              style: TextStyle(
                fontSize: screenWidth * 0.03,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: screenHeight * 0.02),
            if (showAnswer && currentAnswer.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(bottom: screenHeight * 0.02),
                child: Text(
                  'Answer: $currentAnswer',
                  style: TextStyle(
                    fontSize: screenWidth * 0.04,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ),
            if (!showAnswer && currentAnswer.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(bottom: screenHeight * 0.02),
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      showAnswer = true;
                    });
                  },
                  child: Text(
                    'Show Answer',
                    style: TextStyle(fontSize: screenWidth * 0.03),
                  ),
                ),
              ),
            Expanded(
              child: GridView.builder(
                shrinkWrap: true,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 3,
                ),
                itemCount: players.length,
                itemBuilder: (context, index) {
                  final player = players[index];
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          player['name'],
                          style: TextStyle(
                            fontSize: screenWidth * 0.03,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          player['current_answer'] ?? 'No answer',
                          style: TextStyle(
                            fontSize: screenWidth * 0.035,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}