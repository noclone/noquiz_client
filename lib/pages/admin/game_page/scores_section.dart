import 'package:flutter/material.dart';
import 'package:noquiz_client/utils/socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';


class ScoresSection extends StatefulWidget {
  final List<Map<String, dynamic>> players;
  final String roomId;
  final WebSocketChannel channel;
  final Stream<dynamic> broadcastStream;

  const ScoresSection({
    super.key,
    required this.players,
    required this.roomId,
    required this.channel,
    required this.broadcastStream,
  });

  @override
  State<ScoresSection> createState() => _ScoresSectionState();
}

class _ScoresSectionState extends State<ScoresSection> {
  void incrementScore(int index) {
    setState(() {
      widget.players[index]['score']++;
    });
    sendToSocket(widget.channel, MessageSubject.PLAYER_SCORE, "INCREASE", {"PLAYER_ID": widget.players[index]["id"], "VALUE": 1});
  }

  void decrementScore(int index) {
    setState(() {
      widget.players[index]['score']--;
    });
    sendToSocket(widget.channel, MessageSubject.PLAYER_SCORE, "DECREASE", {"PLAYER_ID": widget.players[index]["id"], "VALUE": 1});
  }

  @override
  void initState() {
    super.initState();

    widget.broadcastStream.listen((message) {
      MessageData data = decodeMessageData(message);
      if (data.subject == MessageSubject.PLAYER_SCORE) {
        if (data.action == "UPDATE") {
          final playerId = data.content["PLAYER_ID"];
          final value = data.content["VALUE"];
          setState(() {
            widget.players.firstWhere((player) => player["id"] == playerId)['score'] = value;
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(width: 1)),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: widget.players.length,
        itemBuilder: (context, index) {
          final player = widget.players[index];
          return Container(
            width: 150,
            margin: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => incrementScore(index),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(player['name']),
                ),
                Text('Score: ${player['score']}'),
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: () => decrementScore(index),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
