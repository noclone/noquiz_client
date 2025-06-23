import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:noquiz_client/components/player_list.dart';
import 'package:noquiz_client/pages/admin/game_page/admin_room_game_page.dart';
import 'package:noquiz_client/utils/preferences.dart';
import 'package:noquiz_client/utils/socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';


class AdminRoomLobbyPage extends StatefulWidget {
  final String roomId;
  final String serverIp;

  const AdminRoomLobbyPage({super.key, required this.roomId, required this.serverIp});

  @override
  State<AdminRoomLobbyPage> createState() => _AdminRoomLobbyPageState();
}

class _AdminRoomLobbyPageState extends State<AdminRoomLobbyPage> {
  late WebSocketChannel channel;
  late Stream<dynamic> broadcastStream;
  List<Map<String, dynamic>> players = [];
  Map<String, dynamic>? admin;

  @override
  void initState() {
    super.initState();
    channel = WebSocketChannel.connect(
      Uri.parse('ws://${widget.serverIp}:8000/ws/${widget.roomId}'),
    );
    channel.ready.then((_) {
      getPlayerId().then((playerId) => sendToSocket(channel, MessageSubject.PLAYER_INIT, "INIT_ADMIN", {"name": "Admin", "player_id": playerId}));
    });
    broadcastStream = channel.stream.asBroadcastStream();
    broadcastStream.listen((message) {
      MessageData data = decodeMessageData(message);
      if (data.subject == MessageSubject.GAME_STATE && data.action == "ROOM_UPDATE") {
        setState(() {
          players = List<Map<String, dynamic>>.from(data.content['players']);
          admin = data.content['admin'];
        });
      } else if (data.subject == MessageSubject.PLAYER_INIT) {
        if (data.action == "INIT_SUCCESS") {
          setPreference('player_id', data.content['PLAYER_ID']);
        } else if (data.action == "INIT_FAILED"){
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data.content['REASON'])),
          );
          Navigator.pop(context);
        }
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
    sendToSocket(channel, MessageSubject.GAME_STATE, "START", {});
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminRoomGamePage(
          roomId: widget.roomId,
          channel: channel,
          broadcastStream: broadcastStream,
          players: players,
        ),
      ),
    );
  }

  void _continue() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminRoomGamePage(
          roomId: widget.roomId,
          channel: channel,
          broadcastStream: broadcastStream,
          players: players,
        ),
      ),
    );
  }

  void _deleteRoom() {
    sendToSocket(channel, MessageSubject.GAME_STATE, "DELETE_ROOM", {});
    Navigator.pop(context);
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
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _continue,
                child: const Text('Continue'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _deleteRoom,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                child: const Text('Delete Room'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

