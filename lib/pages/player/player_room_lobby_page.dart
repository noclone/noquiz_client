import 'package:flutter/material.dart';
import 'package:noquiz_client/components/appbar.dart';
import 'package:noquiz_client/components/color_manager.dart';
import 'package:noquiz_client/components/player_list.dart';
import 'package:noquiz_client/components/textfield.dart';
import 'package:noquiz_client/pages/player/player_room_game_page.dart';
import 'package:noquiz_client/utils/room.dart';
import 'package:noquiz_client/utils/socket.dart';
import 'package:provider/provider.dart';
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
    final colorManager = Provider.of<ColorManager>(context, listen: false);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Enter Your Nickname', style: TextStyle(color: colorManager.currentColors.textPrimaryColor),),
          backgroundColor: colorManager.currentColors.primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: colorManager.currentColors.secondaryColor),
          ),
          content: NQTextField(controller: nicknameController, labelText: "Nickname",),
          actions: <Widget>[
            TextButton(
              child: Text('Submit', style: TextStyle(color: colorManager.currentColors.textPrimaryColor)),
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
    final colorManager = Provider.of<ColorManager>(context);
    return Scaffold(
      appBar: const NQAppBar(title: 'Room lobby'),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text(
              'Waiting for the admin to start the game',
              style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: colorManager.currentColors.textPrimaryColor),
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
