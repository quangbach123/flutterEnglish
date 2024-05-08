import 'package:flutter/material.dart';

class EditWordPage extends StatelessWidget {
  final String wordId;

  EditWordPage({required this.wordId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Word'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            // Implement logic to retrieve data for the wordId and display it on the interface
          },
          child: Text('Edit Word'),
        ),
      ),
    );
  }
}
