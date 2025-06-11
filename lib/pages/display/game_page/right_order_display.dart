import 'package:flutter/material.dart';


class RightOrderDisplay extends StatefulWidget {
  final String? currentRightOrder;
  final List<List<dynamic>> imageData;
  final bool showLabels;

  const RightOrderDisplay({Key? key,
    required this.currentRightOrder,
    required this.imageData,
    required this.showLabels,
  }) : super(key: key);

  @override
  _RightOrderDisplayState createState() => _RightOrderDisplayState();
}

class _RightOrderDisplayState extends State<RightOrderDisplay> {

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Center(
          child: Text(
            widget.currentRightOrder ?? '',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
        if (widget.imageData.isNotEmpty)
          LayoutBuilder(
            builder: (context, constraints) {
              double imageWidth = constraints.maxWidth / widget.imageData.length - 16;

              return Center(
                child: SizedBox(
                  height: 250,
                  child: ListView.builder(
                    shrinkWrap: true,
                    scrollDirection: Axis.horizontal,
                    itemCount: widget.imageData.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: SizedBox(
                          width: imageWidth,
                          child: Column(
                            children: [
                              Image.network(
                                widget.imageData[index][0],
                                fit: BoxFit.contain,
                                height: 200,
                              ),
                              if (widget.showLabels)
                                Text(
                                  widget.imageData[index][1],
                                  style: const TextStyle(fontSize: 20),
                                  textAlign: TextAlign.center,
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
    );
  }
}
