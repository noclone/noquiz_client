import 'package:flutter/material.dart';
import 'package:noquiz_client/pages/display/game_page/display_state.dart';
import 'package:noquiz_client/utils/socket.dart';

class PlayerScoresDisplay extends StatefulWidget {
  final Function setCurrentDisplayState;
  final Stream<dynamic> broadcastStream;

  const PlayerScoresDisplay({
    super.key,
    required this.setCurrentDisplayState,
    required this.broadcastStream,
  });

  @override
  State<PlayerScoresDisplay> createState() => _PlayerScoresDisplayState();
}

class _PlayerScoresDisplayState extends State<PlayerScoresDisplay> {
  List<Map<String, dynamic>> players = [];

  @override
  void initState() {
    super.initState();
    widget.broadcastStream.listen((message) {
      MessageData data = decodeMessageData(message);
      if (data.subject == MessageSubject.PLAYER_SCORE && data.action == 'SHOW') {
        setState(() {
          players = List<Map<String, dynamic>>.from(data.content['PLAYERS']);
          players.sort((a, b) => b['score'].compareTo(a['score']));
          widget.setCurrentDisplayState(DisplayState.playerScores);
        });
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

    return Center(
      child: Container(
        padding: EdgeInsets.all(screenWidth * 0.05),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.5),
              spreadRadius: screenWidth * 0.0125,
              blurRadius: screenWidth * 0.0175,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        constraints: BoxConstraints(maxWidth: screenWidth * 0.7),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Player Scores',
              style: TextStyle(
                fontSize: screenWidth * 0.04,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: players.length,
                itemBuilder: (context, index) {
                  final player = players[index];
                  return Container(
                    padding: EdgeInsets.symmetric(vertical: screenHeight * 0.01),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          player['name'],
                          style: TextStyle(fontSize: screenWidth * 0.05),
                        ),
                        SizedBox(width: screenWidth * 0.025),
                        Text(
                          player['score'].toString(),
                          style: TextStyle(
                            fontSize: screenWidth * 0.05,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
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
