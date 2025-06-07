import 'package:flutter/material.dart';
import 'dart:convert';

import 'package:web_socket_channel/io.dart';

class PlayerRoomGamePage extends StatefulWidget {
  final IOWebSocketChannel channel;
  final Stream<dynamic> broadcastStream;

  const PlayerRoomGamePage({super.key, required this.channel, required this.broadcastStream});

  @override
  State<PlayerRoomGamePage> createState() => _PlayerRoomGamePageState();
}

class _PlayerRoomGamePageState extends State<PlayerRoomGamePage> {
  bool isBuzzerEnabled = true;

  @override
  void initState() {
    super.initState();
    widget.broadcastStream.listen((message) {
      final data = jsonDecode(message);
      if (data.containsKey('reset-buzzer')) {
        setState(() {
          isBuzzerEnabled = true;
        });
      }
    });
  }

  void _onBuzzerPressed() {
    setState(() {
      isBuzzerEnabled = false;
    });
    widget.channel.sink.add('{"buzz": true}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Game Room'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: isBuzzerEnabled ? _onBuzzerPressed : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 30),
          ),
          child: const Text(
            'BUZZER',
            style: TextStyle(fontSize: 24, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
