import 'package:flutter/material.dart';
import 'package:noquiz_client/components/color_manager.dart';
import 'package:noquiz_client/components/textfield.dart';
import 'package:noquiz_client/utils/socket.dart';
import 'package:provider/provider.dart';
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
      sendToSocket(widget.channel, MessageSubject.TIMER, "START", {"DURATION": duration});
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
    final colorManager = Provider.of<ColorManager>(context);
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Overlay Mode', style: TextStyle(color: colorManager.currentColors.textPrimaryColor),),
              Switch(
                activeColor: colorManager.currentColors.secondaryColor,
                activeTrackColor: colorManager.currentColors.secondaryColor.withAlpha(127),
                inactiveThumbColor: colorManager.currentColors.textPrimaryColor,
                inactiveTrackColor: colorManager.currentColors.textPrimaryColor.withAlpha(127),
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
            child: Text(isTimerVisible ? 'Hide Timer' : 'Show Timer', style: TextStyle(color: colorManager.currentColors.textPrimaryColor),),
          ),
          const SizedBox(height: 10),
          Visibility(
            visible: isTimerVisible,
            child: Column(
              children: [
                NQTextField(controller: _timerController, labelText: 'Enter time in seconds', keyboardType: TextInputType.number,),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: toggleTimer,
                  child: Text(isTimerRunning ? 'Pause Timer' : 'Start Timer', style: TextStyle(color: colorManager.currentColors.textPrimaryColor),),
                ),
                const SizedBox(height: 5),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      isTimerRunning = false;
                    });
                    _resetTimer();
                  },
                  child: Text('Reset Timer', style: TextStyle(color: colorManager.currentColors.textPrimaryColor),),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

