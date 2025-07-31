import 'package:flutter/material.dart';
import 'package:noquiz_client/components/color_manager.dart';
import 'package:noquiz_client/components/title_text.dart';
import 'package:noquiz_client/pages/display/game_page/display_state.dart';
import 'package:noquiz_client/utils/socket.dart';
import 'package:provider/provider.dart';

class PlayerAnswersDisplay extends StatefulWidget {
  final Function setCurrentDisplayState;
  final Stream<dynamic> broadcastStream;

  const PlayerAnswersDisplay({
    super.key,
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
      } else if (data.subject == MessageSubject.PLAYER_ANSWER && data.action == 'SHOW') {
        players = List<Map<String, dynamic>>.from(data.content['PLAYERS'])..shuffle();
        widget.setCurrentDisplayState(DisplayState.playerAnswers);
      }
    }, onError: (error) {
      print('WebSocket error: $error');
    }, onDone: () {
      print('WebSocket connection closed');
    });
  }

  void sort_players() {
    setState(() {
      players.sort((a, b) {
        final aAnswer = int.tryParse(a['current_answer'].toString()) ?? 0;
        final bAnswer = int.tryParse(b['current_answer'].toString()) ?? 0;
        final correct = int.tryParse(currentAnswer) ?? 0;

        final aDiff = (aAnswer - correct).abs();
        final bDiff = (bAnswer - correct).abs();

        return aDiff.compareTo(bDiff);
      });
    });
  }


  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    int crossAxisCount = screenWidth > 600 ? 3 : 2;

    final colorManager = Provider.of<ColorManager>(context);
    return Center(
      child: Container(
        padding: EdgeInsets.all(screenWidth * 0.05),
        decoration: BoxDecoration(
          color: colorManager.currentColors.primaryColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: colorManager.currentColors.secondaryColor, width: 3),
          boxShadow: [
            BoxShadow(
              color: colorManager.currentColors.secondaryColor.withValues(alpha: 0.5),
              spreadRadius: screenWidth * 0.0125,
              blurRadius: screenWidth * 0.0175,
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
            NQTitleText(text: 'Player Answers', fontSize: screenWidth * 0.03,),
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
                    shadows: [
                      Shadow(
                        color: Colors.green.withAlpha(127),
                        blurRadius: 10,
                        offset: const Offset(2, 2),
                      ),
                    ]
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
                    sort_players();
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
                            color: colorManager.currentColors.textPrimaryColor
                          ),
                        ),
                        const SizedBox(width: 20),
                        NQTitleText(text: player['current_answer'] ?? 'No answer', fontSize: screenWidth * 0.035,),
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