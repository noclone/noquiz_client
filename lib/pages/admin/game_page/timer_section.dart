import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:web_socket_channel/io.dart';

class TimerSection extends StatefulWidget {

  final IOWebSocketChannel channel;
  final Stream<dynamic> broadcastStream;

  const TimerSection({
    super.key,
    required this.channel,
    required this.broadcastStream,
  });

  @override
  State<TimerSection> createState() => _TimerSectionState();
}

class _TimerSectionState extends State<TimerSection> {
  bool isTimerRunning = false;
  final TextEditingController _timerController = TextEditingController();

  void _startTimer() {
    final duration = int.tryParse(_timerController.text) ?? 0;
    if (duration > 0) {
      widget.channel.sink.add(jsonEncode({"start-timer": duration}));
    }
  }

  void _pauseTimer() {
    widget.channel.sink.add(jsonEncode({"pause-timer": true}));
  }

  void _resetTimer() {
    widget.channel.sink.add(jsonEncode({"reset-timer": true}));
  }

  void toggleTimer() {
    setState(() {
      isTimerRunning = !isTimerRunning;
    });
    if (isTimerRunning) {
      _startTimer();
    } else {
      _pauseTimer();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            controller: _timerController,
            decoration: const InputDecoration(
              labelText: 'Enter time in seconds',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: toggleTimer,
            child: Text(isTimerRunning ? 'Pause Timer' : 'Start Timer'),
          ),
          const SizedBox(height: 5),
          ElevatedButton(
            onPressed: () {
              setState(() {
                isTimerRunning = false;
              });
              _resetTimer();
            },
            child: const Text('Reset Timer'),
          ),
        ],
      ),
    );
  }
}
