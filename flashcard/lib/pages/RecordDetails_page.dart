import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flashcard/Models/User.dart';
import 'package:flutter/material.dart';

class RecordDetailPage extends StatelessWidget {
  final DocumentSnapshot record;
  final User? user;

  const RecordDetailPage({Key? key, required this.record, required this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Record Detail'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: CircleAvatar(
                backgroundImage: user?.avatarUrl != null
                    ? NetworkImage(user!.avatarUrl!)
                    : const AssetImage('assets/default_avatar.png') as ImageProvider<Object>,
              ),
              title: Text(user!.name),
              subtitle: Text('UserId: ${record['userId']}'),
            ),
            SizedBox(height: 16),
            Text('topicId: ${record['topicId']}'),
            Text('Percentage Correct: ${record['percentageCorrect']}'),
            Text('Correct Count: ${record['correctCount']}'),
            Text('Wrong Count: ${record['wrongCount']}'),
            Text('Elapsed Time: ${record['elapsedTime']}'),
            Text('typeTest: ${record['typeTest']}'),
          ],
        ),
      ),
    );
  }
}
