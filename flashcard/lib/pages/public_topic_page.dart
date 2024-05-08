import 'package:flashcard/Services/TopicServices.dart';
import 'package:flashcard/pages/word_page.dart';
import 'package:flutter/material.dart';
import 'package:flashcard/Models/Topic.dart';

class PublicTopicsPage extends StatefulWidget {
  final String userId;

  const PublicTopicsPage({Key? key, required this.userId}) : super(key: key); 
  @override
  _PublicTopicsPageState createState() => _PublicTopicsPageState();
}

class _PublicTopicsPageState extends State{
  TextEditingController _searchController = TextEditingController();
  List<Topic> _publicTopics = [];
  List<Topic> _filteredTopics = [];
  TopicService _topicService = TopicService();

  @override
  void initState() {
    super.initState();
    _getPublicTopics();
  }

  Future<void> _getPublicTopics() async {
    try {
      List<Topic> publicTopics = await _topicService.getAllPublicTopics();
      setState(() {
        _publicTopics = publicTopics;
        _filteredTopics = publicTopics;
      });
    } catch (error) {
      print('Error fetching public topics: $error');
    }
  }

  void _filterTopics(String keyword) {
    setState(() {
      _filteredTopics = _publicTopics
          .where((topic) =>
              topic.topicName.toLowerCase().contains(keyword.toLowerCase()))
          .toList();
    });
  }

  void _navigateToWordListPage(Topic topic,String userId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WordListPage(topicId: topic.documentId,userId: userId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Public Topics'),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search topics',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: _filterTopics,
            ),
          ),
Expanded(
  child: ListView.builder(
    itemCount: _filteredTopics.length,
    itemBuilder: (context, index) {
      Topic topic = _filteredTopics[index];
      final String? userAvatarUrl = topic.userAvatarUrl;
      final String? userName = topic.userName; // Lấy userName từ topic

      return ListTile(
        leading: CircleAvatar(
          backgroundImage: userAvatarUrl != null
              ? NetworkImage(userAvatarUrl)
              : NetworkImage(
                  'https://png.pngtree.com/png-vector/20210921/ourlarge/pngtree-flat-people-profile-icon-png-png-image_3947764.png',
                ),
        ),
        title: Text(topic.topicName),
        subtitle: Text('ID: ${topic.documentId}'),
        trailing: userName != null ? Text(userName) : Text('No username'), // Kiểm tra userName trước khi sử dụng
        onTap: () => _navigateToWordListPage(topic, (widget as PublicTopicsPage).userId),
      );
    },
  ),
),
        ],
      ),
    );
  }
}
