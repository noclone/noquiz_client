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
  String? expectedAnswerType;
  final TextEditingController _numberController = TextEditingController();

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
      if (data.containsKey('new-question')) {
        setState(() {
          expectedAnswerType = data['expected_answer_type'];
        });
      }
    });
  }

  void _onBuzzerPressed() {
    setState(() {
      isBuzzerEnabled = false;
    });
    widget.channel.sink.add(jsonEncode({"buzz": true}));
  }

  void _submitNumber() {
    final number = _numberController.text;
    if (number.isNotEmpty) {
      widget.channel.sink.add(jsonEncode({"player-answer": number}));
      _numberController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Game Room'),
      ),
      body: Center(
        child: expectedAnswerType == 'NUMBER'
            ? Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _numberController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Answer',
                ),
              ),
            ),
            ElevatedButton(
              onPressed: _submitNumber,
              child: const Text('Submit'),
            ),
          ],
        )
            : ElevatedButton(
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
