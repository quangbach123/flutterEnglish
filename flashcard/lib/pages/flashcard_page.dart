import 'dart:async';
import 'dart:math';
import 'package:flashcard/Configs/Constants.dart';
import 'package:flashcard/Models/Topic.dart';
import 'package:flashcard/Services/RecordService.dart';
import 'package:flashcard/Services/TopicServices.dart';
import 'package:flashcard/Services/UserServices.dart';
import 'package:flashcard/Services/WordServices.dart';
import 'package:flashcard/animations/smooth_prosgres.dart';
import 'package:flashcard/components/card.dart';
import 'package:flashcard/components/card_container.dart';
import 'package:flashcard/components/home_page/Custom_AppBar.dart';
import 'package:flashcard/pages/review_wrong_word.dart';
import 'package:flashcard/pages/text_to_speech.dart';
import 'package:flashcard/pages/word_page.dart';
import 'package:flip_card/flip_card.dart';
import 'package:flip_card/flip_card_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flashcard/animations/card_appear_animation.dart';
import 'package:flashcard/animations/flip_card_animation.dart';
import 'package:flashcard/Models/word.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:swipe_cards/draggable_card.dart';
import 'package:swipe_cards/swipe_cards.dart';

class FlashCardPage extends StatefulWidget {
  final Topic topic;
  final List<Word> words;
  final bool isEnglishFirst;
  final String userId;
  final bool isRecord;

  const FlashCardPage(
      {Key? key,
      required this.topic,
      required this.words,
      required this.isEnglishFirst,
      required this.userId,
      required this.isRecord})
      : super(key: key);

  @override
  State<FlashCardPage> createState() => _FlashCardPageState();
}

class _FlashCardPageState extends State<FlashCardPage> {
  List<Word> _words = [];
  List<int> learn = []; // Danh sách các từ đã học
  List<int> not_learn = []; // Danh sách các từ chưa học
  int _currentIndex = 0;
  final FlutterTts flutterTts = FlutterTts();
  RecordService recordService = RecordService();
  late bool isRecord;
  Timer? _timer;
  int _finalElapsedSeconds = 0; // biến lưu thời gian
  late int _elapsedSeconds; // biến đếm thời gian
  bool _timerStopped = false;

  MatchEngine? _matchEngine;
  List<SwipeItem> _swipeItems = <SwipeItem>[];
  Color color = Colors.black;

  bool isAutoMode = false;

  var duration = Duration(days: 500);

  @override
  void initState() {
    _words = widget.words;
    isRecord = widget.isRecord;
    print(_currentIndex);
    int i = _words.length;
    print('số từ : $i');
    startTimer();

    TopicService topicService = TopicService();
    topicService.incrementView(widget.topic.documentId);

    for (int i = 0; i < _words.length; i++) {
      _swipeItems.add(SwipeItem(
        content: _words[i],
        likeAction: () {
          learn.add(i);
          print('learn: $learn');
          _currentIndex++;
        },
        nopeAction: () {
          not_learn.add(i);
          print('not_learn: $not_learn');
          _currentIndex++;
        },
        onSlideUpdate: (SlideRegion? slideRegion) async {
          setState(() {
            if (slideRegion == SlideRegion.inLikeRegion) {
              color = Colors.green;
            } else if (slideRegion == SlideRegion.inNopeRegion) {
              color = Colors.red;
            } else {
              color = Colors.black;
            }
          });
        },
      ));
    }
    _matchEngine = MatchEngine(swipeItems: _swipeItems);

    super.initState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void startTimer() {
    _elapsedSeconds = 0;
    if (!_timerStopped) {
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _elapsedSeconds++;
          _finalElapsedSeconds = _elapsedSeconds;
        });
      });
    }
  }

// tính % câu đúng
  double calculatePercentage(
      List<int> right, List<int> wrong, List<Word> words) {
    int totalQuestions = words.length;
    int correctAnswers = right.length;
    double percentage = (correctAnswers / totalQuestions) * 100;
    return percentage;
  }

  String _formatElapsedTime(int elapsedSeconds) {
    int hours = elapsedSeconds ~/ 3600;
    int minutes = (elapsedSeconds % 3600) ~/ 60;
    int seconds = elapsedSeconds % 60;

    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

// lấy dữ liệu từ vựng
  void _fetchWords() async {
    WordService wordService = WordService();
    try {
      QuerySnapshot snapshot =
          await wordService.getWordsByTopicId(widget.topic.documentId).first;
      _words.clear();
      for (QueryDocumentSnapshot doc in snapshot.docs) {
        String documentId = doc.id;
        String english = doc['english'];
        String vietnam = doc['vietnam'];
        // Lấy reference đến topicId
        DocumentReference topicRef = doc['topicId'];

        if (topicRef != null) {
          DocumentSnapshot topicDoc = await topicRef.get();
          String topicId = topicDoc.id; // Đặt topicId ở đây
          String topicName = topicDoc['topicName'];
          Word word = Word(
            id: documentId,
            english: english,
            vietnam: vietnam,
            topicId: topicId,
          );

          if (!_words.any((element) => element.id == word.id)) {
            _words.add(word);
          }
        } else {
          // Xử lý trường hợp reference là null nếu cần thiết
        }
      }
      if (kDebugMode) {
        print(_words.length);
      }

      setState(() {});
    } catch (error) {
      print('Error fetching words: $error');
    }
  }

  Widget _buildFrontWidget(String content) {
    final size = MediaQuery.of(context).size;
    return card(
        english: content,
        size: size.height,
        color: color,
        ttsButton: TtsButton(language: 'en-US', text: content));
  }

  Widget _buildBackWidget(String content) {
    final size = MediaQuery.of(context).size;
    return card(
      english: content,
      size: size.height,
      color: color,
      ttsButton: TtsButton(language: 'vi-VN', text: content),
    );
  }

  void setAutoMode() {
    setState(() {
      isAutoMode = !isAutoMode;
      duration = Duration(seconds: 3);
    });

    print(isAutoMode);
    if (isAutoMode) {
      _timer = Timer.periodic(Duration(seconds: 6), (timer) {
        if (_currentIndex < _words.length) {
          _matchEngine!.currentItem!.like();
        } else {
          _timer?.cancel();
        }
      });
    } else {
      setState(() {
        _timer?.cancel();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    if (_words.isEmpty) {
      return const Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(70),
          child: CustomAppBar(),
        ),
        body: Center(
          child: CircularProgressIndicator(), // Hoặc một tiến trình tải khác
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text('${_currentIndex + 1}/${_words.length}'),
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(16),
                      bottomRight: Radius.circular(16)),
                  color: Colors.red[100],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 6.0),
                  child: Text(
                    '${not_learn.length}',
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      bottomLeft: Radius.circular(16)),
                  color: Colors.green[100],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 6.0),
                  child: Text(
                    '${learn.length}',
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 500,
            child: SwipeCards(
              matchEngine: _matchEngine!,
              itemBuilder: (BuildContext context, int index) {
                // return _buildFrontWidget(
                //   _swipeItems[index].content.english,
                // );
                return FlipCard(
                  direction: FlipDirection.HORIZONTAL, // default

                  front: _buildFrontWidget(
                    _words[index].english,
                  ),
                  back: _buildBackWidget(
                    _words[index].vietnam,
                  ),
                  side: CardSide.FRONT, // The side to initially display.
                  autoFlipDuration: duration,
                );
              },
              onStackFinished: () {
                if (isRecord == true) {
                  recordService.saveRecord(
                      userId: widget.userId,
                      topicId: widget.topic.documentId,
                      percentageCorrect:
                          calculatePercentage(learn, not_learn, _words),
                      correctCount: learn.length,
                      wrongCount: not_learn.length,
                      elapsedTime: _formatElapsedTime(_finalElapsedSeconds),
                      typeTest: "FlashCard");
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WrongWordPage(
                      arguments: NavigationArguments(
                        words: _words,
                        wrong: not_learn,
                        learned: learn,
                      ),
                    ),
                  ),
                );
              },
              upSwipeAllowed: false,
              fillSpace: true,
              likeTag: const Text(
                "Learned",
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 24,
                ),
              ),
              nopeTag: const Text(
                "Learning",
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 24,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              IconButton(onPressed: () {}, icon: Icon(Icons.replay)),
              IconButton(
                  onPressed: () {
                    setState(() {
                      setAutoMode();
                    });
                  },
                  icon:
                      isAutoMode ? Icon(Icons.pause) : Icon(Icons.play_arrow)),
            ],
          )
        ],
      ),
    );
  }
}
