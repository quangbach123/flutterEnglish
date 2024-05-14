import 'dart:async';
import 'dart:math';
import 'package:flashcard/Configs/Constants.dart';
import 'package:flashcard/Models/word.dart';
import 'package:flashcard/Services/RecordService.dart';
import 'package:flashcard/components/home_page/quizzScreen/Quizz_Screen.dart';
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
  const VocabularyGame(
      {Key? key,
      required this.words,
      required this.isEnglishFirst,
      required this.userId,
      required this.topicId,
      required this.isRecord})
      : super(key: key);
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
  late int _elapsedSeconds = 0;
  List<int> wrongAnswerIndexes = [];
  List<int> correct = [];

  late int currentIndex = 0;
  late bool __isEnglishFirst;
  late bool isRecord;

  RecordService recordService = RecordService();

  @override
  void initState() {
    super.initState();
    // _fetchWords();
    _words = widget.words;
    __isEnglishFirst = widget.isEnglishFirst;
    isRecord = widget.isRecord;
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
      if (_userInput.trim().toLowerCase() !=
          (__isEnglishFirst
                  ? _words[currentIndex].vietnam
                  : _words[currentIndex].english)
              .trim()
              .toLowerCase()) {
        setState(() {
          wrongAnswerIndexes.add(currentIndex);
        });
      } else {
        setState(() {
          correct.add(currentIndex);

          _score++;
        });
      }
      if (currentIndex == _words.length - 1) {
        double pertage = calculatePercentage(
            _words.length - wrongAnswerIndexes.length, widget.words.length);
        if (isRecord == true) {
          recordService.saveRecord(
              userId: widget.userId,
              topicId: widget.topicId,
              percentageCorrect: pertage,
              correctCount: _words.length - wrongAnswerIndexes.length,
              wrongCount: wrongAnswerIndexes.length,
              elapsedTime: _formatElapsedTime(_elapsedSeconds),
              typeTest: "FillVocab");
        }
        showResultDialog(
            context,
            _words.length - wrongAnswerIndexes.length,
            wrongAnswerIndexes.length,
            _formatElapsedTime(_elapsedSeconds),
            _words,
            wrongAnswerIndexes,
            correct,
            widget.userId);
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
    if (currentIndex < _words.length) {
      wrongAnswerIndexes.add(currentIndex);
    }
    setState(() {
      if (currentIndex == _words.length - 1) {
        double pertage = calculatePercentage(
            _words.length - wrongAnswerIndexes.length, widget.words.length);
        if (isRecord == true) {
          recordService.saveRecord(
              userId: widget.userId,
              topicId: widget.topicId,
              percentageCorrect: pertage,
              correctCount: _words.length - wrongAnswerIndexes.length,
              wrongCount: wrongAnswerIndexes.length,
              elapsedTime: _formatElapsedTime(_elapsedSeconds),
              typeTest: "FillVocab");
        }
        showResultDialog(
            context,
            _words.length - wrongAnswerIndexes.length,
            wrongAnswerIndexes.length,
            _formatElapsedTime(_elapsedSeconds),
            _words,
            wrongAnswerIndexes,
            correct,
            widget.userId);
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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Câu hỏi: ${currentIndex + 1}/${_words.length}',
                  style: TextStyle(fontSize: 20.0),
                ),
                Text(
                  '${_formatElapsedTime(_elapsedSeconds)}',
                  style: TextStyle(fontSize: 20.0),
                ),
              ],
            ),
            Text(
              '$_currentWord',
              style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
            ),
            Column(
              children: [
                TextFormField(
                  controller: _textEditingController,
                  onChanged: (value) {
                    setState(() {
                      _userInput = value;
                    });
                  },
                  onFieldSubmitted: (value) {
                    _checkAnswer();
                  },
                  decoration: const InputDecoration(
                    labelText: 'Enter Vietnamese translation',
                    border: OutlineInputBorder(),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    TextButton(
                      onPressed: _checkAnswer,
                      child: Text('Nộp bài',
                          style: TextStyle(fontSize: 24, color: Colors.green)),
                    ),
                    TextButton(
                      onPressed: _skipWord,
                      child: Text(
                        'Bỏ qua',
                        style: TextStyle(fontSize: 24, color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

void showResultDialog(
    BuildContext context,
    int correctCount,
    int wrongCount,
    String elapsedTime,
    List<Word> words,
    List<int> wrong,
    List<int> correct,
    String userId) {
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (context) => WrongWordPage(
        arguments: NavigationArguments(
          words: words,
          wrong: wrong,
          learned: correct,
        ),
      ),
    ),
  );
}
