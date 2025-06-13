import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:noquiz_client/pages/player/player_room_lobby_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../utils/preferences.dart';
import 'admin/admin_room_lobby_page.dart';
import 'display/game_page/display_room_game_page.dart';

class MenuPage extends StatefulWidget {
  final String nickname;

  const MenuPage({super.key, required this.nickname});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  String? _roomId;
  bool _isLoading = false;
  final TextEditingController _serverIpController = TextEditingController();
  List<String> roomIds = [];

  Future<void> _createRoom() async {
    setState(() {
      _isLoading = true;
      _roomId = null;
    });

    final serverIp = await getServerIpAddress();
    if (serverIp == null || serverIp.isEmpty) {
      _showErrorDialog('Server IP address not set.');
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

      setState(() {
        _isLoading = false;
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        if (responseData.containsKey('room_id')) {
          setState(() {
            _roomId = responseData['room_id'].toString();
          });

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AdminRoomLobbyPage(roomId: _roomId!, nickname: widget.nickname, serverIp: serverIp),
            ),
          );
        } else {
          _showErrorDialog('Room ID not found in response.');
        }
      } else {
        _showErrorDialog('Failed to create room. Status: ${response.statusCode}\nBody: ${response.body}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog('An error occurred: $e');
    }
  }

  Future<void> _joinRoom(String roomId) async {
    setState(() {
      _isLoading = true;
    });

    final serverIp = await getServerIpAddress();
    if (serverIp == null || serverIp.isEmpty) {
      _showErrorDialog('Server IP address not set.');
      return;
    }

    try {
      final url = Uri.parse('http://$serverIp:8000/api/rooms/$roomId');
      final response = await http.get(url);

      setState(() {
        _isLoading = false;
      });

      if (response.statusCode == 200) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PlayerRoomLobbyPage(roomId: roomId, nickname: widget.nickname, serverIp: serverIp),
          ),
        );
      } else {
        _showErrorDialog('Room not found');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog('An error occurred: $e');
    }
  }

  Future<void> _displayRoom(String roomId) async {
    setState(() {
      _isLoading = true;
    });

    final serverIp = await getServerIpAddress();
    if (serverIp == null || serverIp.isEmpty) {
      _showErrorDialog('Server IP address not set.');
      return;
    }

    try {
      final url = Uri.parse('http://$serverIp:8000/api/rooms/$roomId');
      final response = await http.get(url);

      setState(() {
        _isLoading = false;
      });

      if (response.statusCode == 200) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DisplayRoomGamePage(roomId: roomId, serverIp: serverIp),
          ),
        );
      } else {
        _showErrorDialog('Room not found');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog('An error occurred: $e');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            child: const Text('Okay'),
            onPressed: () {
              Navigator.of(ctx).pop();
            },
          )
        ],
      ),
    );
  }

  Future<void> fetchRoomIds() async {
    final serverIp = await getServerIpAddress();
    if (serverIp == null || serverIp.isEmpty) {
      _showErrorDialog('Server IP address not set.');
      return;
    }
    try {
      final response = await http.get(Uri.parse('http://$serverIp:8000/api/rooms'));
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

  void _setServerIpAddress() async {
    final serverIp = _serverIpController.text.trim();
    if (serverIp.isEmpty) {
      _showErrorDialog('Please enter a server IP address.');
      return;
    }
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('server_ip', serverIp);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Server IP address saved')),
    );

    fetchRoomIds();
  }

  Future<void> _loadServerIpAddress() async {
    final serverIp = await getServerIpAddress();
    if (serverIp != null && serverIp.isNotEmpty) {
      _serverIpController.text = serverIp;
      fetchRoomIds();
    }
  }

  @override
  void initState() {
    super.initState();
    _loadServerIpAddress();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz Menu'),
      ),
      body: Stack(
        children: <Widget>[
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Welcome, ${widget.nickname}!',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _serverIpController,
                          decoration: const InputDecoration(
                            labelText: 'Enter server IP address',
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
                ),
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ),
                Expanded(
                  child: ListView.builder(
                    itemCount: roomIds.length,
                    itemBuilder: (context, index) {
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        child: ListTile(
                          title: Text(roomIds[index]),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.login),
                                onPressed: () => _joinRoom(roomIds[index]),
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
          Positioned(
            bottom: 20,
            right: 20,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _createRoom,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: _isLoading
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
                  : const Text('Admin: Create Room'),
            ),
          ),
        ],
      ),
    );
  }
}
