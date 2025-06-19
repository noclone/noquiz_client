import 'package:flutter/material.dart';
import 'package:noquiz_client/components/visibility_component.dart';
import 'package:noquiz_client/pages/player/answer_type.dart';
import 'package:noquiz_client/pages/player/buzzer.dart';
import 'package:noquiz_client/pages/player/number_input.dart';
import 'package:noquiz_client/pages/player/right_order.dart';
import 'package:noquiz_client/utils/preferences.dart';
import 'package:noquiz_client/utils/socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';


class PlayerRoomGamePage extends StatefulWidget {
  final WebSocketChannel channel;
  final Stream<dynamic> broadcastStream;
  final String roomId;

  const PlayerRoomGamePage({super.key, required this.channel, required this.broadcastStream, required this.roomId});

  @override
  State<PlayerRoomGamePage> createState() => _PlayerRoomGamePageState();
}

class _PlayerRoomGamePageState extends State<PlayerRoomGamePage> {
  AnswerType expectedAnswerType = AnswerType.none;

  @override
  void initState() {
    super.initState();
    widget.broadcastStream.listen((message) {
      MessageData data = decodeMessageData(message);
      if (data.subject == MessageSubject.QUESTION) {
        if (data.action == "SEND"){
          if (data.content['EXPECTED_ANSWER_TYPE'] == 'NONE') {
            setExpectedAnswerType(AnswerType.none);
          } else if (data.content['EXPECTED_ANSWER_TYPE'] == 'NUMBER') {
            setExpectedAnswerType(AnswerType.number);
          }
        }
      } else if (data.subject == MessageSubject.RIGHT_ORDER) {
        if (data.action == "SEND"){
          setExpectedAnswerType(AnswerType.rightOrder);
        }
      }
    }, onError: (error) {
      print('WebSocket error: $error');
    }, onDone: () {
      print('WebSocket connection closed');
    });

    resumeSavedState();
  }

  void resumeSavedState() async {
    String savedValue = await getPreference('expected_answer_type');

    setState(() {
      expectedAnswerType = stringToAnswerType(savedValue);
    });
    if (expectedAnswerType == AnswerType.rightOrder)
    {
      sendToSocket(widget.channel, MessageSubject.RIGHT_ORDER, "REQUEST", {});
    }
  }

  void setExpectedAnswerType(AnswerType type) {
    setState(() {
      expectedAnswerType = type;
    });
    setPreference('expected_answer_type', type.toString());
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
