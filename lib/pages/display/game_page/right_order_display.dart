import 'package:flutter/material.dart';
import 'package:noquiz_client/components/network_image.dart';
import 'package:noquiz_client/components/visibility_component.dart';
import 'package:noquiz_client/pages/display/game_page/display_state.dart';
import 'package:noquiz_client/utils/socket.dart';

enum RightOrderState {
  images,
  playerAnswers,
}

class RightOrderDisplay extends StatefulWidget {
  final Function setCurrentDisplayState;
  final Stream<dynamic> broadcastStream;

  const RightOrderDisplay({
    Key? key,
    required this.setCurrentDisplayState,
    required this.broadcastStream,
  }) : super(key: key);

  @override
  _RightOrderDisplayState createState() => _RightOrderDisplayState();
}

class _RightOrderDisplayState extends State<RightOrderDisplay> {
  String? rightOrderTitle;
  List<List<dynamic>> answerData = [];
  List<List<dynamic>> imageData = [];
  bool showAnswer = false;
  RightOrderState state = RightOrderState.images;
  List<Map<String, dynamic>> playerAnswers = [];

  @override
  void initState() {
    super.initState();
    widget.broadcastStream.listen((message) {
      MessageData data = decodeMessageData(message);
      if (data.subject == MessageSubject.RIGHT_ORDER) {
        if (data.action == "SEND") {
          setState(() {
            widget.setCurrentDisplayState(DisplayState.rightOrder);
            state = RightOrderState.images;
            rightOrderTitle = data.content['TITLE'];
            answerData = List<List<dynamic>>.from(data.content['DATA'] ?? []);
            imageData = List<List<dynamic>>.from(data.content['DATA'] ?? [])
              ..shuffle();
            showAnswer = false;
          });
        } else if (data.action == "SHOW_ANSWER") {
          setState(() {
            widget.setCurrentDisplayState(DisplayState.rightOrder);
            state = RightOrderState.images;
            rightOrderTitle = data.content['TITLE'];
            answerData = List<List<dynamic>>.from(data.content['DATA'] ?? []);
            showAnswer = true;
          });
        } else if (data.action == "PLAYER_ANSWER") {
          setState(() {
            state = RightOrderState.playerAnswers;
            playerAnswers.add({
              'imagesOrder': data.content['VALUE'],
              'playerName': data.content['PLAYER_NAME'],
            });
          });
        } else if (data.action == "CLEAR_PLAYERS_ANSWER") {
          setState(() {
            playerAnswers.clear();
          });
        }
      }
    }, onError: (error) {
      print('WebSocket error: $error');
    }, onDone: () {
      print('WebSocket connection closed');
    });
  }

  double responsiveFontSize(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return screenWidth * 0.03;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        buildComponent(
          visible: state == RightOrderState.images,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Center(
                child: Text(
                  textAlign: TextAlign.center,
                  rightOrderTitle ?? '',
                  style: TextStyle(
                    fontSize: responsiveFontSize(context),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (imageData.isNotEmpty)
                LayoutBuilder(
                  builder: (context, constraints) {
                    final maxWidth = constraints.maxWidth;
                    final count = imageData.length;
                    final imageWidth = count > 0 ? (maxWidth / count) - 16 : maxWidth;

                    return Center(
                      child: SizedBox(
                        height: imageWidth * (showAnswer ? 1.5 : 1.2),
                        child: ListView.builder(
                          shrinkWrap: true,
                          scrollDirection: Axis.horizontal,
                          itemCount: count,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: SizedBox(
                                width: imageWidth,
                                child: Column(
                                  children: [
                                    Expanded(
                                      child: NoQuizNetworkImage(
                                        imagePath: showAnswer ? answerData[index][0] : imageData[index][0],
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                      ),
                                    ),
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        showAnswer ? answerData[index][1] : imageData[index][1],
                                        style: TextStyle(
                                          fontSize: responsiveFontSize(context),
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    if (showAnswer)
                                      FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          answerData[index][2],
                                          style: TextStyle(
                                            fontSize: responsiveFontSize(context),
                                          ),
                                          textAlign: TextAlign.center,
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
        ),
        buildComponent(
          visible: state == RightOrderState.playerAnswers,
          child: Column(
            children: [
              if (answerData.isNotEmpty)
                Card(
                  margin: const EdgeInsets.all(16.0),
                  elevation: 4.0,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        Text(
                          'Correct Answer',
                          style: TextStyle(
                            fontSize: responsiveFontSize(context),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final maxWidth = constraints.maxWidth;
                            final count = answerData.length;
                            final imageWidth = count > 0 ? (maxWidth / count) - 16 : maxWidth;

                            return SizedBox(
                              height: imageWidth,
                              child: ListView.builder(
                                shrinkWrap: true,
                                scrollDirection: Axis.horizontal,
                                itemCount: count,
                                itemBuilder: (context, index) {
                                  return Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: SizedBox(
                                      width: imageWidth,
                                      child: Column(
                                        children: [
                                          Expanded(
                                            child: NoQuizNetworkImage(
                                              imagePath: answerData[index][0],
                                              fit: BoxFit.cover,
                                              width: double.infinity,
                                            ),
                                          ),
                                          FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Text(
                                              answerData[index][1],
                                              style: TextStyle(
                                                fontSize: responsiveFontSize(context),
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              Expanded(
                child: ListView.builder(
                  itemCount: playerAnswers.length,
                  itemBuilder: (context, index) {
                    final playerAnswer = playerAnswers[index];
                    return Column(
                      children: [
                        Text(
                          playerAnswer['playerName'],
                          style: TextStyle(
                            fontSize: responsiveFontSize(context),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final maxWidth = constraints.maxWidth;
                            final count = playerAnswer['imagesOrder'].length;
                            final imageWidth = count > 0 ? (maxWidth / count) - 20 : maxWidth;

                            return SizedBox(
                              height: imageWidth,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: count,
                                itemBuilder: (context, imgIndex) {
                                  bool isCorrect = playerAnswer['imagesOrder'][imgIndex][0] == answerData[imgIndex][0];

                                  return Padding(
                                    padding: const EdgeInsets.all(6.0),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: isCorrect ? Colors.green : Colors.red,
                                          width: 4.0,
                                        ),
                                      ),
                                      child: SizedBox(
                                        width: imageWidth,
                                        child: Column(
                                          children: [
                                            Expanded(
                                              child: NoQuizNetworkImage(
                                                imagePath: playerAnswer['imagesOrder'][imgIndex][0],
                                                fit: BoxFit.cover,
                                                width: double.infinity,
                                              ),
                                            ),
                                            FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: Text(
                                                playerAnswer['imagesOrder'][imgIndex][1],
                                                style: TextStyle(
                                                  fontSize: responsiveFontSize(context),
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                        const Divider(
                          color: Colors.grey,
                          thickness: 1,
                          height: 20,
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

