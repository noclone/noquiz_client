import 'package:flutter/material.dart';
import 'package:web_socket_channel/io.dart';

class PlayerRoomGamePage extends StatelessWidget {
  final IOWebSocketChannel channel;

  const PlayerRoomGamePage({super.key, required this.channel});

  void _onBuzzerPressed() {
    channel.sink.add('{"buzz": true}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Game Room'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: _onBuzzerPressed,
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
