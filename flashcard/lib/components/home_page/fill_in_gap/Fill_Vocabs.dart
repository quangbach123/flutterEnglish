import 'dart:async';
import 'dart:math';
import 'package:flashcard/Configs/Constants.dart';
import 'package:flashcard/Models/word.dart';
import 'package:flashcard/Services/RecordService.dart';
import 'package:flashcard/components/home_page/quizzScreen/Quizz_Screen.dart';
import 'package:flashcard/pages/Topic_home_page.dart';
import 'package:flashcard/pages/review_wrong_word.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VocabularyGame extends StatefulWidget {
  final String topicId;
  final String userId;
  final List<Word> words;
  final bool isEnglishFirst;
  final bool isRecord;
  const VocabularyGame({Key? key, required this.words, required this.isEnglishFirst, required this.userId, required this.topicId, required this.isRecord}) : super(key: key);
  @override
  _VocabularyGameState createState() => _VocabularyGameState();
}

class _VocabularyGameState extends State<VocabularyGame> {
  TextEditingController _textEditingController = TextEditingController();
  late List<Word> _words = [];
  late String _currentWord = '';
  late String _userInput = '';
  late int _score = 0;
  late Timer _timer;
  bool _timerStopped = false;
  int _finalElapsedSeconds = 0;
  late int _elapsedSeconds=0;
  List<int> wrongAnswerIndexes = [];
  late int currentIndex = 0;
  late bool __isEnglishFirst;
  late bool isRecord;

  RecordService recordService = RecordService();

  @override
  void initState() {
    super.initState();
    // _fetchWords();
    _words=widget.words;
    __isEnglishFirst=widget.isEnglishFirst;
    isRecord= widget.isRecord;
    _fetchNextWord();
    startTimer();
    if (kDebugMode) {
      print(_words);
    }
  }

void _fetchNextWord() {
  if (_words.isNotEmpty && currentIndex < _words.length) {
    setState(() {
      if (__isEnglishFirst) {
        _currentWord = _words[currentIndex].english;
      } else {
        _currentWord = _words[currentIndex].vietnam;
      }
    });
  } else {
    print('Empty word list or index out of bounds');
  }
}

void _checkAnswer() {
  if (currentIndex < _words.length) {
    if (_userInput.trim().toLowerCase() != (__isEnglishFirst ? _words[currentIndex].vietnam : _words[currentIndex].english).trim().toLowerCase()) {
      setState(() {
        wrongAnswerIndexes.add(currentIndex);
      });
    }
    else {
      setState(() {
        _score++;
      });
    }
    if (currentIndex == _words.length - 1) {
      double pertage =calculatePercentage(_words.length - wrongAnswerIndexes.length, widget.words.length);
      if(isRecord==true){
              recordService.saveRecord(userId: widget.userId, topicId: widget.topicId, percentageCorrect: pertage, correctCount: _words.length - wrongAnswerIndexes.length, wrongCount: wrongAnswerIndexes.length, elapsedTime: _formatElapsedTime(_elapsedSeconds),typeTest:"FillVocab");

      }
      showResultDialog(context, _words.length - wrongAnswerIndexes.length, wrongAnswerIndexes.length, _formatElapsedTime(_elapsedSeconds), _words, wrongAnswerIndexes,widget.userId);
      return;
    }
    setState(() {
      _userInput = '';
      currentIndex++;
        _textEditingController.clear();
    });
    _fetchNextWord();
  }
}


void _skipWord() {
  if(currentIndex < _words.length){
    wrongAnswerIndexes.add(currentIndex);
  }
  setState(() {
    if (currentIndex == _words.length - 1) {
          double pertage =calculatePercentage(_words.length - wrongAnswerIndexes.length, widget.words.length);
          if(isRecord==true){
            recordService.saveRecord(userId: widget.userId, topicId: widget.topicId, percentageCorrect: pertage, correctCount: _words.length - wrongAnswerIndexes.length, wrongCount: wrongAnswerIndexes.length, elapsedTime: _formatElapsedTime(_elapsedSeconds),typeTest:"FillVocab");

          }
      showResultDialog(context,_words.length-wrongAnswerIndexes.length,wrongAnswerIndexes.length,_formatElapsedTime(_elapsedSeconds),_words,wrongAnswerIndexes,widget.userId);
     
    } else {
      currentIndex++;
      _fetchNextWord();
    }
  });
}
  void startTimer() {
    _elapsedSeconds = 0;
    if (!_timerStopped) {
      _timer = Timer.periodic(Duration(seconds: 1), (timer) {
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
String _formatElapsedTime(int elapsedSeconds) {
  int hours = elapsedSeconds ~/ 3600;
  int minutes = (elapsedSeconds % 3600) ~/ 60;
  int seconds = elapsedSeconds % 60;

  return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
}
// tính phầm trăm câu đúng
double calculatePercentage(int correctCount, int totalCount) {
  if (totalCount == 0) {
    return 0.0;
  }
  return (correctCount / totalCount) * 100.0;
}

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Vocabulary Game'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              '$_currentWord',
              style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20.0),
            TextField(
              controller: _textEditingController,
              onChanged: (value) {
                setState(() {
                  _userInput = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Enter Vietnamese translation',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                  onPressed: _checkAnswer,
                  child: Text('Submit'),
                ),
                ElevatedButton(
                  onPressed: _skipWord,
                  child: Text('Skip'),
                ),
              ],
            ),
            SizedBox(height: 20.0),
            Text(
              'Score: $_score',
              style: TextStyle(fontSize: 20.0),
            ),
            SizedBox(height: 10.0),
            Text(
              '${_formatElapsedTime(_elapsedSeconds)}',
              style: TextStyle(fontSize: 20.0),
            ),
          ],
        ),
      ),
    );
  }
}
void showResultDialog(BuildContext context, int correctCount, int wrongCount, String elapsedTime,List<Word> words, List<int> wrong, String userId) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
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
                Text(
                  'Phần trăm câu đúng: ',
                  style: TextStyle(color: Colors.white),
                ),
                Text(
                  '${calculatePercentage(correctCount, words.length).toStringAsFixed(2)}%',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
            SizedBox(height: 16), // Khoảng cách giữa các dòng
            Text(
              'Đã học: ${correctCount.toString()}',
              style: TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16), // Khoảng cách giữa các dòng
            Text(
              'Chưa học: ${wrongCount.toString()}',
              style: TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16), // Khoảng cách giữa các dòng
            Text(
              'Thời gian hoàn thành: $elapsedTime',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        actions: [
TextButton(
  onPressed: () {
        Navigator.pop(context); 
        Navigator.pop(context);
          },
          child: Text(
            'Đóng',
            style: TextStyle(color: Colors.white),
          ),
        ),

          TextButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => WrongWordPage(
                    arguments: NavigationArguments(
                      words: words,
                      wrong: wrong,
                    ),
                  ),
                ),
              );
            },
            child: Text(
              'Nút tùy chọn',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      );
    },
  );
}
