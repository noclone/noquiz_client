import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:qr_flutter_new/qr_flutter.dart';
import '../../utils/visibility_component.dart';
import 'game_page/board_display.dart';
import 'game_page/display_state.dart';
import 'game_page/question_display.dart';
import 'game_page/player_scores_display.dart';
import 'game_page/player_answers_display.dart';
import 'game_page/right_order_display.dart';
import 'game_page/themes_display.dart';
import 'game_page/theme_answers_display.dart';
import 'game_page/answer_display.dart';
import 'game_page/timer_display.dart';

class DisplayRoomLobbyPage extends StatefulWidget {
  final String roomId;
  final String serverIp;

  const DisplayRoomLobbyPage({super.key, required this.roomId, required this.serverIp});

  @override
  State<DisplayRoomLobbyPage> createState() => _DisplayRoomLobbyPageState();
}

class _DisplayRoomLobbyPageState extends State<DisplayRoomLobbyPage> {
  late WebSocketChannel channel;
  late Stream<dynamic> broadcastStream;
  bool showQRCode = false;
  final TextEditingController _textController = TextEditingController();
  String qrData = '';

  @override
  void initState() {
    super.initState();
    channel = WebSocketChannel.connect(
      Uri.parse('ws://${widget.serverIp}:8000/ws/${widget.roomId}'),
    );

    channel.ready.then((_) {
      channel.sink.add(jsonEncode({"name": "display_${widget.roomId}", "display": true}));
    });

    broadcastStream = channel.stream.asBroadcastStream();
    broadcastStream.listen((message) {
      final data = jsonDecode(message);
      if (data.containsKey('start-game')) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DisplayRoomLobbyPage(roomId: widget.roomId, serverIp: widget.serverIp),
          ),
        );
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
    _textController.dispose();
    super.dispose();
  }

  void _validateAndShowQRCode() {
    if (_textController.text.isNotEmpty) {
      setState(() {
        qrData = _textController.text;
        showQRCode = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Display Lobby'),
      ),
      body: Center(
        child: showQRCode
            ? QrImageView(
          data: qrData,
          version: QrVersions.auto,
          size: 200.0,
        )
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _textController,
                decoration: const InputDecoration(
                  labelText: 'Enter data for QR code',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: _validateAndShowQRCode,
              child: const Text('Generate QR Code'),
            ),
          ],
        ),
      ),
    );
  }
}
