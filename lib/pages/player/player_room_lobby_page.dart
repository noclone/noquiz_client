import 'package:flutter/material.dart';
import 'package:noquiz_client/components/player_list.dart';
import 'package:noquiz_client/pages/player/player_room_game_page.dart';
import 'package:noquiz_client/utils/room.dart';
import 'package:noquiz_client/utils/socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';


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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showNicknameDialog();
    });

    widget.broadcastStream.listen((message) {
      MessageData data = decodeMessageData(message);
      if (data.subject == MessageSubject.GAME_STATE && data.action == "START") {
        goToNextPage();
      } else if (data.subject == MessageSubject.GAME_STATE && data.action == "ROOM_UPDATE") {
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

    checkRoomState(widget.roomId, goToNextPage);
  }

  void _showNicknameDialog() {
    TextEditingController nicknameController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Enter Your Nickname'),
          content: TextField(
            controller: nicknameController,
            decoration: const InputDecoration(hintText: "Nickname"),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Submit'),
              onPressed: () {
                if (nicknameController.text.isNotEmpty) {
                  Navigator.of(context).pop();
                  onPlayerNameUpdated(nicknameController.text);
                }
              },
            ),
          ],
        );
      },
    );
  }

  void goToNextPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlayerRoomGamePage(
          channel: widget.channel,
          broadcastStream: widget.broadcastStream,
          roomId: widget.roomId,
        ),
      ),
    );
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
              child: PlayerList(
                players: players,
                admin: admin,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
