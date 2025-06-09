import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:web_socket_channel/io.dart';
import 'dart:convert';

import '../../components/player_list.dart';
import 'admin_room_game_page.dart';

class AdminRoomLobbyPage extends StatefulWidget {
  final String roomId;
  final String nickname;

  const AdminRoomLobbyPage({super.key, required this.roomId, required this.nickname});

  @override
  State<AdminRoomLobbyPage> createState() => _AdminRoomLobbyPageState();
}

class _AdminRoomLobbyPageState extends State<AdminRoomLobbyPage> {
  late IOWebSocketChannel channel;
  late Stream<dynamic> broadcastStream;
  List<Map<String, dynamic>> players = [];
  Map<String, dynamic>? admin;

  @override
  void initState() {
    super.initState();
    channel = IOWebSocketChannel.connect(
      Uri.parse('ws://localhost:8000/ws/${widget.roomId}'),
    );

    channel.ready.then((_) {
      channel.sink.add(jsonEncode({"name": widget.nickname, "admin": true}));
    });

    broadcastStream = channel.stream.asBroadcastStream();

    broadcastStream.listen((message) {
      final data = jsonDecode(message);
      if (data.containsKey('players')){
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

  Future<void> _copyToClipboard() async {
    await Clipboard.setData(ClipboardData(text: widget.roomId));
  }

  void _startGame() {
    channel.sink.add(jsonEncode({"start-game": true}));
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminRoomGamePage(roomId: widget.roomId, channel: channel, broadcastStream: broadcastStream),
      ),
    );
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
            IconButton(
              icon: const Icon(Icons.copy, size: 18),
              onPressed: _copyToClipboard,
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: PlayerList(players: players, admin: admin),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _startGame,
                child: const Text('Start Game'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
