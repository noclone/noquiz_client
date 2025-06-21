import 'dart:async';
import 'package:flutter/material.dart';
import 'package:noquiz_client/components/visibility_component.dart';
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
  final WebSocketChannel channel;
  final Stream<dynamic> broadcastStream;

  const DisplayRoomGamePage(
      {super.key, required this.channel, required this.broadcastStream});

  @override
  State<DisplayRoomGamePage> createState() => _DisplayRoomGamePageState();
}

class _DisplayRoomGamePageState extends State<DisplayRoomGamePage> {
  DisplayState currentDisplayState = DisplayState.question;
  DisplayState? previousDisplayState;
  bool showTimer = false;
  bool isTimerOverlay = false;

  @override
  void initState() {
    super.initState();

    widget.broadcastStream.listen((message) {
      MessageData data = decodeMessageData(message);
      if (data.subject == MessageSubject.GAME_STATE &&
          data.action == "ROOM_CLOSED") {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Admin left the room')),
        );
        Navigator.popUntil(context, ModalRoute.withName('/'));
      } else if (data.subject == MessageSubject.TIMER &&
          data.action == "TOGGLE_VISIBILITY") {
        setState(() {
          showTimer = data.content['SHOW'];
          isTimerOverlay = data.content['OVERLAY'];
          if (showTimer && !isTimerOverlay) {
            previousDisplayState = currentDisplayState;
            currentDisplayState = DisplayState.timer;
          } else if (!showTimer &&
              !isTimerOverlay &&
              previousDisplayState != null) {
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
      showTimer = false;
      currentDisplayState = state;
    });
  }

  void showTimerOverlay(bool val) {
    setState(() {
      showTimer = val;
      isTimerOverlay = val;
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
                channel: widget.channel,
                broadcastStream: widget.broadcastStream,
                showTimerOverlay: showTimerOverlay,
              ),
            ),
            buildComponent(
              visible: currentDisplayState == DisplayState.rightOrder,
              child: RightOrderDisplay(
                setCurrentDisplayState: setCurrentDisplayState,
                broadcastStream: widget.broadcastStream,
              ),
            ),
            buildComponent(
              visible: currentDisplayState == DisplayState.playerScores,
              child: PlayerScoresDisplay(
                setCurrentDisplayState: setCurrentDisplayState,
                broadcastStream: widget.broadcastStream,
              ),
            ),
            buildComponent(
              visible: currentDisplayState == DisplayState.playerAnswers,
              child: PlayerAnswersDisplay(
                setCurrentDisplayState: setCurrentDisplayState,
                broadcastStream: widget.broadcastStream,
              ),
            ),
            buildComponent(
              visible: currentDisplayState == DisplayState.themes,
              child: ThemesDisplay(
                setCurrentDisplayState: setCurrentDisplayState,
                broadcastStream: widget.broadcastStream,
              ),
            ),
            buildComponent(
              visible: currentDisplayState == DisplayState.themeAnswers,
              child: ThemeAnswersDisplay(
                setCurrentDisplayState: setCurrentDisplayState,
                broadcastStream: widget.broadcastStream,
              ),
            ),
            buildComponent(
              visible: currentDisplayState == DisplayState.board,
              child: BoardDisplay(
                setCurrentDisplayState: setCurrentDisplayState,
                broadcastStream: widget.broadcastStream,
              ),
            ),
            Positioned(
              top: 20.0,
              right: 20.0,
              child: Visibility(
                visible: showTimer && isTimerOverlay,
                maintainState: true,
                maintainAnimation: true,
                maintainSize: true,
                child: TimerDisplay(
                  broadcastStream: widget.broadcastStream,
                ),
              ),
            ),
            buildComponent(
                visible: showTimer && !isTimerOverlay,
                child: TimerDisplay(
                  broadcastStream: widget.broadcastStream,
                )),
          ],
        ),
      ),
    );
  }
}
