import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:noquiz_client/player_room_lobby_page.dart';
import 'dart:convert';
import 'admin_room_lobby_page.dart';

class MenuPage extends StatefulWidget {
  final String nickname;

  const MenuPage({super.key, required this.nickname});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  String? _roomId;
  bool _isLoading = false;
  final TextEditingController _roomIdController = TextEditingController();

  Future<void> _createRoom() async {
    setState(() {
      _isLoading = true;
      _roomId = null;
    });

    try {
      final url = Uri.parse('http://localhost:8000/api/rooms/create');
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
              builder: (context) => AdminRoomLobbyPage(roomId: _roomId!, nickname: widget.nickname),
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

  Future<void> _joinRoom() async {
    final roomId = _roomIdController.text.trim();
    if (roomId.isEmpty) {
      _showErrorDialog('Please enter a room ID.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final url = Uri.parse('http://localhost:8000/api/rooms/$roomId');
      final response = await http.get(url);

      setState(() {
        _isLoading = false;
      });

      if (response.statusCode == 200) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PlayerRoomLobbyPage(roomId: roomId, nickname: widget.nickname),
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
                  child: TextField(
                    controller: _roomIdController,
                    decoration: const InputDecoration(
                      labelText: 'Enter Room ID',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _joinRoom(),
                  ),
                ),
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ),
                ElevatedButton(
                  onPressed: _joinRoom,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    textStyle: Theme.of(context).textTheme.titleMedium,
                  ),
                  child: const Text('Continue'),
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
