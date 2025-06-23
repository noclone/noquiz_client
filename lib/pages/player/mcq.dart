import 'package:flutter/material.dart';
import 'package:noquiz_client/utils/questions.dart';
import 'package:noquiz_client/utils/socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class MCQ extends StatefulWidget {
  final WebSocketChannel channel;
  final Stream<dynamic> broadcastStream;

  const MCQ({super.key, required this.channel, required this.broadcastStream});

  @override
  State<MCQ> createState() => _MCQState();
}

class _MCQState extends State<MCQ> {
  int clickedIndex = -1;
  int answerIndex = -1;
  List<String> mcqOptions = [];
  String answer = "";

  @override
  void initState() {
    super.initState();

    sendToSocket(widget.channel, MessageSubject.QUESTION, "REQUEST", {});

    widget.broadcastStream.listen((message) {
      MessageData data = decodeMessageData(message);
      if (data.subject == MessageSubject.QUESTION) {
        if (data.action == "SEND") {
          setState(() {
            answerIndex = -1;
            clickedIndex = -1;
            mcqOptions = getMCQOptions(data.content['MCQ_OPTIONS']);
            answer = data.content['ANSWER'];
          });
        }
        if (data.action == "SHOW_ANSWER") {
          setState(() {
            answerIndex = mcqOptions.indexOf(answer);
          });
          if (answerIndex != -1 && answerIndex == clickedIndex) {
            sendToSocket(widget.channel, MessageSubject.PLAYER_SCORE, "INCREASE", {"VALUE": 1});
          }
        }
      }
    }, onError: (error) {
      print('WebSocket error: $error');
    }, onDone: () {
      print('WebSocket connection closed');
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final aspectRatio = screenWidth / screenHeight;

    return Center(
      child: SizedBox(
        height: screenHeight * 0.8,
        width: screenWidth * 0.8,
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: aspectRatio + 0.1,
          children: List.generate(mcqOptions.length, (index) {
            return Center(
              child: SizedBox.expand(
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      clickedIndex = index;
                    });
                    sendToSocket(widget.channel, MessageSubject.PLAYER_ANSWER,
                        "UPDATE", {"VALUE": mcqOptions[index]});
                  },
                  style: ElevatedButton.styleFrom(
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    backgroundColor: answerIndex == index
                        ? Colors.green
                        : clickedIndex == index
                            ? Colors.blue
                            : null,
                  ),
                  child: Text(
                    mcqOptions[index],
                    style: TextStyle(
                        fontSize: screenWidth * 0.03,
                        color: clickedIndex == index || answerIndex == index
                            ? Colors.white
                            : null),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
