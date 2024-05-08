import 'dart:async';
import 'package:flashcard/Configs/Constants.dart';
import 'package:flashcard/Models/Topic.dart';
import 'package:flashcard/Services/RecordService.dart';
import 'package:flashcard/Services/TopicServices.dart';
import 'package:flashcard/Services/UserServices.dart';
import 'package:flashcard/Services/WordServices.dart';
import 'package:flashcard/animations/smooth_prosgres.dart';
import 'package:flashcard/components/card_container.dart';
import 'package:flashcard/components/home_page/Custom_AppBar.dart';
import 'package:flashcard/pages/Topic_home_page.dart';
import 'package:flashcard/pages/review_wrong_word.dart';
import 'package:flashcard/pages/text_to_speech.dart';
import 'package:flashcard/pages/word_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flashcard/animations/card_appear_animation.dart';
import 'package:flashcard/animations/flip_card_animation.dart';
import 'package:flashcard/Models/word.dart';

class FlashCardPage extends StatefulWidget {
  final Topic topic;
  final List<Word> words;
  final bool isEnglishFirst;
  final String userId;
  final bool isRecord;

  const FlashCardPage({Key? key, required this.topic, required this.words, required this.isEnglishFirst, required this.userId, required this.isRecord}) : super(key: key);

  @override
  State<FlashCardPage> createState() => _FlashCardPageState();
}
class _FlashCardPageState extends State<FlashCardPage> with  SingleTickerProviderStateMixin  {

  Offset _cardPosition = Offset.zero;
  bool _isFront = true;
  bool _isAnimating = false;
  List<Word> _words = [];
  List<int> right=[];// list từ đúng
  List<int> wrong=[];//list từ sai
  int _currentIndex = 0;
  final FlutterTts flutterTts = FlutterTts();
  late int _elapsedSeconds; // biến đếm thời gian
  late Timer _timer;
  bool _timerStopped = false;
  int _finalElapsedSeconds = 0;// biến lưu thời gian
  bool _isAlertDialogDisplayed = false; // Biến kiểm soát
  late bool __isEnglishFirst;
  RecordService recordService = RecordService();
   bool _isAutoMode = false; // Biến kiểm soát chế độ tự động
   late bool isRecord;
   
  @override
  void initState() {
    super.initState();
    _words = widget.words; 
    isRecord= widget.isRecord;
    startTimer();
    __isEnglishFirst=widget.isEnglishFirst;
    print(_currentIndex);
    int i =  _words.length;
    print('số từ : $i');
    print(_isAlertDialogDisplayed);
            TopicService topicService = TopicService();
            topicService.incrementView(widget.topic.documentId);
    // controlalert();
  }
  @override
void dispose() {
  stopTimer(); // Hủy bỏ hàm hẹn giờ trong phương thức 
  super.dispose();
}
void controlalert(){
  if(_currentIndex >=_words.length){
    _isAlertDialogDisplayed=true;

  }
}

  void toggleAutoMode() {
    setState(() {
      _isAutoMode = !_isAutoMode;
      if (_isAutoMode) {
        startAutoFlipTimer();
      } else {
        _timer.cancel();
      }
    });
  }

  void startAutoFlipTimer() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      setState(() {
        _isFront = !_isFront;
        _currentIndex = (_currentIndex + 1) % _words.length;
      });
    });
  }
// tính % câu đúng
double calculatePercentage(List<int> right, List<int> wrong, List<Word> words) {
  int totalQuestions = words.length;
  int correctAnswers = right.length;
  double percentage = (correctAnswers / totalQuestions) * 100;
  return percentage;
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

void stopTimer() {
  _timer.cancel();
   _timerStopped = true;
}

// lấy dữ liệu từ vựng 
void _fetchWords() async {
  WordService wordService = WordService();
  try {
    QuerySnapshot snapshot = await wordService.getWordsByTopicId(widget.topic.documentId).first;
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

void _handlePanEnd(Size size) {
  setState(() {
    if (_words.isNotEmpty) {
      _currentIndex++;
      if (_currentIndex >= _words.length) {
        _cardPosition = Offset(size.width * 2, _cardPosition.dy); // Di chuyển thẻ ra khỏi màn hình nếu hết thẻ
        stopTimer(); // Dừng thời gian khi hiển thị AlertDialog
      } else {
        _cardPosition = Offset.zero; // Đặt lại vị trí thẻ về ban đầu
      }
    }
  });
}


Widget _buildFrontWidget(String content) {
  final size = MediaQuery.of(context).size;
  return CardContainer(size: size, content: content, textColor: Colors.black, ttsButton: TtsButton(language: 'en-US', text: content));
}
Widget _buildBackWidget(String content) {
  final size = MediaQuery.of(context).size;
  return CardContainer(size: size, content: content, textColor: Colors.white, ttsButton: TtsButton(language: 'vi-VN', text: content));
}
String _formatElapsedTime(int elapsedSeconds) {
  int hours = elapsedSeconds ~/ 3600;
  int minutes = (elapsedSeconds % 3600) ~/ 60;
  int seconds = elapsedSeconds % 60;

  return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
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
    backgroundColor: oColor,
  ),
  body: Stack(
    children:[ 
      GestureDetector(
      onPanDown: (details) {
      },
      onPanUpdate: (details) {
        if(_currentIndex<_words.length){
                  setState(() {
          _cardPosition += details.delta;
        });
        }
      },
      onPanEnd: (details) {
          if(_currentIndex<_words.length){
                    if (_cardPosition.dx > 0) {
                    // Khi thẻ được kéo sang phải
                    print('Đã học');
                    if(_currentIndex<_words.length){
                      right.add(_currentIndex);
                    }
                    
                  } else if (_cardPosition.dx < 0) {
                    // Khi thẻ được kéo sang trái
                    print('Chưa học');
                    wrong.add(_currentIndex);
                  }
                  setState(() {
                    _cardPosition = _cardPosition.dx > 0
                        ? Offset(size.width * 2, _cardPosition.dy)
                        : Offset(-size.width * 2, _cardPosition.dy);
                  });
                  _handlePanEnd(MediaQuery.of(context).size); // Truyền kích thước màn hình vào _handlePanEnd()
                  if (_cardPosition.dx != 0) {
                    // Chỉ chạy animation khi thẻ được kéo (không chạy khi load lần đầu)
                  }
          }
      },
child: _currentIndex < _words.length
    ? Container(
        margin: const EdgeInsets.symmetric(horizontal: 16), // Khoảng cách giữa Card và Progress Bar
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15), // Bo góc của Container
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CardAppearAnimation(
              child: Transform.translate(
                offset: _cardPosition,
                child: FlipCardAnimation(
                 frontWidget: _isFront
                    ? (__isEnglishFirst
                        ? _buildFrontWidget(_words.isNotEmpty ? _words[_currentIndex].english : "")
                        : _buildBackWidget(_words.isNotEmpty ? _words[_currentIndex].vietnam : ""))
                    : (__isEnglishFirst
                        ? _buildBackWidget(_words.isNotEmpty ? _words[_currentIndex].vietnam : "")
                        : _buildFrontWidget(_words.isNotEmpty ? _words[_currentIndex].english : "")),
                backWidget: _isFront
                    ? (__isEnglishFirst
                        ? _buildBackWidget(_words.isNotEmpty ? _words[_currentIndex].vietnam : "")
                        : _buildFrontWidget(_words.isNotEmpty ? _words[_currentIndex].english : ""))
                    : (__isEnglishFirst
                        ? _buildFrontWidget(_words.isNotEmpty ? _words[_currentIndex].english : "")
                        : _buildBackWidget(_words.isNotEmpty ? _words[_currentIndex].vietnam : "")),

                  direction: FlipDirection.horizontal,
                  onAnimationStart: () {
                    setState(() {
                      _isAnimating = true;
                    });
                  },
                  onAnimationEnd: () {
                    setState(() {
                      _isAnimating = false;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 20), // Khoảng cách giữa Card và Progress Bar
            FractionallySizedBox(
              // widthFactor: 1.0, // Tự động điều chỉnh chiều rộng của thanh Progress Bar theo chiều rộng của Container
              child: Container(
                height: 20, // Chiều cao của thanh Progress Bar
                width: 450,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(50), // Bo góc của Container
                ),
                child: SmoothLinearProgressIndicator(
                  value: (_currentIndex + 1) / _words.length,
                ),

              ),
            ),
            
            Positioned(
            bottom: 16,
            right: 16,
            child: ElevatedButton(
              onPressed: toggleAutoMode,
              child: Text(_isAutoMode ? 'Manual Mode' : 'Auto Mode'),
            ),
          ),
          ],
        ),
      )
    : AlertDialog(
      backgroundColor: oColor,
      title: const Text(
        'KẾT QUẢ HỌC TẬP',
        style: TextStyle(color: Colors.white),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
                Row(
        children: [
          const Text(
            'Phần trăm câu đúng: ',
            style: TextStyle(color: Colors.white),
          ),
          Text(
            '${calculatePercentage(right, wrong, _words).toStringAsFixed(2)}%',
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
          const SizedBox(height: 16), // Khoảng cách giữa các dòng
          Text(
            'Đã học: ${right.toString()}',
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 16), // Khoảng cách giữa các dòng
          Text(
            'Chưa học: ${wrong.toString()}',
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 16), // Khoảng cách giữa các dòng
          Text(
            'Thời gian hoàn thành: ${_formatElapsedTime(_finalElapsedSeconds)}',
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
              if(isRecord==true){
                recordService.saveRecord(
                userId: widget.userId,
                topicId: widget.topic.documentId,
                percentageCorrect: calculatePercentage(right,  wrong, _words),
                correctCount: right.length,
                wrongCount: wrong.length,
                elapsedTime: _formatElapsedTime(_finalElapsedSeconds),
                typeTest:"FlashCard"
              );
            }
              Navigator.pop(context); 
          },
          child: const Text(
            'Đóng',
            style: TextStyle(color: Colors.white),
          ),
        ),
        TextButton(
          onPressed: () {
            if(isRecord==true){
                recordService.saveRecord(
                userId: widget.userId,
                topicId: widget.topic.documentId,
                percentageCorrect: calculatePercentage(right,  wrong, _words),
                correctCount: right.length,
                wrongCount: wrong.length,
                elapsedTime: _formatElapsedTime(_finalElapsedSeconds),
                typeTest:"FlashCard"
              );
            }
             Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => WrongWordPage(
                    arguments: NavigationArguments(
                      words: _words,
                      wrong: wrong,
                    ),
                  ),
                ),
              );
          },
          child: const Text(
            'Nút tùy chọn',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    ),
    ),
     Positioned(
        top: 0,
        right: 0,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            'Time: ${_formatElapsedTime(_elapsedSeconds)}',
            style: const TextStyle(
              fontSize: 20.0,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
  ]
  ),
);

}
}


