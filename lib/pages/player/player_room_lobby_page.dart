import 'package:flutter/material.dart';
import 'package:web_socket_channel/io.dart';
import 'dart:convert';

import '../../components/player_list.dart';
import 'player_room_game_page.dart';


class PlayerRoomLobbyPage extends StatefulWidget {
  final String roomId;
  final String nickname;

  const PlayerRoomLobbyPage({super.key, required this.roomId, required this.nickname});

  @override
  State<PlayerRoomLobbyPage> createState() => _PlayerRoomLobbyPageState();
}

class _PlayerRoomLobbyPageState extends State<PlayerRoomLobbyPage> {
  late IOWebSocketChannel channel;
  List<Map<String, dynamic>> players = [];
  Map<String, dynamic>? admin;

  @override
  void initState() {
    super.initState();
    channel = IOWebSocketChannel.connect(
      Uri.parse('ws://localhost:8000/ws/${widget.roomId}'),
    );

    channel.ready.then((_) {
      channel.sink.add('{"name": "${widget.nickname}"}');
    });

    channel.stream.listen((message) {
      final data = jsonDecode(message);
      if (data.containsKey('room-deleted')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Admin left the room')),
        );
        Navigator.popUntil(context, ModalRoute.withName('/'));
      }
      else if (data.containsKey('start-game')){
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PlayerRoomGamePage(channel: channel,),
          ),
        );
      }
      else {
        setState(() {
          players = List<Map<String, dynamic>>.from(data['players']);
          admin = data['admin'];
        });
      }
    }, onError: (error) {
      print('WebSocket error: $error');
    }, onDone: () {
      print('WebSocket connection closed');
    });
  }

  @override
  void dispose() {
    channel.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Room Lobby'),
            const SizedBox(width: 10),
            Text(
              widget.roomId,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: PlayerList(players: players, admin: admin),
      ),
    );
  }
}
