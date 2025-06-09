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

  @override
  void initState() {
    super.initState();
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
                                channel: widget.channel,
                                broadcastStream: widget.broadcastStream,
                              ),
                              TimerSection(
                                channel: widget.channel,
                                broadcastStream: widget.broadcastStream,
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
