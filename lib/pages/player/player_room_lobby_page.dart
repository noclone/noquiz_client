import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:noquiz_client/components/player_list.dart';
import 'package:noquiz_client/pages/player/player_room_game_page.dart';
import 'package:noquiz_client/utils/preferences.dart';
import 'package:noquiz_client/utils/socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';


class PlayerRoomLobbyPage extends StatefulWidget {
  final String roomId;
  final WebSocketChannel channel;
  final Stream<dynamic> broadcastStream;

  const PlayerRoomLobbyPage({super.key, required this.roomId, required this.channel, required this.broadcastStream});

  @override
  State<PlayerRoomLobbyPage> createState() => _PlayerRoomLobbyPageState();
}

class _PlayerRoomLobbyPageState extends State<PlayerRoomLobbyPage> {
  List<Map<String, dynamic>> players = [];
  Map<String, dynamic>? admin;

  void checkRoomState() async {
    final serverIp = await getServerIpAddress();
    final url = Uri.parse('http://$serverIp:8000/api/rooms/${widget.roomId}');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data["started"]) {
        goToNextPage();
      }
    } else {
      print('Failed to load question');
    }
  }

  void goToNextPage(){
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlayerRoomGamePage(channel: widget.channel, broadcastStream: widget.broadcastStream, roomId: widget.roomId),
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    widget.broadcastStream.listen((message) {
      MessageData data = decodeMessageData(message);
      if (data.subject == MessageSubject.GAME_STATE && data.action == "START"){
        goToNextPage();
      }
      else if (data.subject == MessageSubject.GAME_STATE && data.action == "ROOM_UPDATE") {
        setState(() {
          players = List<Map<String, dynamic>>.from(data.content['players']);
          admin = data.content['admin'];
        });
      }
    }, onError: (error) {
      print('WebSocket error: $error');
    }, onDone: () {
      print('WebSocket connection closed');
    });

    checkRoomState();
  }

  void onPlayerNameUpdated(String newName) {
    sendToSocket(widget.channel, MessageSubject.PLAYER_NAME, "UPDATE", {"PLAYER_NAME": newName});
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
              child: PlayerList(broadcastStream: widget.broadcastStream, players: players, admin: admin, onPlayerNameUpdated: onPlayerNameUpdated,),
            ),
          ],
        ),
      ),
    );
  }
}
