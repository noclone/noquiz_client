import 'package:flutter/material.dart';
import 'package:noquiz_client/components/title_text.dart';
import 'package:noquiz_client/utils/colors.dart';

import 'network_image.dart';

class NQImageList extends StatelessWidget {
  final List<List<dynamic>> imageList;
  final List<List<dynamic>>? answerList;
  final double textHeight;
  final bool shadowText;
  final bool colorTextAnswer;
  final bool showAnswer;

  const NQImageList({
    Key? key,
    required this.imageList,
    this.answerList,
    this.textHeight = 40.0,
    this.shadowText = false,
    this.colorTextAnswer = false,
    this.showAnswer = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = imageList.length;
        final spacing = 16.0;
        final maxWidth = constraints.maxWidth;
        final imageWidth = (maxWidth - (spacing * (count + 1))) / count;
        final imageHeight = imageWidth;
        final double answerHeight = showAnswer ? textHeight : 0;

        return SizedBox(
          height: imageHeight + textHeight + 16 + answerHeight,
          child: ListView.builder(
            shrinkWrap: true,
            scrollDirection: Axis.horizontal,
            itemCount: count,
            itemBuilder: (context, index) {
              bool isCorrect = answerList != null &&
                  imageList[index][0] == answerList![index][0];
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: SizedBox(
                  width: imageWidth,
                  child: Column(
                    children: [
                      SizedBox(
                        width: imageWidth,
                        height: imageHeight,
                        child: NQNetworkImage(
                          imagePath: imageList[index][0],
                          fit: BoxFit.cover,
                        ),
                      ),
                      SizedBox(
                        width: imageWidth,
                        height: textHeight,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: shadowText
                              ? NQTitleText(
                                  text: imageList[index][1],
                                  fontSize: 200,
                                )
                              : Text(
                                  imageList[index][1],
                                  style: TextStyle(
                                    fontSize: 200,
                                    color: answerList != null && colorTextAnswer
                                        ? isCorrect
                                            ? Colors.green
                                            : Colors.red
                                        : textPrimaryColor,
                                    shadows: [
                                      if (colorTextAnswer)
                                        Shadow(
                                          color: answerList != null
                                              ? isCorrect
                                                  ? Colors.green
                                                  : Colors.red
                                              : secondaryColor,
                                          blurRadius: 10,
                                          offset: const Offset(2, 2),
                                        ),
                                    ],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                        ),
                      ),
                      if (showAnswer && answerList != null)
                        SizedBox(
                          width: imageWidth,
                          height: answerHeight,
                          child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: NQTitleText(
                                text: answerList![index][2],
                                fontSize: 200,
                              )),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
