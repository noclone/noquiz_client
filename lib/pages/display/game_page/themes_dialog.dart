import 'package:flutter/material.dart';

class ThemesDialog {
  static void show(BuildContext context, List<dynamic> themes) {
    int crossAxisCount = 1;
    if (themes.length == 3 || themes.length == 4) {
      crossAxisCount = 2;
    } else {
      crossAxisCount = 3;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Themes'),
          content: SizedBox(
            width: double.maxFinite,
            height: double.maxFinite,
            child: GridView.count(
              shrinkWrap: true,
              crossAxisCount: crossAxisCount,
              childAspectRatio: 3,
              children: themes.map<Widget>((theme) {
                return Card(
                  margin: const EdgeInsets.all(8.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        theme,
                        style: const TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}
