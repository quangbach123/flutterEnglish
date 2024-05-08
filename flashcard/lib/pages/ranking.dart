import 'package:flashcard/Models/User.dart';
import 'package:flashcard/Services/RecordService.dart';
import 'package:flashcard/Services/UserServices.dart';
import 'package:flashcard/pages/RecordDetails_page.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class RecordListPage extends StatefulWidget {
  final String topicId;

  RecordListPage({required this.topicId});

  @override
  _RecordListPageState createState() => _RecordListPageState();
}

class _RecordListPageState extends State<RecordListPage> {
  final RecordService _recordService = RecordService();
  late Future<List<DocumentSnapshot>> _FillVocabRecordFuture;
  late Future<List<DocumentSnapshot>> _multipleRecordFuture;
  late Future<List<DocumentSnapshot>> _flashCardRecordFuture;
  int _currentScreen = 0; // 0: FillVocab, 1: Multiple, 2: FlashCard
  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
    _FillVocabRecordFuture = _recordService.getRecordsByTypeTestAndTopicId('FillVocab', widget.topicId);
    _multipleRecordFuture = _recordService.getRecordsByTypeTestAndTopicId('Multiple', widget.topicId);
    _flashCardRecordFuture=_recordService.getRecordsByFlashCardTypeTestAndTopicId(widget.topicId);
    
  }

  Widget buildRecordList(List<DocumentSnapshot>? records) {
    if (records == null || records.isEmpty) {
      return Center(child: Text('No records found.'));
    }
    return ListView.builder(
      itemCount: records.length,
      itemBuilder: (context, index) {
        var record = records[index];
        return FutureBuilder<User?>(
          future: _userService.getUserById(record['userId']),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return ListTile(
                title: Text('Loading...'),
              );
            } else if (userSnapshot.hasError) {
              return ListTile(
                title: Text('Error: ${userSnapshot.error}'),
              );
            } else {
              User? user = userSnapshot.data;
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RecordDetailPage(record: record, user: user),
                    ),
                  );
                },
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: user != null && user.avatarUrl != null
                        ? NetworkImage(user.avatarUrl!)
                        : AssetImage('assets/default_avatar.png') as ImageProvider<Object>,
                  ),
                  title: Text(user?.name ?? 'Unknown User'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('topicId: ${record['topicId']}'),
                      Text('Percentage Correct: ${record['percentageCorrect']}'),
                      Text('Elapsed Time: ${record['elapsedTime']}'),
                      Text('Times: ${record['times']}'),
                    ],
                  ),
                ),
              );
            }
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Record List'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _currentScreen == 0
                ? FutureBuilder<List<DocumentSnapshot>>(
              future: _FillVocabRecordFuture,
              builder: (context, FillVocabSnapshot) {
                if (FillVocabSnapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (FillVocabSnapshot.hasError) {
                  return Center(child: Text('Error: ${FillVocabSnapshot.error}'));
                } else {
                  return buildRecordList(FillVocabSnapshot.data);
                }
              },
            )
                : _currentScreen == 1
                ? FutureBuilder<List<DocumentSnapshot>>(
              future: _multipleRecordFuture,
              builder: (context, multipleSnapshot) {
                if (multipleSnapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (multipleSnapshot.hasError) {
                  return Center(child: Text('Error: ${multipleSnapshot.error}'));
                } else {
                  return buildRecordList(multipleSnapshot.data);
                }
              },
            )
                : FutureBuilder<List<DocumentSnapshot>>(
              future: _flashCardRecordFuture,
              builder: (context, flashCardSnapshot) {
                if (flashCardSnapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (flashCardSnapshot.hasError) {
                  return Center(child: Text('Error: ${flashCardSnapshot.error}'));
                } else {
                  return buildRecordList(flashCardSnapshot.data);
                }
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _currentScreen = 0;
                  });
                },
                child: Text('FillVocab'),
              ),
              SizedBox(width: 10),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _currentScreen = 1;
                  });
                },
                child: Text('Multiple'),
              ),
              SizedBox(width: 10),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _currentScreen = 2;
                  });
                },
                child: Text('FlashCard'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

