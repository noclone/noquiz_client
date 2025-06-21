import 'package:flutter/material.dart';
import 'package:noquiz_client/components/network_image.dart';
import 'package:noquiz_client/pages/display/game_page/display_state.dart';
import 'package:noquiz_client/utils/socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class QuestionDisplay extends StatefulWidget {
  final Function setCurrentDisplayState;
  final WebSocketChannel channel;
  final Stream<dynamic> broadcastStream;
  final Function showTimerOverlay;

  const QuestionDisplay({
    Key? key,
    required this.setCurrentDisplayState,
    required this.channel,
    required this.broadcastStream,
    required this.showTimerOverlay,
  }) : super(key: key);

  @override
  _QuestionDisplayState createState() => _QuestionDisplayState();
}

class _QuestionDisplayState extends State<QuestionDisplay> {
  String currentQuestion = 'Waiting for a question...';
  List<String> imageUrls = [];
  List<String> mcq_options = [];
  String currentAnswer = '';
  int countdown = 0;
  bool showAnswer = false;

  @override
  void initState() {
    super.initState();
    widget.broadcastStream.listen((message) {
      MessageData data = decodeMessageData(message);
      if (data.subject == MessageSubject.QUESTION) {
        if (data.action == 'SEND') {
          widget.setCurrentDisplayState(DisplayState.question);
          setState(() {
            showAnswer = false;
            countdown = 3;
          });
          startCountdown(data.content);
        } else if (data.action == 'SHOW_ANSWER') {
          setState(() {
            showAnswer = true;
          });
        }
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
        if (data['TIMER'] != 0) {
          widget.showTimerOverlay();
          sendToSocket(widget.channel, MessageSubject.TIMER, "START", {"DURATION": data['TIMER']});
        }

        setState(() {
          currentQuestion = data['QUESTION'];
          currentAnswer = data['ANSWER'] ?? '';
          imageUrls = List<String>.from(data['IMAGES']);
          mcq_options = List<String>.from(data['MCQ_OPTIONS'])..shuffle();
          countdown = 0;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final imageWidth = imageUrls.isEmpty
        ? 0.0
        : screenWidth / imageUrls.length - 16.0 * imageUrls.length;
    final double questionFontSize = screenWidth * 0.05;
    final double countdownFontSize = screenWidth * 0.1;

    if (showAnswer && mcq_options.isEmpty){
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Answer:',
              style: TextStyle(fontSize: screenWidth * 0.05, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              currentAnswer.isNotEmpty ? currentAnswer : 'Answer not available.',
              style: TextStyle(fontSize: screenWidth * 0.05, fontWeight: FontWeight.bold, color: Colors.green),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (countdown > 0 || currentQuestion.isNotEmpty)
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
        if (mcq_options.isNotEmpty && countdown == 0)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SizedBox(
              height: screenHeight * 0.2,
              width: screenWidth * 0.8,
              child: GridView.count(
                crossAxisCount: 2,
                childAspectRatio: 10,
                children: List.generate(mcq_options.length, (index) {
                  return Card(
                    color: showAnswer && mcq_options[index] == currentAnswer ? Colors.green : Colors.white,
                    child: Center(
                      child: Text(
                        mcq_options[index],
                        style: TextStyle(fontSize: screenWidth * 0.02, color: showAnswer ? Colors.white : Colors.black),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
      ],
    );
  }
}
