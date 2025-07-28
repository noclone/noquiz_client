import 'package:flutter/material.dart';
import 'package:noquiz_client/utils/colors.dart';

import 'network_image.dart';

class NQImageList extends StatelessWidget {
  final List<List<dynamic>> imageList;

  const NQImageList({
    Key? key,
    required this.imageList,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = imageList.length;
        final imageWidth =
            (constraints.maxWidth / 2) / count;
        final imageHeight = imageWidth;

        return SizedBox(
          height: imageHeight + 40,
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
                      SizedBox(
                        width: imageWidth,
                        height: imageHeight,
                        child: NQNetworkImage(
                          imagePath: imageList[index]
                          [0],
                          fit: BoxFit.cover,
                        ),
                      ),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          imageList[index][1],
                          style: TextStyle(
                            color: textPrimaryColor,
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
    );
  }
}