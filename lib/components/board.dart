import 'dart:math';

import 'package:flutter/material.dart';
import 'package:noquiz_client/components/network_image.dart';

class NQBoard extends StatelessWidget {
  final List<Map<String, dynamic>> board;
  final List<bool> imageVisibility;

  const NQBoard({
    Key? key,
    required this.board,
    required this.imageVisibility,
  }) : super(key: key);

  Color getBorderColor(String difficulty) {
    switch (difficulty) {
      case 'EASY':
        return Colors.green;
      case 'MEDIUM':
        return Colors.orange;
      case 'HARD':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const int crossAxisCount = 4;
          int itemCount = board.length;
          double size = min(constraints.maxHeight, constraints.maxWidth);

          return Center(
            child: SizedBox(
              width: size,
              height: size,
              child: GridView.count(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 4.0,
                mainAxisSpacing: 4.0,
                childAspectRatio: (size / crossAxisCount) / (size / (itemCount / crossAxisCount).ceil()),
                children: List.generate(itemCount, (index) {
                  if (!imageVisibility[index]) {
                    return Container();
                  }
                  final thumbnailUrl = board[index]['thumbnail'];
                  return Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: getBorderColor(board[index]['difficulty']),
                          width: 4.0,
                        ),
                      ),
                      child: NQNetworkImage(
                        imagePath: thumbnailUrl,
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                }),
              ),
            ),
          );
        },
      ),
    );
  }
}
