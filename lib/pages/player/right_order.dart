import 'package:flutter/material.dart';
import 'package:noquiz_client/components/network_image.dart';
import 'package:noquiz_client/utils/socket.dart';
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

  @override
  void initState() {
    super.initState();
    widget.broadcastStream.listen((message) {
      MessageData data = decodeMessageData(message);
      if (data.subject == MessageSubject.RIGHT_ORDER) {
        if (data.action == "SEND") {
          setState(() {
            imageData = List<List<dynamic>>.from(data.content['DATA'] ?? [])..shuffle();
          });
        } else if (data.action == "REQUEST") {
          setState(() {
            imageData = List<List<dynamic>>.from(data.content['DATA'] ?? [])..shuffle();
          });
        } else if (data.action == "REQUEST_PLAYERS_ANSWER") {
          sendToSocket(widget.channel, MessageSubject.RIGHT_ORDER, "PLAYER_ANSWER", {"VALUE": imageData});
        }
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

  double responsiveFontSize(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return screenWidth * 0.03;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (imageData.isNotEmpty)
          LayoutBuilder(
            builder: (context, constraints) {
              final maxWidth = constraints.maxWidth;
              final imageCount = imageData.length;
              final imageWidth = imageCount > 0 ? maxWidth / imageCount : maxWidth;

              return Center(
                child: SizedBox(
                  width: maxWidth,
                  height: imageWidth,
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
                                  child: NoQuizNetworkImage(
                                    imagePath: imageData[index][0],
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                  ),
                                ),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    imageData[index][1],
                                    style: TextStyle(fontSize: responsiveFontSize(context)),
                                    textAlign: TextAlign.center,
                                  ),
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
