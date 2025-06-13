import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class RightOrder extends StatefulWidget {
  final WebSocketChannel channel;
  final Stream<dynamic> broadcastStream;

  const RightOrder({
    Key? key,
    required this.channel,
    required this.broadcastStream,
  }) : super(key: key);

  @override
  _RightOrderState createState() => _RightOrderState();
}

class _RightOrderState extends State<RightOrder> {
  List<List<dynamic>> imageData = [];
  String? currentRightOrder;

  @override
  void initState() {
    super.initState();
    widget.broadcastStream.listen((message) {
      final data = jsonDecode(message);
      if (data.containsKey('right-order')) {
        setState(() {
          currentRightOrder = data['right-order'];
          imageData = List<List<dynamic>>.from(data['data'] ?? [])..shuffle();
        });
      } else if (data.containsKey('send-right-order-answer')) {
        widget.channel.sink.add(jsonEncode({
          'player-right-order-answer': imageData,
        }));
      }
    });
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      final item = imageData.removeAt(oldIndex);
      imageData.insert(newIndex, item);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Center(
          child: Text(
            currentRightOrder ?? '',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
        if (imageData.isNotEmpty)
          LayoutBuilder(
            builder: (context, constraints) {
              final maxWidth = constraints.maxWidth;
              final imageCount = imageData.length;
              final imageWidth = imageCount > 0 ? maxWidth / imageCount : maxWidth;

              return Center(
                child: SizedBox(
                  width: maxWidth,
                  height: 250,
                  child: ReorderableListView.builder(
                    buildDefaultDragHandles: false,
                    scrollDirection: Axis.horizontal,
                    itemCount: imageCount,
                    itemBuilder: (context, index) {
                      return ReorderableDragStartListener(
                        key: Key('$index'),
                        index: index,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: SizedBox(
                            width: imageWidth - 16,
                            child: Column(
                              children: [
                                Expanded(
                                  child: Image.network(
                                    imageData[index][0],
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                  ),
                                ),
                                Text(
                                  imageData[index][1],
                                  style: const TextStyle(fontSize: 20),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                    onReorder: _onReorder,
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
