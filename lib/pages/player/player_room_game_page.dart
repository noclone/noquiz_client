import 'package:flutter/material.dart';
import 'package:noquiz_client/pages/player/right_order.dart';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../utils/visibility_component.dart';
import 'answer_type.dart';
import 'number_input.dart';
import 'buzzer.dart';


class PlayerRoomGamePage extends StatefulWidget {
  final WebSocketChannel channel;
  final Stream<dynamic> broadcastStream;

  const PlayerRoomGamePage({super.key, required this.channel, required this.broadcastStream});

  @override
  State<PlayerRoomGamePage> createState() => _PlayerRoomGamePageState();
}

class _PlayerRoomGamePageState extends State<PlayerRoomGamePage> {
  AnswerType expectedAnswerType = AnswerType.none;

  @override
  void initState() {
    super.initState();
    widget.broadcastStream.listen((message) {
      final data = jsonDecode(message);
      if (data.containsKey('new-question')) {
        setState(() {
          if (data['expected_answer_type'] == 'NONE') {
            expectedAnswerType = AnswerType.none;
          } else if (data['expected_answer_type'] == 'NUMBER') {
            expectedAnswerType = AnswerType.number;
          }
        });
      } else if (data.containsKey('right-order')) {
        setState(() {
          expectedAnswerType = AnswerType.rightOrder;
        });
      }
    }, onError: (error) {
      print('WebSocket error: $error');
    }, onDone: () {
      print('WebSocket connection closed');
    });
  }

  void setExpectedAnswerType(AnswerType type) {
    setState(() {
      expectedAnswerType = type;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Game Room'),
      ),
      body: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            buildComponent(
              visible: expectedAnswerType == AnswerType.none,
              child: BuzzerComponent(
                channel: widget.channel,
                broadcastStream: widget.broadcastStream,
                setExpectedAnswerType: setExpectedAnswerType,
              ),
            ),
            buildComponent(
              visible: expectedAnswerType == AnswerType.number,
              child: NumberInputComponent(
                channel: widget.channel,
              ),
            ),
            buildComponent(
              visible: expectedAnswerType == AnswerType.rightOrder,
              child: RightOrder(
                channel: widget.channel,
                broadcastStream: widget.broadcastStream,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
