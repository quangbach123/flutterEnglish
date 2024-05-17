import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flashcard/Configs/Constants.dart';
import 'package:flashcard/Models/Topic.dart';
import 'package:flashcard/Services/RecordService.dart';
import 'package:flashcard/Services/WordServices.dart';
import 'package:flashcard/components/home_page/quizzScreen/Options.dart';
import 'package:flashcard/Models/word.dart';
import 'package:flashcard/pages/review_wrong_word.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../Custom_AppBar.dart';
import 'dart:async';

class QuizzScreen extends StatefulWidget {
  final List<Word> words;
  final bool isEnglishFirst;
  final String userId;
  final String topicId;
  final bool isRecord;
  const QuizzScreen(
      {Key? key,
      required this.words,
      required this.isEnglishFirst,
      required this.userId,
      required this.topicId,
      required this.isRecord});

  @override
  State<QuizzScreen> createState() => _QuizzScreenState();
}

class _QuizzScreenState extends State<QuizzScreen> {
  late String? _question = '';
  late List<String> _answers = [];
  late String _correctAnswer;
  final List<Map<String, String>> _remainingWords = [];
  late bool _isDataLoaded = false;
  late int count = 0;
  List<String> _selectedQuestions = []; // Danh sách các câu hỏi đã được chọn
  late Timer _timer;
  bool _timerStopped = false;
  int _finalElapsedSeconds = 0;
  late int _elapsedSeconds = 0;
  List<Word> correctAnswers = [];
  List<Word> wrongAnswers = [];
  List<Word> words = [];
  late bool isEnglishFirst;
  RecordService recordService = RecordService();
  late bool isRecord;

  void initState() {
    super.initState();
    initializeData();
    isEnglishFirst = widget.isEnglishFirst;
    words = widget.words;
    isRecord = widget.isRecord;
    startTimer();
    int i = words.length;
    int K = _remainingWords.length;
    print('số từ : $i');
    print('số từ còn lại : $K');
    print(_remainingWords);
  }

  void _checkAnswer(String selectedAnswer) {
    Word? selectedWord;
    if (isEnglishFirst) {
      selectedWord = words.firstWhere((word) => word.vietnam == selectedAnswer,
          orElse: () => Word(id: '', english: '', vietnam: '', topicId: ''));
    } else {
      selectedWord = words.firstWhere((word) => word.english == selectedAnswer,
          orElse: () => Word(id: '', english: '', vietnam: '', topicId: ''));
    }

    if (selectedWord != null) {
      if (isEnglishFirst) {
        if (selectedWord.vietnam == _correctAnswer) {
          correctAnswers.add(selectedWord);
          print('add to correct');
        } else {
          wrongAnswers.add(selectedWord);
          print('add to wrong');
        }
      } else {
        if (selectedWord.english == _correctAnswer) {
          correctAnswers.add(selectedWord);
          print('add to correct');
        } else {
          wrongAnswers.add(selectedWord);
          print('add to wrong');
        }
      }
    }
    _fetchQuestion();
  }

  @override
  void dispose() {
    stopTimer(); // Hủy bỏ hàm hẹn giờ trong phương thức
    super.dispose();
  }

  Future<void> initializeData() async {
    await _initRemainingWords(widget.words);
    _fetchQuestion();
  }

  Future<void> _initRemainingWords(List<Word> words) async {
    try {
      _remainingWords.clear();

      for (Word word in words) {
        String english = word.english;
        String vietnam = word.vietnam;

        Map<String, String> wordData = {'english': english, 'vietnam': vietnam};
        _remainingWords.add(wordData);
      }

      print(_remainingWords);
    } catch (error) {
      print('Error initializing remaining words: $error');
    }
  }

void _fetchQuestion() {
  count++;
  var random = Random();

  // Kiểm tra xem danh sách `_remainingWords` có rỗng không
  if (_remainingWords.isEmpty) {
    // Xử lý khi danh sách rỗng
    return;
  }

  var remainingQuestions = _remainingWords.where((word) {
    if (isEnglishFirst) {
      return !_selectedQuestions.contains(word['english']);
    } else {
      return !_selectedQuestions.contains(word['vietnam']);
    }
  }).toList();

  // Kiểm tra xem danh sách `remainingQuestions` có rỗng không
  if (remainingQuestions.isEmpty) {
    showResultDialog(
      context,
      correctAnswers.length,
      wrongAnswers.length,
      _formatElapsedTime(_elapsedSeconds),
      words,
      wrongAnswers,
      correctAnswers,
      widget.userId,
      widget.topicId,
      isRecord,
    );
    return;
  }

  var randomQuestion = remainingQuestions[random.nextInt(remainingQuestions.length)];

  setState(() {
    if (isEnglishFirst) {
      _question = randomQuestion['english'];
      _correctAnswer = randomQuestion['vietnam']!;
    } else {
      _question = randomQuestion['vietnam'];
      _correctAnswer = randomQuestion['english']!;
    }
  });

  var allAnswers = _remainingWords.where((word) {
    if (isEnglishFirst) {
      return word['vietnam'] != _correctAnswer;
    } else {
      return word['english'] != _correctAnswer;
    }
  }).map((word) {
    if (isEnglishFirst) {
      return word['vietnam'];
    } else {
      return word['english'];
    }
  }).toList();

  // Kiểm tra xem danh sách `allAnswers` có rỗng không
  if (allAnswers.isEmpty) {
    // Xử lý khi danh sách trống
    return;
  }

  var answers = [_correctAnswer];

  while (answers.length < 4 && allAnswers.isNotEmpty) {
    var randomAnswer = allAnswers[random.nextInt(allAnswers.length)];
    if (!answers.contains(randomAnswer)) {
      answers.add(randomAnswer!);
    }
  }

  answers.shuffle();
  setState(() {
    _answers = answers;
  });

  if (isEnglishFirst) {
    _selectedQuestions.add(randomQuestion['english']!);
  } else {
    _selectedQuestions.add(randomQuestion['vietnam']!);
  }
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

  @override
  Widget build(BuildContext context) {
    if (_question == null) {
      return Center(
        child: CircularProgressIndicator(),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Câu hỏi số ${count}',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${_formatElapsedTime(_elapsedSeconds)}',
              style: TextStyle(
                  color: Colors.black,
                  fontSize: 15,
                  fontWeight: FontWeight.bold),
            ),
            Text(
              _question!,
              style: TextStyle(
                color: Colors.black,
                fontSize: 40,
                fontWeight: FontWeight.bold,
              ),
            ),
            Column(
              children: _answers.map((answer) {
                return Padding(
                  padding: EdgeInsets.all(1),
                  child: AnswerOptionsWidget(
                    option: answer,
                    onPressed: () {
                      _checkAnswer(answer);
                    },
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

// hàm tìm ra index của các phần tử sai trong mảng words
List<int> findIndexesOfWrongAnswers(List<Word> words, List<Word> wrongAnswers) {
  List<int> indexes = [];
  for (int i = 0; i < words.length; i++) {
    bool isWrongAnswer = false;
    for (Word wrong in wrongAnswers) {
      if (words[i].id == wrong.id) {
        isWrongAnswer = true;
        break;
      }
    }
    if (isWrongAnswer) {
      indexes.add(i);
    }
  }
  return indexes;
}
List<int> findIndexesInWords(List<Word> words, List<Word> answers) {
  List<int> indexes = [];
  for (Word answer in answers) {
    int index = words.indexWhere((word) => word.id == answer.id);
    if (index != -1) {
      indexes.add(index);
    }
  }
  return indexes;
}



// tính phầm trăm câu đúng
double calculatePercentage(int correctCount, int totalCount) {
  if (totalCount == 0) {
    return 0.0;
  }
  return (correctCount / totalCount) * 100.0;
}

void showResultDialog(
    BuildContext context,
    int correctCount,
    int wrongCount,
    String elapsedTime,
    List<Word> words,
    List<Word> wrongAnswers,
    List<Word> correctAnswers,
    String userId,
    String topicId,
    isRecord) {
  RecordService recordSerivce = RecordService();
  if (isRecord == true) {
    recordSerivce.saveRecord(
        userId: userId,
        topicId: topicId,
        percentageCorrect: calculatePercentage(correctCount, words.length),
        correctCount: correctCount,
        wrongCount: wrongCount,
        elapsedTime: elapsedTime,
        typeTest: "Multiple");
  }
  List<int> wrongIndexes = findIndexesInWords(words, wrongAnswers);
  List<int> learnedIndexes = findIndexesInWords(words, correctAnswers);
  print('Số đáp án đúng: ${correctAnswers.length}');
  print('Số đáp án sai: ${wrongAnswers.length}');

  // Print the indexes
  print('Indexes of wrong answers: $wrongIndexes');
  print('Indexes of learned answers: $learnedIndexes');

  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (context) => WrongWordPage(
        arguments: NavigationArguments(
          words: words,
          wrong: wrongIndexes,
          learned: learnedIndexes
        ),
      ),
    ),
  );
}
