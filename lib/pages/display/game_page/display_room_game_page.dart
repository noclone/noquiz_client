import 'dart:async';
import 'package:flutter/material.dart';
import 'package:noquiz_client/components/visibility_component.dart';
import 'package:noquiz_client/pages/display/game_page/answer_display.dart';
import 'package:noquiz_client/pages/display/game_page/board_display.dart';
import 'package:noquiz_client/pages/display/game_page/display_state.dart';
import 'package:noquiz_client/pages/display/game_page/player_answers_display.dart';
import 'package:noquiz_client/pages/display/game_page/player_scores_display.dart';
import 'package:noquiz_client/pages/display/game_page/question_display.dart';
import 'package:noquiz_client/pages/display/game_page/right_order_display.dart';
import 'package:noquiz_client/pages/display/game_page/theme_answers_display.dart';
import 'package:noquiz_client/pages/display/game_page/themes_display.dart';
import 'package:noquiz_client/pages/display/game_page/timer_display.dart';
import 'package:noquiz_client/utils/socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';


class DisplayRoomGamePage extends StatefulWidget {
  final String roomId;
  final String serverIp;

  const DisplayRoomGamePage({super.key, required this.roomId, required this.serverIp});

  @override
  State<DisplayRoomGamePage> createState() => _DisplayRoomGamePageState();
}

class _DisplayRoomGamePageState extends State<DisplayRoomGamePage> {
  late WebSocketChannel channel;
  late Stream<dynamic> broadcastStream;
  DisplayState currentDisplayState = DisplayState.question;
  DisplayState? previousDisplayState;
  bool showTimer = false;
  bool isTimerOverlay = false;

  @override
  void initState() {
    super.initState();
    channel = WebSocketChannel.connect(
      Uri.parse('ws://${widget.serverIp}:8000/ws/${widget.roomId}'),
    );

    broadcastStream = channel.stream.asBroadcastStream();
    broadcastStream.listen((message) {
      MessageData data = decodeMessageData(message);
      if (data.subject == MessageSubject.GAME_STATE && data.action == "ROOM_CLOSED") {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Admin left the room')),
        );
        Navigator.popUntil(context, ModalRoute.withName('/'));
      } else if (data.subject == MessageSubject.TIMER && data.action == "TOGGLE_VISIBILITY") {
        setState(() {
          showTimer = data.content['SHOW'];
          isTimerOverlay = data.content['OVERLAY'];
          if (showTimer && !isTimerOverlay) {
            previousDisplayState = currentDisplayState;
            currentDisplayState = DisplayState.timer;
          } else if (!showTimer && !isTimerOverlay && previousDisplayState != null) {
            currentDisplayState = previousDisplayState!;
          }
        });
      }
    }, onError: (error) {
      print('WebSocket error: $error');
    }, onDone: () {
      print('WebSocket connection closed');
    });
  }

  void setCurrentDisplayState(DisplayState state) {
    setState(() {
      currentDisplayState = state;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Display Room'),
      ),
      body: Center(
        child: Stack(
          children: [
            buildComponent(
              visible: currentDisplayState == DisplayState.question,
              child: QuestionDisplay(
                setCurrentDisplayState: setCurrentDisplayState,
                broadcastStream: broadcastStream,
              ),
            ),
            buildComponent(
              visible: currentDisplayState == DisplayState.rightOrder,
              child: RightOrderDisplay(
                setCurrentDisplayState: setCurrentDisplayState,
                broadcastStream: broadcastStream,
              ),
            ),
            buildComponent(
              visible: currentDisplayState == DisplayState.playerScores,
              child: PlayerScoresDisplay(
                roomId: widget.roomId,
                setCurrentDisplayState: setCurrentDisplayState,
                broadcastStream: broadcastStream,
              ),
            ),
            buildComponent(
              visible: currentDisplayState == DisplayState.playerAnswers,
              child: PlayerAnswersDisplay(
                roomId: widget.roomId,
                setCurrentDisplayState: setCurrentDisplayState,
                broadcastStream: broadcastStream,
              ),
            ),
            buildComponent(
              visible: currentDisplayState == DisplayState.themes,
              child: ThemesDisplay(
                setCurrentDisplayState: setCurrentDisplayState,
                broadcastStream: broadcastStream,
              ),
            ),
            buildComponent(
              visible: currentDisplayState == DisplayState.themeAnswers,
              child: ThemeAnswersDisplay(
                setCurrentDisplayState: setCurrentDisplayState,
                broadcastStream: broadcastStream,
              ),
            ),
            buildComponent(
              visible: currentDisplayState == DisplayState.answer,
              child: AnswerDisplay(
                setCurrentDisplayState: setCurrentDisplayState,
                broadcastStream: broadcastStream,
              ),
            ),
            buildComponent(
              visible: currentDisplayState == DisplayState.board,
              child: BoardDisplay(
                setCurrentDisplayState: setCurrentDisplayState,
                broadcastStream: broadcastStream,
              ),
            ),
            showTimer
                ? isTimerOverlay
                  ? Positioned(
                    top: 20.0,
                    right: 20.0,
                    child: TimerDisplay(
                      broadcastStream: broadcastStream,
                    ),
                  )
                  : TimerDisplay(
                    broadcastStream: broadcastStream,
                  )
                : Container(),
          ],
        ),
      ),
    );
  }
}

