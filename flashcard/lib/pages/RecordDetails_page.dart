import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flashcard/Models/User.dart';
import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

class RecordDetailPage extends StatelessWidget {
  final DocumentSnapshot record;
  final User? user;

  const RecordDetailPage({Key? key, required this.record, required this.user})
      : super(key: key);

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
                    : const AssetImage('assets/default_avatar.png')
                        as ImageProvider<Object>,
              ),
              title: Text(user!.name),
            ),
            const SizedBox(height: 16),
            Text('Loại bài test: ${record['typeTest']}'),
            Text('Hoàn thành trong: ${record['elapsedTime']}'),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  CircularPercentIndicator(
                    animation: true,
                    radius: 70.0,
                    lineWidth: 20.0,
                    percent: record['percentageCorrect'] / 100,
                    center: Text(
                      '${record['percentageCorrect'].toStringAsFixed(0)}%',
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    progressColor: Colors.green,
                    backgroundColor: Colors.orange,
                  ),
                  Column(
                    children: [
                      Text(
                        'Số câu đúng: ${record['correctCount']}',
                        style: const TextStyle(color: Colors.green),
                      ),
                      const SizedBox(height: 16), // Khoảng cách giữa các dòng
                      Text(
                        'Số câu sai: ${record['wrongCount']}',
                        style: const TextStyle(color: Colors.orange),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
