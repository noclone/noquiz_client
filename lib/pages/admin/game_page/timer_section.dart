import 'package:flutter/material.dart';
import 'package:noquiz_client/utils/socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class TimerSection extends StatefulWidget {

  final WebSocketChannel channel;
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
  bool isTimerVisible = false;
  bool isOverlayMode = false;
  final TextEditingController _timerController = TextEditingController();

  void _startTimer() {
    final duration = int.tryParse(_timerController.text) ?? 0;
    if (duration > 0) {
      sendToSocket(widget.channel, MessageSubject.TIMER, "START", {"duration": duration});
    }
  }

  void _pauseTimer() {
    sendToSocket(widget.channel, MessageSubject.TIMER, "PAUSE", {});
  }

  void _resetTimer() {
    sendToSocket(widget.channel, MessageSubject.TIMER, "RESET", {});
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

  void toggleTimerVisibility() {
    setState(() {
      isTimerVisible = !isTimerVisible;
    });
    sendToSocket(widget.channel, MessageSubject.TIMER, "TOGGLE_VISIBILITY", {"SHOW": isTimerVisible, "OVERLAY": isOverlayMode});
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Overlay Mode'),
              Switch(
                value: isOverlayMode,
                onChanged: (value) {
                  setState(() {
                    isOverlayMode = value;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: toggleTimerVisibility,
            child: Text(isTimerVisible ? 'Hide Timer' : 'Show Timer'),
          ),
          const SizedBox(height: 10),
          Visibility(
            visible: isTimerVisible,
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
          ),
        ],
      ),
    );
  }
}

