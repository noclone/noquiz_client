import 'package:flutter/material.dart';
import 'package:web_socket_channel/io.dart';
import 'dart:convert';

import '../../components/player_list.dart';
import 'player_room_game_page.dart';


class PlayerRoomLobbyPage extends StatefulWidget {
  final String roomId;
  final String nickname;
  final String serverIp;

  const PlayerRoomLobbyPage({super.key, required this.roomId, required this.nickname, required this.serverIp});

  @override
  State<PlayerRoomLobbyPage> createState() => _PlayerRoomLobbyPageState();
}

class _PlayerRoomLobbyPageState extends State<PlayerRoomLobbyPage> {
  late IOWebSocketChannel channel;
  late Stream<dynamic> broadcastStream;
  List<Map<String, dynamic>> players = [];
  Map<String, dynamic>? admin;

  @override
  void initState() {
    super.initState();
    channel = IOWebSocketChannel.connect(
      Uri.parse('ws://${widget.serverIp}:8000/ws/${widget.roomId}'),
    );

    channel.ready.then((_) {
      channel.sink.add(jsonEncode({"name": widget.nickname}));
    });

    broadcastStream = channel.stream.asBroadcastStream();

    broadcastStream.listen((message) {
      final data = jsonDecode(message);
      if (data.containsKey('initiated-player-id')) {
        // Save player id
      }
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
            builder: (context) => PlayerRoomGamePage(channel: channel, broadcastStream: broadcastStream,),
          ),
        );
      }
      else if (data.containsKey('players')) {
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
        title: const Row(
          children: [
            Text('Room Lobby'),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Text(
              'Waiting for the admin to start the game',
              style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: PlayerList(players: players, admin: admin),
            ),
          ],
        ),
      ),
    );
  }
}
