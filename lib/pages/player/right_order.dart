import 'package:flutter/material.dart';
import 'package:noquiz_client/components/image_list.dart';
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
  List<List<dynamic>> answerData = [];
  List<List<dynamic>> imageData = [];

  @override
  void initState() {
    super.initState();
    widget.broadcastStream.listen((message) {
      MessageData data = decodeMessageData(message);
      if (data.subject == MessageSubject.RIGHT_ORDER) {
        if (data.action == "SEND") {
          setState(() {
            answerData = List<List<dynamic>>.from(data.content['DATA'] ?? []);
            imageData = List<List<dynamic>>.from(data.content['DATA'] ?? [])..shuffle();
          });
        } else if (data.action == "REQUEST") {
          setState(() {
            answerData = List<List<dynamic>>.from(data.content['DATA'] ?? []);
            imageData = List<List<dynamic>>.from(data.content['DATA'] ?? [])..shuffle();
          });
        } else if (data.action == "REQUEST_PLAYERS_ANSWER") {
          sendToSocket(widget.channel, MessageSubject.RIGHT_ORDER, "PLAYER_ANSWER", {"VALUE": imageData});

          int count = countCorrectlyOrderedElements();
          int points = 0;
          switch (count){
            case 0:
            case 1:
              points = 0;
              break;
            case 2:
              points = 1;
              break;
            case 3:
              points = 3;
              break;
            case 5:
              points = 4;
              break;
          }
          sendToSocket(widget.channel, MessageSubject.PLAYER_SCORE, "INCREASE", {"VALUE": points});
        }
      }
    });
  }

  int countCorrectlyOrderedElements() {
    int count = 0;
    for (int i = 0; i < answerData.length; i++) {
      if (answerData[i][0] == imageData[i][0]) {
        count++;
      }
    }
    return count;
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
          NQImageList(imageList: imageData, onReorder: _onReorder,)
      ],
    );
  }
}
