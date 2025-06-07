import 'package:flutter/material.dart';
import 'dart:convert';

class AdminRoomGamePage extends StatefulWidget {
  final String roomId;
  final Stream<dynamic> broadcastStream;

  const AdminRoomGamePage({super.key, required this.roomId, required this.broadcastStream});

  @override
  State<AdminRoomGamePage> createState() => _AdminRoomGamePageState();
}

class _AdminRoomGamePageState extends State<AdminRoomGamePage> {
  List<Map<String, dynamic>> buzzes = [];

  @override
  void initState() {
    super.initState();
    widget.broadcastStream.listen((message) {
      final data = jsonDecode(message);
      if (data.containsKey('buzz')) {
        setState(() {
          buzzes.add({
            'name': data['buzz'][0],
            'time': data['buzz'][1],
          });
          // Sort the buzzes list by time
          buzzes.sort((a, b) => a['time'].compareTo(b['time']));
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Game Room: ${widget.roomId}'),
      ),
      body: Row(
        children: [
          const Expanded(
            child: Center(
              child: Text('Game has started!'),
            ),
          ),
          Container(
            width: 200,
            decoration: const BoxDecoration(
              border: Border(left: BorderSide(width: 1)),
            ),
            child: ListView.builder(
              itemCount: buzzes.length,
              itemBuilder: (context, index) {
                final buzz = buzzes[index];
                return ListTile(
                  title: Text(buzz['name']),
                  subtitle: Text(buzz['time'].toString()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
