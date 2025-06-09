import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/io.dart';

import 'buzzes_section.dart';
import 'questions_section.dart';
import 'scores_section.dart';
import 'timer_section.dart';

class AdminRoomGamePage extends StatefulWidget {
  final String roomId;
  final IOWebSocketChannel channel;
  final Stream<dynamic> broadcastStream;
  final List<Map<String, dynamic>> players;

  const AdminRoomGamePage({
    super.key,
    required this.roomId,
    required this.channel,
    required this.broadcastStream,
    required this.players,
  });

  @override
  State<AdminRoomGamePage> createState() => _AdminRoomGamePageState();
}

class _AdminRoomGamePageState extends State<AdminRoomGamePage> {
  List<Map<String, dynamic>> buzzes = [];
  Set<int> correctAnswers = {};
  Set<int> wrongAnswers = {};
  final TextEditingController _timerController = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.broadcastStream.listen((message) {
      final data = jsonDecode(message);
      if (data.containsKey('buzz')) {
        setState(() {
          buzzes.add({
            'name': data['buzz'][0],
            'time': data['buzz'][1],
          });
          buzzes.sort((a, b) => a['time'].compareTo(b['time']));
        });
      }
    });
  }

  void _resetBuzzers() {
    setState(() {
      buzzes.clear();
    });
    widget.channel.sink.add(jsonEncode({"reset-buzzer": true}));
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Game Room: ${widget.roomId}'),
      ),
      body: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: QuestionsSection(
                    roomId: widget.roomId,
                    correctAnswers: correctAnswers,
                    wrongAnswers: wrongAnswers,
                    channel: widget.channel,
                  ),
                ),
                Container(
                  width: 200,
                  decoration: const BoxDecoration(
                    border: Border(left: BorderSide(width: 1)),
                  ),
                  child: DefaultTabController(
                    length: 2,
                    child: Column(
                      children: [
                        const TabBar(
                          tabs: [
                            Tab(text: 'Buzzes'),
                            Tab(text: 'Timer'),
                          ],
                        ),
                        Expanded(
                          child: TabBarView(
                            children: [
                              BuzzesSection(
                                buzzes: buzzes,
                                onResetBuzzers: _resetBuzzers,
                              ),
                              TimerSection(
                                timerController: _timerController,
                                onStartTimer: _startTimer,
                                onPauseTimer: _pauseTimer,
                                onResetTimer: _resetTimer,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          ScoresSection(
            players: widget.players,
            roomId: widget.roomId,
          ),
        ],
      ),
    );
  }
}
