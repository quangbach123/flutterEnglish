import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:io' as io;
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:flashcard/Services/RecordService.dart';
import 'package:flashcard/animations/flip_card_animation.dart';
import 'package:flashcard/components/card.dart';
import 'package:flashcard/pages/text_to_speech.dart';
import 'package:flip_card/flip_card.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart' as mobile;
import 'package:file_selector/file_selector.dart' as web;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:universal_html/html.dart' as html;
import 'package:flashcard/Models/Topic.dart';
import 'package:flashcard/Models/word.dart';
import 'package:flashcard/Services/TopicServices.dart';
import 'package:flashcard/Services/WordServices.dart';
import 'package:flashcard/components/home_page/fill_in_gap/Fill_Vocabs.dart';
import 'package:flashcard/components/home_page/quizzScreen/Quizz_Screen.dart';
import 'package:flashcard/pages/add_word_page.dart';
import 'package:flashcard/pages/flashcard_page.dart';
import 'package:flashcard/pages/ranking.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_tts/flutter_tts.dart';

class WordListPage extends StatefulWidget {
  final String topicId;
  final String userId;

  WordListPage({required this.topicId, required this.userId});

  @override
  _WordListPageState createState() => _WordListPageState();
}

class _WordListPageState extends State<WordListPage> {
  final List<Word> _words = []; // list từ mặc định gọi từ id
  List<Word> _favoriteWords = []; // list từ yêu thích
  List<String> _favoriteWordIds = []; // list id từ iêu thích
  late Topic _topic;
  bool _isStudyAllSelected = true; // biến chọn làm full đề
  bool _isStudyFavoriteSelected = false; // biến chọn chỉ làm từ yêu thích
  bool _isEnglishFirst =
      true; // biến chọn  hiển thị tiếng anh trước , ngược lại thì tiếng việt
  bool _isLoading = true; // biến kiểm tra loading
  bool _isUserIdMatch =
      false; // Biến để kiểm tra xem userId có khớp với userId của topic không
  late Future<List<DocumentSnapshot>> _recordListFuture;
  Future<void> _loadTopic() async {
    try {
      String id = widget.topicId;
      TopicService topicService = TopicService();
      Topic topic = await topicService.getTopicById(id);
      _topic = topic; // Gán giá trị từ tương lai đã hoàn thành cho _topic
      setState(() {
        // Không cần gọi setState vì _topic đã được gán giá trị trong hàm initState
      });
    } catch (error) {
      print("Error loading topic: $error");
      // Xử lý lỗi nếu cần thiết
    }
  }

  void _handleStudyAll() {
    setState(() {
      _isStudyAllSelected = !_isStudyAllSelected;
      _isStudyFavoriteSelected =
          false; // Đảm bảo chỉ một trong hai biến được chọn
    });
  }

  void _handleStudyFavorite() {
    setState(() {
      _isStudyAllSelected = false; // Đảm bảo chỉ một trong hai biến được chọn
      _isStudyFavoriteSelected = !_isStudyFavoriteSelected;
    });
  }

  Future<void> exportToCSV(
      BuildContext context, List<Word> words, String topicId) async {
    try {
      // Tạo một chuỗi CSV từ danh sách từ
      String csvData = 'English,Vietnamese\n';
      for (Word word in words) {
        csvData += '${word.english},${word.vietnam}\n';
      }

      // Thực hiện tạo tệp CSV trên cả web và di động
      if (kIsWeb) {
        // Trên web, chúng ta tạo một blob từ dữ liệu CSV
        final encodedData = utf8.encode(csvData);
        final blob = html.Blob([encodedData]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute("download", "word_list_$topicId.csv")
          ..click();
      } else {
        // Trên di động, chúng ta lưu file CSV vào thư mục Downloads
        final downloadsDirectory = await getExternalStorageDirectory();
        final file = File('${downloadsDirectory!.path}/word_list_$topicId.csv');
        await file.writeAsString(csvData);
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('File Saved'),
              content: Text('CSV file saved at: ${file.path}'),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('OK'),
                ),
              ],
            );
          },
        );
      }
    } catch (error) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Error'),
            content: Text('An error occurred: $error'),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  // Hàm để kiểm tra xem userId có khớp với userId của topic không
  void _checkUserIdMatch() async {
    // Lấy userId của topic
    TopicService topicService = TopicService();
    Topic topic = await topicService.getTopicById(widget.topicId);
    String topicUserId =
        topic.userId ?? ''; // Gán một giá trị mặc định nếu topic.userId là null

    // Lấy userId từ widget
    String currentUserId = widget.userId;

    // Kiểm tra xem hai userId có khớp nhau không
    if (topicUserId == currentUserId) {
      setState(() {
        _isUserIdMatch = true;
      });
    }
  }

  final WordService _wordService = WordService();
  FlutterTts flutterTts = FlutterTts();
  Future<void> _speak(String language, String text) async {
    await flutterTts.setLanguage(language);

    await flutterTts.speak(text);
  }

  Future<void> _toggleFavorite(String wordId) async {
    if (_favoriteWordIds.contains(wordId)) {
      // Nếu từ đã nằm trong danh sách yêu thích, xóa nó ra khỏi danh sách
      setState(() {
        _favoriteWordIds.remove(wordId);
        print(_favoriteWordIds.length);
      });
    } else {
      // Nếu từ chưa nằm trong danh sách yêu thích, thêm nó vào danh sách
      setState(() {
        _favoriteWordIds.add(wordId);
        print(_favoriteWordIds.length);
        print(_isStudyAllSelected);
      });
    }
  }

  bool _isFavorite(String wordId) {
    // Kiểm tra xem từ có trong danh sách yêu thích không
    return _favoriteWordIds.contains(wordId);
  }

  void _checkFavoriteWords() {
    if (_favoriteWordIds.isEmpty) {
      _isStudyAllSelected = true;
      _isStudyFavoriteSelected = false;
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchWords();
    _checkUserIdMatch();
    _checkFavoriteWords();
    _loadTopic(); // Gọi hàm tải chủ đề
    print('hiển thị mặc định tiếng anh trước: $_isEnglishFirst');
    RecordService recordService = RecordService();
    _recordListFuture = recordService.getRecordsByTypeTestTopicIdAndUserId(
        'FlashCard', widget.topicId, widget.userId);
    _recordListFuture.then((records) {
      if (records.isNotEmpty) {
        final percentageCorrect = records.first['percentageCorrect'];
        print('Percentage Correct: $percentageCorrect');
      } else {
        print('No records found');
      }
    });
  }

  // tạo danh sách từ học mặc định
  void _addFavoriteWords() {
    _favoriteWords
        .clear(); // Xóa danh sách từ yêu thích hiện tại để chuẩn bị thêm mới

    // Lặp qua từng từ trong _words
    for (Word word in _words) {
      // Nếu id của từ đó tồn tại trong danh sách _favoriteWordIds
      if (_favoriteWordIds.contains(word.id)) {
        // Thêm từ đó vào danh sách _favoriteWords
        _favoriteWords.add(word);
      }
    }
  }

  Future<void> _fetchWords() async {
    setState(() {
      // Đánh dấu rằng đang tải dữ liệu
      _isLoading = true;
    });

    WordService wordService = WordService();
    try {
      QuerySnapshot snapshot =
          await wordService.getWordsByTopicId(widget.topicId).first;
      _words.clear();
      for (QueryDocumentSnapshot doc in snapshot.docs) {
        String documentId = doc.id;
        String english = doc['english'];
        String vietnam = doc['vietnam'];
        // Lấy reference đến topicId
        DocumentReference topicRef = doc['topicId'];

        // ignore: unnecessary_null_comparison
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

      setState(() {
        // Đánh dấu rằng việc tải dữ liệu đã hoàn thành
        _isLoading = false;
      });
    } catch (error) {
      print('Error fetching words: $error');
    }
  }

  final controller = PageController(initialPage: 0);

  @override
  Widget build(BuildContext context) {
    if (_words.isEmpty) {
      // Hiển thị thông báo khi không có từ nào trong chủ đề
      return Scaffold(
        appBar: AppBar(
          actions: [
            _isUserIdMatch
                ? IconButton(
                    icon: Icon(Icons.add),
                    onPressed: () {
                      _addNewWord();
                    },
                  )
                : Container(),
          ],
        ),
        body: Center(
          child: _isLoading
              ? const CircularProgressIndicator() // Hiển thị loading indicator nếu đang tải dữ liệu
              : const Text('No words found'),
          // Hiển thị "No words found" nếu không có dữ liệu
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              _addNewWord();
            },
          ),
        ],
      ),
      body: _topic == null
          ? CircularProgressIndicator()
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Column(
                        children: [
                          Container(
                              height: 200,
                              child: PageView.builder(
                                  controller: controller,
                                  itemCount: _words.length,
                                  itemBuilder: (context, index) => FlipCard(
                                        direction:
                                            FlipDirection.VERTICAL, // default

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
                                        side: CardSide
                                            .FRONT, // The side to initially display.
                                      ))),
                          const SizedBox(height: 16),
                          SmoothPageIndicator(
                            controller: controller,
                            count: _words.length,
                            onDotClicked: (index) {
                              controller.animateToPage(index,
                                  duration: const Duration(milliseconds: 500),
                                  curve: Curves.easeIn);
                            },
                            effect: WormEffect(
                                dotHeight: 8.0,
                                dotWidth: 8.0,
                                spacing: 4,
                                activeDotColor: Colors.black,
                                dotColor: Colors.grey[300]!),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${_topic.topicName}',
                              style: TextStyle(
                                  fontSize: 24, fontWeight: FontWeight.bold)),
                          Visibility(
                            visible: !_isLoading,
                            child: IconButton(
                              icon: Icon(Icons.download_sharp),
                              onPressed: () {
                                // Truyền danh sách từ vào hàm
                                exportToCSV(
                                    this.context, _words, widget.topicId);
                              },
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          CircleAvatar(
                              radius: 20,
                              backgroundImage: NetworkImage(_topic
                                      .userAvatarUrl ??
                                  'https://www.pngkey.com/png/full/114-1149878_setting-user-avatar-in-specific-size-without-breaking.png')),
                          const SizedBox(width: 8),
                          Text(_topic.userName ?? 'Unknown'),
                          const SizedBox(width: 8),
                          VerticalDivider(
                            color: Colors.black,
                            thickness: 2,
                          ),
                          Text('${_words.length} thuật ngữ'),
                        ],
                      ),
                      Visibility(
                        visible: !_isLoading,
                        child: Switch(
                          value: _isEnglishFirst,
                          onChanged: (newValue) {
                            setState(() {
                              _isEnglishFirst = newValue;
                              print(
                                  'hiển thị mặc định tiếng anh trước: $_isEnglishFirst');
                            });
                          },
                        ),
                      ),
                      Visibility(
                        visible: !_isLoading,
                        child: FutureBuilder<List<DocumentSnapshot>>(
                          future: _recordListFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const CircularProgressIndicator();
                            } else if (snapshot.hasError) {
                              return Text('Error: ${snapshot.error}');
                            } else if (!snapshot.hasData ||
                                snapshot.data!.isEmpty) {
                              return Text('No records found');
                            } else {
                              // Lấy percentageCorrect từ danh sách bản ghi
                              double percentageCorrect = snapshot.data![0]
                                      ['percentageCorrect']
                                  .toDouble();
                              return Card(
                                child: ListTile(
                                  title: const Text(
                                    'Kết quả gần đây',
                                    style: TextStyle(fontSize: 20),
                                  ),
                                  subtitle: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
                                    children: [
                                      CircularPercentIndicator(
                                        animation: true,
                                        radius: 40.0,
                                        lineWidth: 10.0,
                                        percent: percentageCorrect / 100,
                                        center: Text(
                                          '${percentageCorrect.toStringAsFixed(0)}%',
                                          style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold),
                                        ),
                                        progressColor: Colors.green,
                                        backgroundColor: Colors.orange,
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Số lần làm: ${snapshot.data![0]['times']}',
                                            style:
                                                TextStyle(color: Colors.black),
                                          ),
                                          Text(
                                            'Số câu đúng: ${snapshot.data![0]['correctCount']}',
                                            style:
                                                TextStyle(color: Colors.green),
                                          ),
                                          Text(
                                            'Số câu sai: ${snapshot.data![0]['wrongCount']}',
                                            style:
                                                TextStyle(color: Colors.orange),
                                          ),
                                        ],
                                      )
                                    ],
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                      Visibility(
                        visible: !_isLoading,
                        child: Card(
                          child: ListTile(
                            onTap: () {
                              if (_favoriteWordIds.isEmpty) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => FlashCardPage(
                                      topic: _topic,
                                      words: _words,
                                      isEnglishFirst: _isEnglishFirst,
                                      userId: widget.userId,
                                      isRecord:
                                          _isStudyAllSelected ? true : false,
                                    ),
                                  ),
                                );
                              } else {
                                if (_isStudyAllSelected == true) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => FlashCardPage(
                                        topic: _topic,
                                        words: _words,
                                        isEnglishFirst: _isEnglishFirst,
                                        userId: widget.userId,
                                        isRecord:
                                            _isStudyAllSelected ? true : false,
                                      ),
                                    ),
                                  );
                                } else {
                                  _addFavoriteWords();
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => FlashCardPage(
                                        topic: _topic,
                                        words: _favoriteWords,
                                        isEnglishFirst: _isEnglishFirst,
                                        userId: widget.userId,
                                        isRecord:
                                            _isStudyAllSelected ? true : false,
                                      ),
                                    ),
                                  );
                                }
                              }
                            },
                            leading: const Icon(Icons.quiz),
                            iconColor: const Color.fromRGBO(75, 0, 130, 1),
                            title: const Text(
                              'Thẻ ghi nhớ',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                      Visibility(
                        visible: !_isLoading,
                        child: Card(
                          child: ListTile(
                            onTap: () {
                              if (_favoriteWordIds.isEmpty) {
                                if (_words.length < 4) {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: Text('Cảnh báo'),
                                      content: Text(
                                          'Bạn cần tối thiểu 4 từ để chơi.'),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            print(_favoriteWords.length);
                                            Navigator.pop(
                                                context); // Đóng dialog
                                          },
                                          child: Text('OK'),
                                        ),
                                      ],
                                    ),
                                  );
                                } else {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => QuizzScreen(
                                        words: _words,
                                        isEnglishFirst: _isEnglishFirst,
                                        userId: widget.userId,
                                        topicId: widget.topicId,
                                        isRecord:
                                            _isStudyAllSelected ? true : false,
                                      ),
                                    ),
                                  );
                                }
                              } else {
                                if (_isStudyAllSelected == true) {
                                  if (_words.length < 4) {
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: Text('Cảnh báo'),
                                        content: Text(
                                            'Bạn cần tối thiểu 4 từ để chơi.'),
                                        actions: [
                                          TextButton(
                                            onPressed: () {
                                              print(_favoriteWords.length);
                                              Navigator.pop(
                                                  context); // Đóng dialog
                                            },
                                            child: Text('OK'),
                                          ),
                                        ],
                                      ),
                                    );
                                  } else {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => QuizzScreen(
                                          words: _words,
                                          isEnglishFirst: _isEnglishFirst,
                                          userId: widget.userId,
                                          topicId: widget.topicId,
                                          isRecord: _isStudyAllSelected
                                              ? true
                                              : false,
                                        ),
                                      ),
                                    );
                                  }
                                } else {
                                  if (_favoriteWordIds.length < 4) {
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: Text('Cảnh báo'),
                                        content: Text(
                                            'Bạn cần tối thiểu 4 từ để chơi.'),
                                        actions: [
                                          TextButton(
                                            onPressed: () {
                                              print(_favoriteWords.length);
                                              Navigator.pop(
                                                  context); // Đóng dialog
                                            },
                                            child: Text('OK'),
                                          ),
                                        ],
                                      ),
                                    );
                                  } else {
                                    _addFavoriteWords();
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => QuizzScreen(
                                          words: _favoriteWords,
                                          isEnglishFirst: _isEnglishFirst,
                                          userId: widget.userId,
                                          topicId: widget.topicId,
                                          isRecord: _isStudyAllSelected
                                              ? true
                                              : false,
                                        ),
                                      ),
                                    );
                                  }
                                }
                              }
                            },
                            leading: const Icon(Icons.checklist_rtl_rounded),
                            iconColor: const Color.fromRGBO(75, 0, 130, 1),
                            title: const Text(
                              'Trắc nghiệm',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                      Visibility(
                        visible: !_isLoading,
                        child: Card(
                          child: ListTile(
                            onTap: () {
                              if (_favoriteWordIds.isEmpty) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => VocabularyGame(
                                      words: _words,
                                      isEnglishFirst: _isEnglishFirst,
                                      userId: widget.userId,
                                      topicId: widget.topicId,
                                      isRecord:
                                          _isStudyAllSelected ? true : false,
                                    ),
                                  ),
                                );
                              } else {
                                if (_isStudyAllSelected == true) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => VocabularyGame(
                                        words: _words,
                                        isEnglishFirst: _isEnglishFirst,
                                        userId: widget.userId,
                                        topicId: widget.topicId,
                                        isRecord:
                                            _isStudyAllSelected ? true : false,
                                      ),
                                    ),
                                  );
                                } else {
                                  _addFavoriteWords();
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => VocabularyGame(
                                        words: _favoriteWords,
                                        isEnglishFirst: _isEnglishFirst,
                                        userId: widget.userId,
                                        topicId: widget.topicId,
                                        isRecord:
                                            _isStudyAllSelected ? true : false,
                                      ),
                                    ),
                                  );
                                }
                              }
                            },
                            leading: const Icon(Icons.edit),
                            iconColor: const Color.fromRGBO(75, 0, 130, 1),
                            title: const Text(
                              'Điền từ',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                      Visibility(
                        visible: !_isLoading,
                        child: Card(
                          child: ListTile(
                            leading: Icon(Icons.format_list_numbered),
                            iconColor: const Color.fromRGBO(75, 0, 130, 1),
                            title: Text(
                              'Bảng xếp hạng',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => RecordListPage(
                                    topicId: widget.topicId,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_favoriteWordIds.isNotEmpty)
                        Row(
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _isStudyAllSelected = true;
                                  _isStudyFavoriteSelected = false;
                                });
                                // Xử lý khi nhấn nút "học hết"
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _isStudyAllSelected
                                    ? Colors.yellow
                                    : Colors.grey,
                              ),
                              child: Text('Học hết'),
                            ),
                            SizedBox(width: 8), // Khoảng cách giữa hai nút
                            ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _isStudyAllSelected = false;
                                  _isStudyFavoriteSelected = true;
                                });
                                // Xử lý khi nhấn nút "học từ yêu thích"
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _isStudyFavoriteSelected
                                    ? Colors.yellow
                                    : Colors.grey,
                              ),
                              child: Text('Học từ yêu thích'),
                            ),
                          ],
                        ),
                      const SizedBox(height: 8),
                      Text('Danh sách từ vựng', style: TextStyle(fontSize: 24)),
                      const SizedBox(height: 8),
                      Visibility(
                        visible: !_isLoading,
                        child: ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: _words.length,
                          itemBuilder: (context, index) {
                            final word = _words[index];
                            final english = _words[index].english;
                            final vietnam = _words[index].vietnam;
                            final isFavorite =
                                _favoriteWordIds.contains(_words[index].id);
                            print("Is favorite: $isFavorite");
                            return Card(
                              child: ListTile(
                                title: Text(english),
                                subtitle: Text(vietnam),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.edit),
                                      onPressed: () {
                                        _editWord(context, _words[index].id,
                                            widget.topicId, english, vietnam);
                                      },
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.delete),
                                      onPressed: () {
                                        _deleteWord(_words[index].id);
                                      },
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.star,
                                          color: isFavorite
                                              ? Colors.yellow
                                              : Colors.grey),
                                      onPressed: () {
                                        _toggleFavorite(word.id);
                                      },
                                    ),
                                    IconButton(
                                      onPressed: () {
                                        _speak('en-US', english);

                                        Future.delayed(
                                            const Duration(seconds: 2), () {
                                          _speak('vi-VN', vietnam);
                                        });
                                      },
                                      icon: Icon(Icons.speaker),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ]),
              ),
            ),
    );
  }

  void _editWord(BuildContext context, String wordId, String topicId,
      String english, String vietnamese) {
    TextEditingController englishController =
        TextEditingController(text: english);
    TextEditingController vietnameseController =
        TextEditingController(text: vietnamese);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit Word'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: englishController,
                decoration: InputDecoration(labelText: 'English'),
              ),
              TextField(
                controller: vietnameseController,
                decoration: InputDecoration(labelText: 'Vietnamese'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Đóng dialog khi nhấn nút Cancel
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                String english = englishController.text;
                String vietnamese = vietnameseController.text;

                // Thực hiện logic để cập nhật từ vựng
                try {
                  await _wordService.updateWord(
                      wordId, english, vietnamese, topicId);
                  // Nếu thành công, hiển thị thông báo và đóng dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Word updated successfully')));
                  Navigator.pop(context); // Đóng dialog
                  setState(() {});
                  _fetchWords();
                } catch (error) {
                  // Nếu có lỗi, hiển thị thông báo lỗi
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error updating word: $error')));
                }
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _deleteWord(String wordId) {
    try {
      // Gọi hàm xóa từ từ WordService
      _wordService.deleteWord(wordId);
      // Cập nhật lại trang bằng cách gọi setState
      setState(() {});
      _fetchWords();
    } catch (error) {
      print('Error deleting word: $error');
    }
  }

  void _addNewWord() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddWordPage(topicId: widget.topicId),
      ),
    ).then((value) {
      // Đoạn code dưới sẽ được thực hiện khi trang AddWordPage được đóng và quay lại trang trước đó
      setState(() {
        // Cập nhật lại dữ liệu
        _fetchWords();
      });
    });
  }
}
