import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:noquiz_client/components/textfield.dart';
import 'package:noquiz_client/components/title_text.dart';
import 'package:noquiz_client/pages/admin/admin_room_lobby_page.dart';
import 'package:noquiz_client/pages/display/display_room_lobby_page.dart';
import 'package:noquiz_client/pages/player/player_room_lobby_page.dart';
import 'package:noquiz_client/components/dialogs.dart';
import 'package:noquiz_client/utils/preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:noquiz_client/utils/socket.dart';
import 'package:provider/provider.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'components/color_manager.dart';


void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => ColorManager(),
      child: const NoQuiz(),
    ),
  );
}

class NoQuiz extends StatelessWidget {
  const NoQuiz({super.key});

  @override
  Widget build(BuildContext context) {
    final colorManager = Provider.of<ColorManager>(context);
    return MaterialApp(
      title: 'Quiz App',
      theme: ThemeData(
        scaffoldBackgroundColor: colorManager.currentColors.primaryColor,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            textStyle: TextStyle(color: colorManager.currentColors.textPrimaryColor),
            shadowColor: colorManager.currentColors.secondaryColor,
            elevation: 5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: colorManager.currentColors.secondaryColor, width: 2),
            ),
          ),
        ),
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
  bool isConnected = false;

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
    bool success = await fetchRoomIds();
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to connect to the server.'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        isConnected = false;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Successfully connected to the server.'),
          backgroundColor: Colors.green,
        ),
      );
      setState(() {
        isConnected = true;
      });
    }

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
      String? type = await getPreference("player_type");
      type == "player" ? _connect(roomId) : _displayRoom(roomId);
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

  Future<bool> fetchRoomIds() async {
    String serverIp = _serverIpController.text.trim();
    if (serverIp.isEmpty) {
      showErrorDialog('Server IP address not set.', context);
      return false;
    }

    try {
      final response = await http.get(Uri.parse('http://$serverIp:8000/api/rooms')).timeout(
        const Duration(seconds: 1),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          roomIds = List<String>.from(data);
        });
        return true;
      } else {
        print('Failed to load room IDs');
        return false;
      }
    } catch (e) {
      print('Error fetching room IDs: $e');
      return false;
    }
  }

  void _connect(String roomId) async {
    await setPreference('room_id', roomId);
    await setPreference('player_type', "player");

    String serverIp = _serverIpController.text;
    channel = WebSocketChannel.connect(
      Uri.parse('ws://$serverIp:8000/ws/$roomId'),
    );

    channel.ready.then((_) {
      getPlayerId().then((playerId) {
        if (playerId == null || playerId.isEmpty) {
          sendToSocket(channel, MessageSubject.PLAYER_INIT, "INIT_PLAYER", {});
        }
        else {
          sendToSocket(channel, MessageSubject.PLAYER_INIT, "INIT_PLAYER", {"player_id": playerId});
        }

        final broadcastStream = channel.stream.asBroadcastStream();

        broadcastStream.listen((message) {
          MessageData data = decodeMessageData(message);
          if (data.subject == MessageSubject.PLAYER_INIT && data.action == "INIT_SUCCESS") {
            setPreference('player_id', data.content['PLAYER_ID']);
          }
          if (data.subject == MessageSubject.GAME_STATE && data.action == "ROOM_CLOSED") {
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

  Future<void> _joinAsAdmin(String roomId) async {
    final serverIp = await getServerIpAddress();
    if (serverIp == null || serverIp.isEmpty) {
      showErrorDialog('Server IP address not set.', context);
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminRoomLobbyPage(roomId: roomId, serverIp: serverIp),
      ),
    );
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
        await setPreference('room_id', roomId);
        await setPreference('player_type', "display");
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
    double responsiveFontSize = min(MediaQuery.of(context).size.width, MediaQuery.of(context).size.height) * 0.08;
    final colorManager = Provider.of<ColorManager>(context);

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              NQTitleText(text: 'NoQuiz', fontSize: responsiveFontSize,),
              const SizedBox(height: 20),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                child: NQTextField(controller: _serverIpController, labelText: 'Server Ip Address', onSubmitted: _setServerIpAddress)
              ),
              const SizedBox(height: 20),
              Visibility(
                visible: isConnected,
                child: Column(
                  children: [
                    FractionallySizedBox(
                      widthFactor: 0.65,
                      child: SizedBox(
                        height: MediaQuery.of(context).size.height * 0.05,
                        child: ElevatedButton(
                          onPressed: _createRoom,
                          style: ElevatedButton.styleFrom(
                            maximumSize: const Size(500, double.infinity),
                          ),
                          child: Text(
                            'Create Room',
                            style: TextStyle(
                              color: colorManager.currentColors.textPrimaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: responsiveFontSize * 0.45,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Divider(
                      color: Colors.white,
                      thickness: 1,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      spacing: 10,
                      children: [
                        Text(
                          'Available rooms',
                          style: TextStyle(
                            color: colorManager.currentColors.textPrimaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: responsiveFontSize * 0.5,
                          ),
                        ),
                        IconButton(
                          color: colorManager.currentColors.tertiaryColor,
                          icon: const Icon(Icons.refresh),
                          onPressed: fetchRoomIds,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 200,
                      child: ListView.builder(
                        itemCount: roomIds.length,
                        itemBuilder: (context, index) {
                          return Card(
                            color: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(color: colorManager.currentColors.secondaryColor, width: 2),
                            ),
                            margin: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            child: ListTile(
                              title: Text(
                                roomIds[index],
                                style: TextStyle(
                                    fontSize: responsiveFontSize * 0.4,
                                    color: colorManager.currentColors.textPrimaryColor),
                                textAlign: TextAlign.center,
                              ),
                              trailing: GestureDetector(
                                onLongPress: () {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                          side: BorderSide(color: colorManager.currentColors.secondaryColor, width: 2),
                                        ),
                                        backgroundColor: colorManager.currentColors.primaryColor,
                                        title: Text(
                                          'Join Room ${roomIds[index]}',
                                          style: TextStyle(color: colorManager.currentColors.textPrimaryColor),
                                          textAlign: TextAlign.center,
                                        ),
                                        content: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: <Widget>[
                                            ListTile(
                                              leading: Icon(Icons.person,
                                                  color: colorManager.currentColors.tertiaryColor),
                                              title: Text(
                                                'Join as Player',
                                                style: TextStyle(color: colorManager.currentColors.textPrimaryColor),
                                              ),
                                              onTap: () {
                                                Navigator.of(context).pop();
                                                _connect(roomIds[index]);
                                              },
                                            ),
                                            ListTile(
                                              leading: Icon(Icons.tv,
                                                  color: colorManager.currentColors.tertiaryColor),
                                              title: Text(
                                                'Join as Display',
                                                style: TextStyle(color: colorManager.currentColors.textPrimaryColor),
                                              ),
                                              onTap: () {
                                                Navigator.of(context).pop();
                                                _displayRoom(roomIds[index]);
                                              },
                                            ),
                                            ListTile(
                                              leading: Icon(
                                                  Icons.admin_panel_settings,
                                                  color: colorManager.currentColors.tertiaryColor),
                                              title: Text(
                                                'Join as Admin',
                                                style: TextStyle(color: colorManager.currentColors.textPrimaryColor),
                                              ),
                                              onTap: () {
                                                Navigator.of(context).pop();
                                                _joinAsAdmin(roomIds[index]);
                                              },
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  );
                                },
                                child: IconButton(
                                  color: colorManager.currentColors.tertiaryColor,
                                  icon: const Icon(Icons.login),
                                  onPressed: () => _connect(roomIds[index]),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
