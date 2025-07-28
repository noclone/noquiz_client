import 'package:flutter/material.dart';
import 'package:noquiz_client/components/board.dart';
import 'package:noquiz_client/pages/display/game_page/display_state.dart';
import 'package:noquiz_client/utils/socket.dart';


class BoardDisplay extends StatefulWidget {
  final Function setCurrentDisplayState;
  final Stream<dynamic> broadcastStream;

  const BoardDisplay(
      {super.key,
      required this.setCurrentDisplayState,
      required this.broadcastStream});

  @override
  State<BoardDisplay> createState() => _BoardDisplayState();
}

class _BoardDisplayState extends State<BoardDisplay> {
  List<Map<String, dynamic>> board = [];
  List<bool> imageVisibility = [];

  @override
  void initState() {
    super.initState();

    widget.broadcastStream.listen((message) {
      MessageData data = decodeMessageData(message);
      if (data.subject == MessageSubject.BOARD && data.action == "UPDATE") {
        widget.setCurrentDisplayState(DisplayState.board);
        setState(() {
          board = List<Map<String, dynamic>>.from(data.content['BOARD']);
          imageVisibility = List<bool>.from(data.content['IMAGE_VISIBILITY']);
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
    if (board.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return NQBoard(board: board, imageVisibility: imageVisibility);
  }
}
