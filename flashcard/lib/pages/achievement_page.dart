import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flashcard/Services/RecordService.dart';
import 'package:flutter/material.dart';

class AchievementPage extends StatefulWidget {
  final String userId;

  AchievementPage({required this.userId});
  @override
  State<AchievementPage> createState() => _AchievementPageState();
}

class _AchievementPageState extends State<AchievementPage> {
  List<DocumentSnapshot> _userAchievements = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _getUserAchievements();
  }

  // Hàm để lấy danh sách bản ghi
  Future<void> _getUserAchievements() async {
    try {
      List<DocumentSnapshot> records = await RecordService()
          .getRecordsByUserIdAndPercentageCorrect(widget.userId);
      setState(() {
        _userAchievements = records;
        _isLoading = false;
      });
    } catch (error) {
      print("Error getting user achievements: $error");
    }
  }

  Widget _getUserAchievementsWidget() {
    if (_userAchievements.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 10),
          // Hiển thị danh sách các bản ghi
          ListView.builder(
            shrinkWrap: true,
            itemCount: _userAchievements.length,
            itemBuilder: (context, index) {
              // Lấy ra các trường từ mỗi bản ghi
              final topicId = _userAchievements[index]['topicId'];
              final typeTest = _userAchievements[index]['typeTest'];
              final percentageCorrect =
                  _userAchievements[index]['percentageCorrect'];
              final elapsedTime = _userAchievements[index]['elapsedTime'];
              final topicName = _userAchievements[index]['topicName'];

              // Hiển thị thông tin của mỗi bản ghi dưới dạng ListTile
              return ListTile(
                leading: CircleAvatar(
                  //child: AspectRatio(
                  //aspectRatio: 1 / 1,
                  child: Image.asset('assets/images/achievement.png'),
                ), //),
                title: Text(
                  'Achievement from $topicName',
                  style: TextStyle(
                    fontSize: 20,
                  ),
                ),
                subtitle: Text('$typeTest complete in $elapsedTime',
                    style: TextStyle(fontSize: 16, color: Colors.grey)),
              );
            },
          ),
        ],
      );
    } else {
      // Nếu không có bản ghi nào được tìm thấy
      return Center(
        child: Text('No achievements found'),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Achievement Page'),
      ),
      body: SafeArea(
        child: _isLoading
            ? Center(
                child: CircularProgressIndicator(),
              )
            : SingleChildScrollView(
                child: _getUserAchievementsWidget(),
              ),
      ),
    );
  }
}
