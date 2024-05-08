import 'package:flashcard/Models/User.dart';
import 'package:flashcard/Services/UserServices.dart';
import 'package:flashcard/pages/word_page.dart';
import 'package:flutter/material.dart';
import 'package:flashcard/Models/Topic.dart';
import 'package:flashcard/Services/TopicServices.dart';

class UserTopicScreen extends StatefulWidget {
  final String userId;

  UserTopicScreen({required this.userId});

  @override
  _UserTopicScreenState createState() => _UserTopicScreenState();
}

class _UserTopicScreenState extends State<UserTopicScreen> {
  final TopicService _topicService = TopicService();
  late List<Topic> _topics;
  

  @override
  void initState() {
    super.initState();
      _topics = [];   
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      List<Topic> topics = await _topicService.getTopicsByUserId(widget.userId);
      setState(() {
        _topics = topics;
        
      });
    } catch (error) {
      print("Error loading topics: $error");
    }
  }

  Future<void> _addTopic() async {
    String topicName = '';
    String topicImageUrl = '';

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Thêm chủ đề mới'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                onChanged: (value) {
                  topicName = value;
                },
                decoration: InputDecoration(labelText: 'Tên chủ đề'),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Hủy'),
            ),
            TextButton(
              onPressed: () async {
                UserService userService = UserService();
                // Lấy thông tin về người dùng từ userId
                User? user = await userService.getUserById(widget.userId);
                // Kiểm tra xem có user không trước khi thêm chủ đề mới
                if (user != null) {
                  Topic newTopic = Topic(
                    documentId: '', // Bạn có thể sử dụng UUID hoặc một phương thức tạo ID khác để tạo một ID ngẫu nhiên cho chủ đề mới
                    topicImageUrl: topicImageUrl,
                    topicName: topicName,
                    userId: widget.userId,
                    userAvatarUrl: user.avatarUrl, // Lấy avatarUrl từ user
                    userName: user.name, 
                    isPublic: false, 
                    view: '0', 
                  );
                  // Thêm chủ đề mới với tham chiếu đến người dùng
                  await _topicService.addTopicWithUserReference(newTopic, widget.userId);
                  await _loadData();
                  Navigator.of(context).pop();
                } else {
                  // Xử lý trường hợp không tìm thấy người dùng
                  print("User not found!");
                }
              },
              child: Text('Thêm'),
            ),
          ],
        );
      },
    );
  }
  Future<void> _deleteTopic(String topicId) async {
    try {
      await _topicService.deleteTopicWithUserReference(topicId, widget.userId);
      await _loadData();
    } catch (error) {
      print("Error deleting topic: $error");
    }
  }

  Future<void> _updateTopic(String topicId, Map<String, dynamic> data) async {
    try {
      await _topicService.updateTopic(topicId, data);
      await _loadData();
    } catch (error) {
      print("Error updating topic: $error");
    }
  }

  Future<void> _toggleTopicStatus(String topicId, bool currentStatus) async {
    bool newStatus = !currentStatus;
    try {
      await _updateTopic(topicId, {'isPublic': newStatus});
    } catch (error) {
      print("Error toggling topic status: $error");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User Topics'),
      ),
      body:_topics.isEmpty
        ? Center(child: Text('No topics found'))
        : ListView.builder(
        itemCount: _topics.length,
        itemBuilder: (context, index) {
          Topic topic = _topics[index];
          return ListTile(
            title: Text(topic.topicName),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(topic.isPublic ? Icons.public : Icons.lock),
                  onPressed: () => _toggleTopicStatus(topic.documentId, topic.isPublic),
                ),
                IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => _buildEditTopicDialog(topic),
                    );
                  },
                ),
                IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () => _deleteTopic(topic.documentId),
                ),
                
              ],
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => WordListPage(topicId: topic.documentId, userId: widget.userId,),
                ),
              );
            },
          );
        },
      ),
      
      floatingActionButton: FloatingActionButton(
        onPressed: _addTopic,
        child: Icon(Icons.add),
      ),
    );
  }

  Widget _buildEditTopicDialog(Topic topic) {
    String newTopicName = topic.topicName;
    return AlertDialog(
      title: Text('Sửa chủ đề'),
      content: TextField(
        onChanged: (value) {
          newTopicName = value;
        },
        controller: TextEditingController(text: topic.topicName),
        decoration: InputDecoration(labelText: 'Tên chủ đề mới'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Hủy'),
        ),
        TextButton(
          onPressed: () {
            _updateTopic(topic.documentId, {'topicName': newTopicName});
            Navigator.pop(context);
          },
          child: Text('Lưu'),
        ),
      ],
    );
  }
}
