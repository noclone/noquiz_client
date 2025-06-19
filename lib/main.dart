import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:noquiz_client/pages/player/player_room_lobby_page.dart';
import 'package:noquiz_client/components/dialogs.dart';
import 'package:noquiz_client/utils/preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:web_socket_channel/web_socket_channel.dart';

import 'pages/admin/admin_room_lobby_page.dart';
import 'pages/display/display_room_lobby_page.dart';

void main() {
  runApp(const NoQuiz());
}

class NoQuiz extends StatelessWidget {
  const NoQuiz({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quiz App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _serverIpController = TextEditingController();
  late WebSocketChannel channel;
  List<String> roomIds = [];

  @override
  void initState() {
    super.initState();
    _loadServerIpAddress();
  }

  @override
  void dispose() {
    _serverIpController.dispose();
    channel.sink.close();
    super.dispose();
  }

  void _setServerIpAddress() async {
    final serverIp = _serverIpController.text.trim();
    if (serverIp.isEmpty) {
      showErrorDialog('Please enter a server IP address.', context);
      return;
    }
    await setPreference('server_ip', serverIp);
    fetchRoomIds();
  }

  Future<void> _loadServerIpAddress() async {
    if (kIsWeb) {
      String currentUrl = Uri.base.toString();
      String serverIp = Uri.parse(currentUrl).host;
      _serverIpController.text = serverIp;
      setPreference("server_ip", serverIp);
    } else {
      final serverIp = await getServerIpAddress();
      if (serverIp != null && serverIp.isNotEmpty) {
        _serverIpController.text = serverIp;
      }
    }
    String? roomId = await getRoomId();
    if (roomId != null && roomId.isNotEmpty && await roomExists(roomId)) {
      _connect(roomId);
    }
    else {
      fetchRoomIds();
    }
  }

  Future<bool> roomExists(String roomId) async {
    String serverIp = _serverIpController.text;
    final url = Uri.parse('http://$serverIp:8000/api/rooms/$roomId');
    final response = await http.get(url);
    return response.statusCode == 200;
  }

  Future<void> fetchRoomIds() async {
    String serverIp = _serverIpController.text.trim();
    if (serverIp.isEmpty) {
      showErrorDialog('Server IP address not set.', context);
      return;
    }

    try {
      final response =
          await http.get(Uri.parse('http://$serverIp:8000/api/rooms'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          roomIds = List<String>.from(data);
        });
      } else {
        print('Failed to load room IDs');
      }
    } catch (e) {
      print('Error fetching room IDs: $e');
    }
  }

  void _connect(String roomId) async {
    await setPreference('room_id', roomId);

    String serverIp = _serverIpController.text;
    channel = WebSocketChannel.connect(
      Uri.parse('ws://$serverIp:8000/ws/$roomId'),
    );

    channel.ready.then((_) {
      getPlayerId().then((playerId) {
        if (playerId == null || playerId.isEmpty) {
          channel.sink.add(jsonEncode({"init-message": "empty"}));
        }
        else {
          channel.sink.add(jsonEncode({"player_id": playerId}));
        }

        final broadcastStream = channel.stream.asBroadcastStream();

        broadcastStream.listen((message) {
          final data = jsonDecode(message);
          if (data.containsKey('initiated-player-id')) {
            setPreference('player_id', data['initiated-player-id']);
          }
          if (data.containsKey('room-deleted')) {
            fetchRoomIds();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Admin left the room')),
            );
            Navigator.popUntil(context, ModalRoute.withName('/'));
          }
        });
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PlayerRoomLobbyPage(roomId: roomId, channel: channel, broadcastStream: broadcastStream),
          ),
        );
      });
    });
  }

  Future<void> _createRoom() async {

    final serverIp = await getServerIpAddress();
    if (serverIp == null || serverIp.isEmpty) {
      showErrorDialog('Server IP address not set.', context);
      return;
    }

    try {
      final url = Uri.parse('http://$serverIp:8000/api/rooms/create');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData.containsKey('room_id')) {
          final roomId = responseData['room_id'].toString();

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AdminRoomLobbyPage(roomId: roomId, serverIp: serverIp),
            ),
          );
        } else {
          showErrorDialog('Room ID not found in response.', context);
        }
      } else {
        showErrorDialog('Failed to create room. Status: ${response.statusCode}\nBody: ${response.body}', context);
      }
    } catch (e) {
      showErrorDialog('An error occurred: $e', context);
    }
  }

  Future<void> _displayRoom(String roomId) async {

    String serverIp = _serverIpController.text;
    try {
      final url = Uri.parse('http://$serverIp:8000/api/rooms/$roomId');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DisplayRoomLobbyPage(roomId: roomId, serverIp: serverIp),
          ),
        );
      } else {
        showErrorDialog('Room not found', context);
      }
    } catch (e) {
      showErrorDialog('An error occurred: $e', context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NoQuiz'),
      ),
      body: Stack(
        children: <Widget>[
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _serverIpController,
                          decoration: const InputDecoration(
                            labelText: 'Server Ip Address',
                            border: OutlineInputBorder(),
                          ),
                          onSubmitted: (_) => _setServerIpAddress(),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: fetchRoomIds,
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  Expanded(
                    child: ListView.builder(
                      itemCount: roomIds.length,
                      itemBuilder: (context, index) {
                        return Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          child: ListTile(
                            title: Text(roomIds[index]),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.login),
                                  onPressed: () => _connect(roomIds[index]),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.tv),
                                  onPressed: () => _displayRoom(roomIds[index]),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            right: 20,
            child: ElevatedButton(
              onPressed: _createRoom,
              style: ElevatedButton.styleFrom(
                padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: const Text('Admin: Create Room'),
            ),
          ),
        ],
      ),
    );
  }
}
