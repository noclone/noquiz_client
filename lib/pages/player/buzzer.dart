import 'package:flutter/material.dart';
import 'package:noquiz_client/pages/player/answer_type.dart';
import 'package:noquiz_client/utils/socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:vibration/vibration.dart';

class BuzzerComponent extends StatefulWidget {
  final WebSocketChannel channel;
  final Stream<dynamic> broadcastStream;
  final Function setExpectedAnswerType;

  const BuzzerComponent({
    super.key,
    required this.channel,
    required this.broadcastStream,
    required this.setExpectedAnswerType,
  });

  @override
  State<BuzzerComponent> createState() => _BuzzerComponentState();
}

class _BuzzerComponentState extends State<BuzzerComponent> {
  bool isBuzzerEnabled = true;

  @override
  void initState() {
    super.initState();
    widget.broadcastStream.listen((message) {
      MessageData data = decodeMessageData(message);
      if (data.subject == MessageSubject.BUZZER && data.action == "RESET") {
        setState(() {
          widget.setExpectedAnswerType(AnswerType.none);
          isBuzzerEnabled = true;
        });
      }
    }, onError: (error) {
      print('WebSocket error: $error');
    }, onDone: () {
      print('WebSocket connection closed');
    });
  }

  void _onBuzzerPressed() async {
    setState(() {
      isBuzzerEnabled = false;
    });
    if (await Vibration.hasVibrator()) {
      Vibration.vibrate(duration: 400);
    }
    sendToSocket(widget.channel, MessageSubject.BUZZER, "ADD", {});
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final buttonSize = screenSize.width * 0.5;

    return Center(
      child: SizedBox(
        width: buttonSize,
        height: buttonSize,
        child: ElevatedButton(
          onPressed: isBuzzerEnabled ? _onBuzzerPressed : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            shape: const CircleBorder(),
            padding: EdgeInsets.zero,
          ),
          child: null
        ),
      ),
    );
  }
}
