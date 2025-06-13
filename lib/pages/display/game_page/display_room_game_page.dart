import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/io.dart';
import '../../../utils/visibility_component.dart';
import 'board_display.dart';
import 'display_state.dart';
import 'question_display.dart';
import 'player_scores_display.dart';
import 'player_answers_display.dart';
import 'right_order_display.dart';
import 'themes_display.dart';
import 'theme_answers_display.dart';
import 'answer_display.dart';
import 'timer_display.dart';

class DisplayRoomGamePage extends StatefulWidget {
  final String roomId;
  final String serverIp;

  const DisplayRoomGamePage({super.key, required this.roomId, required this.serverIp});

  @override
  State<DisplayRoomGamePage> createState() => _DisplayRoomGamePageState();
}

class _DisplayRoomGamePageState extends State<DisplayRoomGamePage> {
  late IOWebSocketChannel channel;
  late Stream<dynamic> broadcastStream;
  DisplayState currentDisplayState = DisplayState.question;

  @override
  void initState() {
    super.initState();
    channel = IOWebSocketChannel.connect(
      Uri.parse('ws://${widget.serverIp}:8000/ws/${widget.roomId}'),
    );

    channel.ready.then((_) {
      channel.sink.add(jsonEncode({"name": "display_${widget.roomId}", "display": true}));
    });

    broadcastStream = channel.stream.asBroadcastStream();
    broadcastStream.listen((message) {
      final data = jsonDecode(message);
      if (data.containsKey('room-deleted')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Admin left the room')),
        );
        Navigator.popUntil(context, ModalRoute.withName('/'));
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
  void dispose() {
    channel.sink.close();
    super.dispose();
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
              visible: currentDisplayState == DisplayState.timer,
              child: TimerDisplay(
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
                  broadcastStream: broadcastStream
              ),
            ),
            buildComponent(
              visible: currentDisplayState == DisplayState.playerAnswers,
              child: PlayerAnswersDisplay(
                  roomId: widget.roomId,
                  setCurrentDisplayState: setCurrentDisplayState,
                  broadcastStream: broadcastStream
              ),
            ),
            buildComponent(
              visible: currentDisplayState == DisplayState.themes,
              child: ThemesDisplay(
                  setCurrentDisplayState: setCurrentDisplayState,
                  broadcastStream: broadcastStream
              ),
            ),
            buildComponent(
              visible: currentDisplayState == DisplayState.themeAnswers,
              child: ThemeAnswersDisplay(
                  setCurrentDisplayState: setCurrentDisplayState,
                  broadcastStream: broadcastStream
              ),
            ),
            buildComponent(
              visible: currentDisplayState == DisplayState.answer,
              child: AnswerDisplay(
                  setCurrentDisplayState: setCurrentDisplayState,
                  broadcastStream: broadcastStream
              ),
            ),
            buildComponent(
              visible: currentDisplayState == DisplayState.board,
              child: BoardDisplay(
                  setCurrentDisplayState: setCurrentDisplayState,
                  broadcastStream: broadcastStream
              ),
            ),
          ],
        ),
      ),
    );
  }
}
