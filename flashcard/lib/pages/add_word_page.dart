import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart' as mobile;
import 'package:file_selector/file_selector.dart' as web;
import 'package:csv/csv.dart';
import 'package:flashcard/Services/WordServices.dart';

class AddWordPage extends StatefulWidget {
  final String topicId;

  AddWordPage({required this.topicId});

  @override
  _AddWordPageState createState() => _AddWordPageState();
}

class _AddWordPageState extends State<AddWordPage> {
  final WordService _wordService = WordService();
  final TextEditingController _englishController = TextEditingController();
  final TextEditingController _vietnameseController = TextEditingController();

  List<String> _englishWords = [];
  List<String> _vietnameseWords = [];

  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Add Word'),
          actions: [
            IconButton(
                onPressed: () {
                  if (kIsWeb) {
                    _pickAndAddWordsFromCSVWeb();
                  } else {
                    _pickAndAddWordsFromCSV();
                  }
                },
                icon: Icon(Icons.document_scanner)),
            IconButton(
              icon: Icon(Icons.check),
              onPressed: _addWordsToTopic,
            ),
          ],
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _englishWords.length,
                        itemBuilder: (context, index) {
                          return Card(
                            child: ListTile(
                              title: TextFormField(
                                decoration:
                                    InputDecoration(labelText: 'Tiếng Anh'),
                                initialValue: _englishWords[index],
                                onChanged: (value) {
                                  setState(() {
                                    _englishWords[index] = value;
                                  });
                                },
                              ),
                              subtitle: TextFormField(
                                decoration:
                                    InputDecoration(labelText: 'Tiếng Việt'),
                                initialValue: _vietnameseWords[index],
                                onChanged: (value) {
                                  setState(() {
                                    _vietnameseWords[index] = value;
                                  });
                                },
                              ),
                              trailing: IconButton(
                                icon: Icon(Icons.delete),
                                onPressed: () {
                                  setState(() {
                                    _englishWords.removeAt(index);
                                    _vietnameseWords.removeAt(index);
                                  });
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
        floatingActionButton: FloatingActionButton(
          onPressed: _addWordToList,
          child: Icon(Icons.add),
        ));
  }

  void _addWordToList() {
    String englishWord = '';
    String vietnameseWord = '';
    setState(() {
      _englishWords.add(englishWord);
      _vietnameseWords.add(vietnameseWord);
    });
  }

  Future<void> _pickAndAddWordsFromCSV() async {
    try {
      final mobile.FilePickerResult? result =
          await mobile.FilePicker.platform.pickFiles(
        type: mobile.FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result != null) {
        io.File file = io.File(result.files.single.path!);
        List<List<dynamic>> csvData = await _readCSVFile(file);

        for (var row in csvData) {
          setState(() {
            _englishWords.add(row[0].toString());
            _vietnameseWords.add(row[1].toString());
          });
        }
      } else {
        // Người dùng hủy chọn tệp
        print('User canceled file picker');
      }
    } catch (error) {
      print('Error picking file: $error');
    }
  }

  Future<void> _pickAndAddWordsFromCSVWeb() async {
    try {
      final web.XFile? file = await web.openFile(acceptedTypeGroups: [
        web.XTypeGroup(label: 'CSV', extensions: ['csv']),
      ]);

      if (file != null) {
        String csvString = await file.readAsString();
        List<List<dynamic>> csvData = CsvToListConverter().convert(csvString);

        for (var row in csvData) {
          setState(() {
            _englishWords.add(row[0].toString());
            _vietnameseWords.add(row[1].toString());
          });
        }
      } else {
        // Người dùng hủy chọn tệp
        print('User canceled file picker');
      }
    } catch (error) {
      print('Error picking file: $error');
    }
  }

  Future<List<List<dynamic>>> _readCSVFile(io.File file) async {
    String csvString = await file.readAsString();
    return CsvToListConverter().convert(csvString);
  }

  Future<void> _addWordsToTopic() async {
    setState(() {
      isLoading = true;
    });
    if (_englishWords.isNotEmpty && _vietnameseWords.isNotEmpty) {
      try {
        for (int i = 0; i < _englishWords.length; i++) {
          await _wordService.addWord(
              _englishWords[i], _vietnameseWords[i], widget.topicId);
        }
        setState(() {
          isLoading = false;
        });
        Navigator.pop(context); // Trở về màn hình trước sau khi thêm từ
      } catch (error) {
        print('Error adding words: $error');
      }
    } else {
      // Hiển thị thông báo lỗi nếu không có từ nào để thêm
      setState(() {
        isLoading = false;
      });
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Error'),
            content: Text('No words to add.'),
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

  @override
  void dispose() {
    _englishController.dispose();
    _vietnameseController.dispose();
    super.dispose();
  }
}
