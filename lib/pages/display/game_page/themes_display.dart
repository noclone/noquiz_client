import 'package:flutter/material.dart';

class ThemesDisplay extends StatelessWidget {
  final List<dynamic> themes;

  const ThemesDisplay({super.key, required this.themes});

  @override
  Widget build(BuildContext context) {
    int crossAxisCount = 1;
    if (themes.length == 3 || themes.length == 4) {
      crossAxisCount = 2;
    } else if (themes.length > 4) {
      crossAxisCount = 3;
    }

    return Center(
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxWidth: 800, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Themes',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: GridView.count(
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
          ],
        ),
      ),
    );
  }
}
