import 'package:flutter/material.dart';

class TimerSection extends StatefulWidget {
  final TextEditingController timerController;
  final VoidCallback onStartTimer;
  final VoidCallback onPauseTimer;
  final VoidCallback onResetTimer;

  const TimerSection({
    super.key,
    required this.timerController,
    required this.onStartTimer,
    required this.onPauseTimer,
    required this.onResetTimer,
  });

  @override
  State<TimerSection> createState() => _TimerSectionState();
}

class _TimerSectionState extends State<TimerSection> {
  bool isTimerRunning = false;

  void toggleTimer() {
    setState(() {
      isTimerRunning = !isTimerRunning;
    });
    if (isTimerRunning) {
      widget.onStartTimer();
    } else {
      widget.onPauseTimer();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            controller: widget.timerController,
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
              widget.onResetTimer();
            },
            child: const Text('Reset Timer'),
          ),
        ],
      ),
    );
  }
}
