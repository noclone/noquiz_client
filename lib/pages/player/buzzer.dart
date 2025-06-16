import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:noquiz_client/pages/player/answer_type.dart';
import 'package:web_socket_channel/io.dart';
import 'package:vibration/vibration.dart';


class BuzzerComponent extends StatefulWidget {
  final IOWebSocketChannel channel;
  final Stream<dynamic> broadcastStream;
  final Function setExpectedAnswerType;

  const BuzzerComponent({super.key, required this.channel, required this.broadcastStream, required this.setExpectedAnswerType});

  @override
  State<BuzzerComponent> createState() => _BuzzerComponentState();
}

class _BuzzerComponentState extends State<BuzzerComponent> {

  bool isBuzzerEnabled = true;

  @override
  void initState() {
    super.initState();
    widget.broadcastStream.listen((message) {
      final data = jsonDecode(message);
      if (data.containsKey('reset-buzzer')) {
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
    widget.channel.sink.add(jsonEncode({"buzz": true}));
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isBuzzerEnabled ? _onBuzzerPressed : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red,
        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 30),
      ),
      child: const Text(
        'BUZZER',
        style: TextStyle(fontSize: 24, color: Colors.white),
      ),
    );
  }
}
