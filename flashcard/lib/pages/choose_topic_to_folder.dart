import 'package:flashcard/Models/Topic.dart';
import 'package:flashcard/Services/FolderService.dart';
import 'package:flashcard/Services/TopicServices.dart';
import 'package:flashcard/pages/Folder_details_page.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChooseTopicPage extends StatefulWidget {
  final String folderId;
  final String userId;

  ChooseTopicPage({required this.folderId, required this.userId});

  @override
  _ChooseTopicPageState createState() => _ChooseTopicPageState();
}

class _ChooseTopicPageState extends State<ChooseTopicPage> {
  final TopicService _topicService = TopicService();
  late List<Topic> publicTopics;
  FolderService _folderService = FolderService();
  late TextEditingController _searchController;

@override
void initState() {
  super.initState();
  publicTopics = []; // Khởi tạo publicTopics với danh sách trống
  _loadData();
  _searchController = TextEditingController();
}


  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

Future<void> _loadData() async {
  try {
    DocumentReference folderRef = FirebaseFirestore.instance.collection('Folder').doc(widget.folderId);
    List<Topic> fetchedPublicTopics = await _folderService.getPublicTopicsNotInFolder(folderRef);
    setState(() {
      publicTopics = fetchedPublicTopics;
    });
  } catch (error) {
    print("Error loading data: $error");
    // Xử lý lỗi ở đây nếu cần
  }
}

  // Hàm để lọc danh sách chủ đề dựa trên từ khóa tìm kiếm
  List<Topic> _filterTopics(String query) {
    return publicTopics.where((topic) => topic.topicName.toLowerCase().contains(query.toLowerCase())).toList();
  }

  Future<List<DocumentSnapshot>> _getTopicsNotInFolder() async {
    try {
      DocumentSnapshot folderSnapshot =
          await FirebaseFirestore.instance.collection('Folder').doc(widget.folderId).get();
      String folderUserId = folderSnapshot['userId'];

      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('Topics')
          .where('userId', isEqualTo: folderUserId)
          .get();

      List<DocumentReference> topicReferences =
          List<DocumentReference>.from(folderSnapshot['Topics']);

      List<DocumentSnapshot> topicsNotInFolder = [];
      for (QueryDocumentSnapshot topicSnapshot in querySnapshot.docs) {
        if (!topicReferences.any((topicRef) => topicRef.id == topicSnapshot.id)) {
          topicsNotInFolder.add(topicSnapshot);
        }
      }

      return topicsNotInFolder;
    } catch (error) {
      print('Error getting topics not in folder: $error');
      throw error;
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Choose Topic'),
          bottom: TabBar(
            tabs: [
              Tab(text: 'Topics Not in Folder'),
              Tab(text: 'Public Topics'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Tab "Topics Not in Folder"
            FutureBuilder(
              future: _getTopicsNotInFolder(),
              builder: (context, AsyncSnapshot<List<DocumentSnapshot>> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError || !snapshot.hasData) {
                  return Center(child: Text('Error loading topics'));
                }
                List<DocumentSnapshot> topics = snapshot.data!;
                return ListView.builder(
                  itemCount: topics.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(topics[index]['topicName']),
                      onTap: () async {
                        await _folderService.addTopicToFolder(
                          widget.folderId, 
                          topics[index].reference,
                        );
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => FolderDetailPage(folderId: widget.folderId, userId: widget.userId,)),
                        ); 
                      },
                    );
                  },
                );
              },
            ),
            // Tab "Public Topics" với thanh tìm kiếm
Column(
  children: [
    Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          labelText: 'Search topics',
          border: OutlineInputBorder(),
        ),
        onChanged: (value) {
          setState(() {}); // Gọi setState để cập nhật giao diện khi nhập liệu tìm kiếm thay đổi
        },
      ),
    ),
    Expanded(
      child: ListView.builder(
        itemCount: _filterTopics(_searchController.text).length,
        itemBuilder: (context, index) {
          Topic topic = _filterTopics(_searchController.text)[index];
          return ListTile(
            title: Text(topic.topicName),
            onTap: () async {
              if (topic.documentId != null) {
                  DocumentSnapshot<Object?> topicSnapshot = await FirebaseFirestore.instance.collection('Topics').doc(topic.documentId).get();
                  DocumentReference<Object?> topicRef = topicSnapshot.reference;
                  await _folderService.addTopicToFolder(widget.folderId, topicRef);

                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => FolderDetailPage(folderId: widget.folderId, userId: widget.userId,)),
                );
              } else {
                // Xử lý khi documentId là null (nếu cần)
              }
            },

          );
        },
      ),
    ),
  ],
),
          ],
        ),
      ),
    );
  }
}
