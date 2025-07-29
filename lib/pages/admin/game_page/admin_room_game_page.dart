import 'package:flutter/material.dart';
import 'package:noquiz_client/components/appbar.dart';
import 'package:noquiz_client/pages/admin/game_page/buzzes_section.dart';
import 'package:noquiz_client/pages/admin/game_page/scores_section.dart';
import 'package:noquiz_client/pages/admin/game_page/timer_section.dart';
import 'package:noquiz_client/utils/colors.dart';
import 'package:noquiz_client/utils/socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:noquiz_client/pages/admin/game_page/modes_section.dart';

class AdminRoomGamePage extends StatefulWidget {
  final String roomId;
  final WebSocketChannel channel;
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: NQAppBar(
        title: 'Game Room: ${widget.roomId}',
        actions: [
          IconButton(
            icon: const Icon(Icons.people),
            onPressed: () {
              sendToSocket(widget.channel, MessageSubject.PLAYER_ANSWER, "SHOW", const {});
            },
            tooltip: 'Show Players Answers',
          ),
          IconButton(
            icon: const Icon(Icons.score),
            onPressed: () {
              sendToSocket(widget.channel, MessageSubject.PLAYER_SCORE, "SHOW", const {});
            },
            tooltip: 'Show Players Scores',
          ),
        ],),
      body: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: ModesSection(
                    roomId: widget.roomId,
                    channel: widget.channel,
                  ),
                ),
                Container(
                  width: 200,
                  decoration: BoxDecoration(
                    color: primaryColor,
                    border: const Border(
                      left: BorderSide(
                        color: secondaryColor,
                        width: 2.0,),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: secondaryColor.withAlpha(127),
                        spreadRadius: 2,
                        blurRadius: 7,
                        offset: const Offset(0, 0),
                      ),
                    ],
                  ),
                  child: DefaultTabController(
                    length: 2,
                    child: Column(
                      children: [
                        TabBar(
                          indicatorColor: secondaryColor,
                          labelColor: secondaryColor,
                          unselectedLabelColor: textPrimaryColor,
                          tabs: const [
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
            channel: widget.channel,
            broadcastStream: widget.broadcastStream,
          ),
        ],
      ),
    );
  }
}
