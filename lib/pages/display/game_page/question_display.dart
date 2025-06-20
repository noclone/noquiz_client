import 'package:flutter/material.dart';
import 'package:noquiz_client/components/network_image.dart';
import 'package:noquiz_client/pages/display/game_page/display_state.dart';
import 'package:noquiz_client/utils/socket.dart';

class QuestionDisplay extends StatefulWidget {
  final Function setCurrentDisplayState;
  final Stream<dynamic> broadcastStream;

  const QuestionDisplay({
    Key? key,
    required this.setCurrentDisplayState,
    required this.broadcastStream,
  }) : super(key: key);

  @override
  _QuestionDisplayState createState() => _QuestionDisplayState();
}

class _QuestionDisplayState extends State<QuestionDisplay> {
  String currentQuestion = 'Waiting for a question...';
  List<String> imageUrls = [];
  int countdown = 0;

  @override
  void initState() {
    super.initState();
    widget.broadcastStream.listen((message) {
      MessageData data = decodeMessageData(message);
      if (data.subject == MessageSubject.QUESTION && data.action == 'SEND') {
        widget.setCurrentDisplayState(DisplayState.question);
        setState(() {
          countdown = 3;
        });
        startCountdown(data.content);
      }
    }, onError: (error) {
      print('WebSocket error: $error');
    }, onDone: () {
      print('WebSocket connection closed');
    });
  }

  void startCountdown(data) {
    Future.delayed(const Duration(seconds: 1), () {
      if (countdown > 1) {
        setState(() {
          countdown--;
        });
        startCountdown(data);
      } else {
        setState(() {
          currentQuestion = data['QUESTION'];
          imageUrls = List<String>.from(data['IMAGES']);
          countdown = 0;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final imageWidth = imageUrls.isEmpty ? 0.0 : screenWidth / imageUrls.length - 16.0 * imageUrls.length;
    final double questionFontSize = screenWidth * 0.05;
    final double countdownFontSize = screenWidth * 0.1;

    return Stack(
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Center(
              child: SizedBox(
                width: screenWidth * 0.8,
                child: countdown > 0
                    ? Text(
                  countdown.toString(),
                  style: TextStyle(fontSize: countdownFontSize),
                  textAlign: TextAlign.center,
                )
                    : Text(
                  currentQuestion,
                  style: TextStyle(fontSize: questionFontSize),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            if (imageUrls.isNotEmpty && countdown == 0)
              LayoutBuilder(
                builder: (context, constraints) {
                  return Center(
                    child: SizedBox(
                      height: screenHeight * 0.6,
                      child: ListView.builder(
                        shrinkWrap: true,
                        scrollDirection: Axis.horizontal,
                        itemCount: imageUrls.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: SizedBox(
                              width: imageWidth,
                              child: Column(
                                children: [
                                  Expanded(
                                    child: NoQuizNetworkImage(
                                      imagePath: imageUrls[index],
                                      fit: BoxFit.scaleDown,
                                      width: double.infinity,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ],
    );
  }
}

