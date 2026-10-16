import 'package:flutter/material.dart';

class PleaseDownloadModelWidget extends StatelessWidget {
  final VoidCallback changePageToChat;
  const PleaseDownloadModelWidget({super.key, required this.changePageToChat});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "No Model Is Downloaded\nPlease Download a Model!",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: changePageToChat,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text("Download"),
                        SizedBox(width: 10),
                        Icon(Icons.download_rounded),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
