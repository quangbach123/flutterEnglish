import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flashcard/Models/Topic.dart';
import 'package:flashcard/Services/WordServices.dart';
import 'package:flashcard/animations/flip_card_animation.dart';
import 'package:flashcard/components/home_page/Custom_AppBar.dart';
import 'package:flashcard/components/review_card_container.dart';
import 'package:flashcard/Models/word.dart';
import 'package:flashcard/pages/text_to_speech.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide Size;

class NavigationArguments {
  final List<Word> words;
  final List<int> wrong;
  
  NavigationArguments({required this.words, required this.wrong});
}

class WrongWordPage extends StatefulWidget {
  final NavigationArguments arguments;

  const WrongWordPage({Key? key, required this.arguments}) : super(key: key);
  

  @override
  State<WrongWordPage> createState() => _WrongWordPageState();
}

class _WrongWordPageState extends State<WrongWordPage> {
  late List<Word> _words;
  late List<int> wrong;
 bool _isFront = true; 
  @override
  void initState() {
    super.initState();
    _words = widget.arguments.words;
    wrong = widget.arguments.wrong;
    print(_words);
    print(wrong);
  }
    void _toggleCardSide() {
    setState(() {
      _isFront = !_isFront; // Đảo ngược trạng thái của thẻ
    });
    }
  Widget _buildFrontWidget(String content) {
  final size = MediaQuery.of(context).size;
  return CardReviewContainer(size: size, content: content, textColor: Colors.black, ttsButton: TtsButton(language: 'en-US', text: content));
}
Widget _buildBackWidget(String content) {
  final size = MediaQuery.of(context).size;
  return CardReviewContainer(size: size, content: content, textColor: Colors.white, ttsButton: TtsButton(language: 'vi-VN', text: content));
}

  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar:AppBar(
  leading: IconButton(
    icon: Icon(Icons.arrow_back),
    onPressed: () {
      Navigator.pop(context);
      Navigator.pop(context);
    },
  ),
  // Các thuộc tính khác của AppBar
),
    body: Padding(
      padding: EdgeInsets.all(8.0), // Dãn khoảng cách ở 4 phía
      child: ListView.builder(
        itemCount: wrong.length,
        // itemExtent: 200, // Đặt kích thước cố định cho mỗi item
        itemBuilder: (context, index) {
          final int wordIndex = wrong[index];
          final Word word = _words[wordIndex];
          return Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0), // Dãn khoảng cách giữa các thẻ
            child: GestureDetector(
              onTap: () {
                _toggleCardSide();
              },
              child: FlipCardAnimation(
                frontWidget: _isFront ? _buildFrontWidget(word.english) : _buildBackWidget(word.vietnam),
                backWidget: _isFront ? _buildBackWidget(word.vietnam) : _buildFrontWidget(word.english),
                direction: FlipDirection.horizontal,
                onAnimationStart: () {},
                onAnimationEnd: () {},
              ),
            ),
          );
        },
      ),
    ),
  );
}
}

