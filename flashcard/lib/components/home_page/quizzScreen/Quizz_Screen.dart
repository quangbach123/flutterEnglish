import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flashcard/Configs/Constants.dart';
import 'package:flashcard/Models/Topic.dart';
import 'package:flashcard/Services/RecordService.dart';
import 'package:flashcard/Services/WordServices.dart';
import 'package:flashcard/components/home_page/quizzScreen/Options.dart';
import 'package:flashcard/Models/word.dart';
import 'package:flashcard/pages/Topic_home_page.dart';
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
  const QuizzScreen({Key? key, required this.words, required this.isEnglishFirst, required this.userId, required this.topicId, required this.isRecord});

  @override
  State<QuizzScreen> createState() => _QuizzScreenState();
}
class _QuizzScreenState extends State<QuizzScreen> {
  late String? _question='';
  late List<String> _answers = [];
  late String _correctAnswer;
  final List<Map<String, String>> _remainingWords = [];
  late bool _isDataLoaded = false;
  late int count=0;
  List<String> _selectedQuestions = []; // Danh sách các câu hỏi đã được chọn
  late Timer _timer;
  bool _timerStopped = false;
  int _finalElapsedSeconds = 0;
  late int _elapsedSeconds=0;
  List<Word> correctAnswers = [];
  List<Word> wrongAnswers = [];
  List<Word> words = [];
  late bool isEnglishFirst;
  RecordService recordService = RecordService();
  late bool isRecord;


void initState() {
  super.initState();
  initializeData();
  isEnglishFirst=widget.isEnglishFirst;
  words=widget.words;
  isRecord= widget.isRecord;
  startTimer();
  int i= words.length;
  int K =_remainingWords.length; 
  print('số từ : $i');
  print('số từ còn lại : $K');
  print(_remainingWords);
}


void _checkAnswer(String selectedAnswer) {
  // count++;
  Word? selectedWord;
  if (isEnglishFirst) {
    selectedWord = words.firstWhere((word) => word.vietnam == selectedAnswer, orElse: () => Word(id: '', english: '', vietnam: '', topicId: ''));
  } else {
    selectedWord = words.firstWhere((word) => word.english == selectedAnswer, orElse: () => Word(id: '', english: '', vietnam: '', topicId: ''));
  }

  if (selectedWord != null) {
    if (isEnglishFirst) {
      if (selectedWord.vietnam == _correctAnswer) {
        correctAnswers.add(selectedWord);
      } else {
        wrongAnswers.add(selectedWord);
      }
    } else {
      if (selectedWord.english == _correctAnswer) {
        correctAnswers.add(selectedWord);
      } else {
        wrongAnswers.add(selectedWord);
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

  // Future<void> _initRemainingWords() async {
  //   WordService wordService = WordService();
  //   try {
  //     QuerySnapshot snapshot = await wordService.getWordsStream().first;
  //     _remainingWords.clear();
      
  //     for (QueryDocumentSnapshot doc in snapshot.docs) {
  //       String english = doc['english'];
  //       String vietnam = doc['vietnam'];
        
  //       Map<String, String> word = {'english': english, 'vietnam': vietnam};
  //       _remainingWords.add(word);
  //     }
  //     print(_remainingWords);
  //   } catch (error) {
  //     print('Error initializing remaining words: $error');
  //   }
  // }
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

  var remainingQuestions = _remainingWords.where((word) {
    if (isEnglishFirst) {
      return !_selectedQuestions.contains(word['english']);
    } else {
      return !_selectedQuestions.contains(word['vietnam']);
    }
  }).toList();
  
  if (remainingQuestions.isEmpty) {
    showResultDialog(context, correctAnswers.length, wrongAnswers.length, _formatElapsedTime(_elapsedSeconds), words, wrongAnswers,widget.userId,widget.topicId,isRecord);
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
    backgroundColor: oColor,
  ),
  body: Padding(
    padding: EdgeInsets.all(8),
    child: Center(
      child: Column(
        children: [
          SizedBox(
            height: 300,
            child: Stack(
              children: [
                Container(
                  height: 200,
                  width: 390,
                  decoration: BoxDecoration(
                    color: backColor,
                    borderRadius: BorderRadius.circular(20)
                  ),
                ),
                Positioned(
                  bottom: 60,
                  left: 22,
                  child: Container(
                    height: 170,
                    width: 350,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          offset: Offset(0,1),
                          blurRadius: 5,
                          spreadRadius: 3,
                          color: themeColor.withOpacity(.4)
                        )
                      ]
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                                Text(
                                  wrongAnswers.length.toString(),
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              Text(
                                correctAnswers.length.toString(),
                                style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            ],
                          ),
                          SizedBox(height: 40),
                          Center(
                            child: Text(
                              'Câu hỏi số ${count + 0}',
                              style: TextStyle(
                                color: oColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                          SizedBox(height: 10,),
                          Center(
                            child: Text(
                              _question!,
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 180,
                  left: 135,
                  child: Container(
                    width: 100, // Độ rộng mong muốn
                    height: 100, // Độ cao mong muốn
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          spreadRadius: 5,
                          blurRadius: 7,
                          offset: Offset(0, 3), // Thay đổi vị trí của bóng đổ
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        '${_formatElapsedTime(_elapsedSeconds)}',
                        style: TextStyle(color: oColor, fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: _answers.map((answer) {
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 5),
                child: Column(
                  children: [
                    AnswerOptionsWidget(option: answer, onPressed: () { 
                        // count++;
                        // if (count>= _remainingWords.length) {
                        //   stopTimer(); 
                        //   // print(correctAnswers.length);
                        //   // print(wrongAnswers.length);
                        //   showResultDialog(context,correctAnswers.length,wrongAnswers.length,_formatElapsedTime(_elapsedSeconds),words,wrongAnswers);
                        //   return;
                        //   }
                          _checkAnswer(answer);  
                    },),
                    SizedBox(height: 10), // Thêm khoảng cách giữa các phần tử
                  ],
                ),
              );
            }).toList(),
          ),
          SizedBox(height: 20),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 18),
            child: ElevatedButton (
              style: ElevatedButton.styleFrom(
                primary: oColor,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 5
              ),  
              onPressed: () {
                  // count++;
                  // if (count> _remainingWords.length) {
                  //   stopTimer(); 
                  //   // print(correctAnswers.length);
                  //   // print(wrongAnswers.length);
                  //  showResultDialog(context,correctAnswers.length,wrongAnswers.length,_formatElapsedTime(_elapsedSeconds),words,wrongAnswers);
                  //   return;
                  // }
                Word? selectedWord = words.firstWhere((word) => word.english == _question, orElse: () => Word(id: '', english: '', vietnam: '', topicId: ''));
                wrongAnswers.add(selectedWord);
               _fetchQuestion(); // Gọi hàm _fetchQuestion để lấy câu hỏi mới
              },  
              child: Container(
                alignment: Alignment.center,
                child: const Text(
                  'Next',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    ),
  ),
);
  }
}

// hàm tìm ra index của các phần tử sai trong mảng words
List<int> findIndexesOfWrongAnswers(List<Word> words, List<Word> wrongAnswers) {
  List<int> indexes = [];

  for (int i = 0; i < words.length; i++) {
    if (wrongAnswers.contains(words[i])) {
      indexes.add(i);
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

// hàm show dialog
// void showResultDialog(BuildContext context, int correctCount, int wrongCount, String elapsedTime,List<Word> words, List<Word> wrong, String userId, String topicId,isRecord) {
//   RecordService recordSerivce = RecordService();
//   if(isRecord==true){
//                 recordSerivce.saveRecord(
//                 userId: userId,
//                 topicId: topicId,
//                 percentageCorrect: calculatePercentage(correctCount, words.length),
//                 correctCount: correctCount,
//                 wrongCount: wrongCount,
//                 elapsedTime: elapsedTime,
//                 typeTest:"Multiple"
//                 );

//   }
//   showDialog(
//     context: context,
//     builder: (BuildContext context) {
//       return AlertDialog(
//         backgroundColor: oColor,
//         title: const Text(
//           'KẾT QUẢ HỌC TẬP',
//           style: TextStyle(color: Colors.white),
//         ),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Text(
//                   'Phần trăm câu đúng: ',
//                   style: TextStyle(color: Colors.white),
//                 ),
//                 Text(
//                   '${calculatePercentage(correctCount, words.length).toStringAsFixed(2)}%',
//                   style: TextStyle(color: Colors.white),
//                 ),
//               ],
//             ),
//             SizedBox(height: 16), // Khoảng cách giữa các dòng
//             Text(
//               'Đã học: ${correctCount.toString()}',
//               style: TextStyle(color: Colors.white),
//             ),
//             const SizedBox(height: 16), // Khoảng cách giữa các dòng
//             Text(
//               'Chưa học: ${wrongCount.toString()}',
//               style: TextStyle(color: Colors.white),
//             ),
//             const SizedBox(height: 16), // Khoảng cách giữa các dòng
//             Text(
//               'Thời gian hoàn thành: $elapsedTime',
//               style: TextStyle(color: Colors.white),
//             ),
//           ],
//         ),
//         actions: [
//           TextButton(
//             onPressed: () {
//                Navigator.pop(context); 
//             },
//             child: Text(
//               'Đóng',
//               style: TextStyle(color: Colors.white),
//             ),
//           ),
//           TextButton(
//             onPressed: () {
//               Navigator.pushReplacement(
//                 context,
//                 MaterialPageRoute(
//                   builder: (context) => WrongWordPage(
//                     arguments: NavigationArguments(
//                       words: words,
//                       wrong: findIndexesOfWrongAnswers(words,wrong),
//                     ),
//                   ),
//                 ),
//               );
//             },
//             child: Text(
//               'Nút tùy chọn',
//               style: TextStyle(color: Colors.white),
//             ),
//           ),
//         ],
//       );
//     },
//   );
//   } 

void showResultDialog(BuildContext context, int correctCount, int wrongCount, String elapsedTime,List<Word> words, List<Word> wrong, String userId, String topicId,isRecord) {
  RecordService recordSerivce = RecordService();
  if(isRecord==true){
    recordSerivce.saveRecord(
      userId: userId,
      topicId: topicId,
      percentageCorrect: calculatePercentage(correctCount, words.length),
      correctCount: correctCount,
      wrongCount: wrongCount,
      elapsedTime: elapsedTime,
      typeTest:"Multiple"
    );
  }
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
              // Đóng hộp thoại
              Navigator.pop(context);
              // Đóng màn hình hiện tại và quay lại màn hình trước đó
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
            wrong: findIndexesOfWrongAnswers(words, wrong),
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
