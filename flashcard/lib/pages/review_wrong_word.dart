import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flashcard/Models/Topic.dart';
import 'package:flashcard/Services/WordServices.dart';
import 'package:flashcard/animations/flip_card_animation.dart';
import 'package:flashcard/components/card.dart';
import 'package:flashcard/components/home_page/Custom_AppBar.dart';
import 'package:flashcard/components/review_card_container.dart';
import 'package:flashcard/Models/word.dart';
import 'package:flashcard/pages/text_to_speech.dart';
import 'package:flip_card/flip_card.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide Size;
import 'package:percent_indicator/circular_percent_indicator.dart';

class NavigationArguments {
  final List<Word> words;
  final List<int> wrong;
  final List<int> learned;

  NavigationArguments(
      {required this.words, required this.wrong, required this.learned});
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
  late List<int> learned;

  bool _isFront = true;
  @override
  void initState() {
    super.initState();
    _words = widget.arguments.words;
    wrong = widget.arguments.wrong;
    learned = widget.arguments.learned;
    // print(_words.length);
    // print(learned);
    // print(wrong);
  }

  double calculatePercentage(
      List<int> right, List<int> wrong, List<Word> words) {
    int totalQuestions = words.length;
    int correctAnswers = right.length;
    double percentage = (correctAnswers / totalQuestions) * 100;
    return percentage;
  }

  void _toggleCardSide() {
    setState(() {
      _isFront = !_isFront; // Đảo ngược trạng thái của thẻ
    });
  }

  Widget _buildFrontWidget(String content) {
    final size = MediaQuery.of(context).size;
    return CardReviewContainer(
        size: size,
        content: content,
        textColor: Colors.black,
        ttsButton: TtsButton(language: 'en-US', text: content));
  }

  Widget _buildBackWidget(String content) {
    final size = MediaQuery.of(context).size;
    return CardReviewContainer(
        size: size,
        content: content,
        textColor: Colors.white,
        ttsButton: TtsButton(language: 'vi-VN', text: content));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
            Navigator.pop(context);
          },
        ),
        // Các thuộc tính khác của AppBar
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Kết quả',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: MediaQuery.of(context).size.width * 0.6,
                          child: Text(
                            'Bạn đang làm rất tốt!, Hãy tiếp tục ôn tập và cải thiện kết quả của mình nhé!',
                            maxLines: 3,
                          ),
                        ),
                        Icon(Icons.emoji_emotions_outlined,
                            color: Colors.green, size: 50)
                      ],
                    )),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      CircularPercentIndicator(
                        animation: true,
                        radius: 70.0,
                        lineWidth: 20.0,
                        percent:
                            calculatePercentage(learned, wrong, _words) / 100,
                        center: Text(
                          '${calculatePercentage(learned, wrong, _words).toStringAsFixed(0)}%',
                          style: const TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        progressColor: Colors.green,
                        backgroundColor: Colors.orange,
                      ),
                      Column(
                        children: [
                          Text(
                            'Đã học: ${learned.length.toString()}',
                            style: const TextStyle(color: Colors.green),
                          ),
                          const SizedBox(
                              height: 16), // Khoảng cách giữa các dòng
                          Text(
                            'Chưa học: ${wrong.length.toString()}',
                            style: const TextStyle(color: Colors.orange),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Danh sách từ chưa học',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: wrong.length,
                  // itemExtent: 200, // Đặt kích thước cố định cho mỗi item
                  itemBuilder: (context, index) {
                    final int wordIndex = wrong[index];
                    final Word word = _words[wordIndex];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Container(
                        height: 200,
                        child: FlipCard(
                          direction: FlipDirection.VERTICAL, // default

                          front: card(
                              english: _words[index].english,
                              size: 200,
                              color: Colors.black,
                              ttsButton: TtsButton(
                                  language: 'en-US',
                                  text: _words[index].english)),
                          back: card(
                              english: _words[index].vietnam,
                              size: 200,
                              color: Colors.black,
                              ttsButton: TtsButton(
                                  language: 'vi-VN',
                                  text: _words[index].vietnam)),
                          side:
                              CardSide.FRONT, // The side to initially display.
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
