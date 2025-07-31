import 'package:flutter/material.dart';
import 'package:noquiz_client/components/color_manager.dart';
import 'package:noquiz_client/pages/player/answer_type.dart';
import 'package:noquiz_client/utils/socket.dart';
import 'package:provider/provider.dart';
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
    final colorManager = Provider.of<ColorManager>(context);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: 20.0),
          child: Text(
            "Press the buzzer when you have the answer!",
            style: TextStyle(
              fontSize: 20,
              color: colorManager.currentColors.textPrimaryColor,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 20),
        Center(
          child: SizedBox(
            width: buttonSize,
            height: buttonSize,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: isBuzzerEnabled
                      ? [
                    Colors.orange.shade700,
                    Colors.orange.shade400,
                    Colors.orange.shade200,
                    Colors.orange.shade100,
                  ]
                      : [
                    Colors.blue.shade700,
                    Colors.blue.shade400,
                    Colors.blue.shade200,
                    Colors.blue.shade100,
                  ],
                  stops: [0.1, 0.4, 0.7, 0.9],
                ),
                boxShadow: [
                  BoxShadow(
                    color: isBuzzerEnabled
                        ? Colors.orange.withAlpha(127)
                        : Colors.blue.withAlpha(127),
                    spreadRadius: 10,
                    blurRadius: 20,
                    offset: Offset(0, 0),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: isBuzzerEnabled ? _onBuzzerPressed : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: CircleBorder(),
                  padding: EdgeInsets.zero,
                ),
                child: null,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
