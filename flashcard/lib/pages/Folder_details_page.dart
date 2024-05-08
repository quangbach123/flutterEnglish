  import 'package:flashcard/pages/choose_topic_to_folder.dart';
import 'package:flashcard/pages/word_page.dart';
  import 'package:flutter/foundation.dart';
  import 'package:flutter/material.dart';
  import 'package:cloud_firestore/cloud_firestore.dart';
  import 'package:flashcard/Services/FolderService.dart';

  class FolderDetailPage extends StatefulWidget {
    final String folderId;
    final String userId;

    FolderDetailPage({required this.folderId, required this.userId});

    @override
    _FolderDetailPageState createState() => _FolderDetailPageState();
  }

  class _FolderDetailPageState extends State<FolderDetailPage> {
    final FolderService _folderService = FolderService();
    late Future<DocumentSnapshot> _folderFuture;
    late Future<List<DocumentSnapshot>> _topicsFuture;
    @override
    void initState() {
      super.initState();
      _folderFuture = _getFolder(widget.folderId);
      _topicsFuture = _getTopicsInFolder(widget.folderId);
    }

    Future<DocumentSnapshot> _getFolder(String folderId) async {
      try {
        return await FirebaseFirestore.instance.collection('Folder').doc(folderId).get();
      } catch (error) {
        throw error;
      }
    }
    
    Future<List<DocumentSnapshot>> _getTopicsInFolder(String folderId) async {
      try {
        DocumentSnapshot folderSnapshot = await FirebaseFirestore.instance.collection('Folder').doc(folderId).get();
        List<DocumentReference> topicReferences = List<DocumentReference>.from(folderSnapshot['Topics']);
        List<Future<DocumentSnapshot>> topicFutures = topicReferences.map((topicRef) => topicRef.get()).toList();
        return await Future.wait(topicFutures);
      } catch (error) {
        throw error;
      }
    }

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Folder Detail'),
        ),
        body: FutureBuilder(
          future: _folderFuture,
          builder: (context, AsyncSnapshot<DocumentSnapshot> folderSnapshot) {
            if (folderSnapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            if (folderSnapshot.hasError || !folderSnapshot.hasData) {
              return Center(child: Text('Error loading folder data'));
            }
            // Extract folder data
            String folderName = folderSnapshot.data!.get('Name');
            // Build UI for folder detail
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Folder Name: $folderName',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Divider(),
ElevatedButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChooseTopicPage(folderId: widget.folderId, userId: widget.userId,),
      ),
    );
  },
  child: Text('Add Topic to Folder'),
),

                Expanded(
                  child: FutureBuilder(
                    future: _topicsFuture,
                    builder: (context, AsyncSnapshot<List<DocumentSnapshot>> topicsSnapshot) {
                      if (topicsSnapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }
                      if (topicsSnapshot.hasError || !topicsSnapshot.hasData) {
                        return Center(child: Text('Error loading topics'));
                      }
                      // Build UI for list of topics
                      List<String> topicNames = topicsSnapshot.data!.map((topicSnapshot) => topicSnapshot.get('topicName') as String).toList();
                      
                      if (topicsSnapshot.data != null) {
                        topicsSnapshot.data!.forEach((topicSnapshot) {
                          Map<String, dynamic>? data = topicSnapshot.data() as Map<String, dynamic>?;
                          if (data != null) {
                            print("Fields in DocumentSnapshot:");
                            data.forEach((key, value) {
                              print('$key: $value');
                            });
                          }
                        });
                      }
                      return ListView.builder(
                        itemCount: topicNames.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            title: Text(topicNames[index]),
                            trailing: IconButton(
                              icon: Icon(Icons.delete),
                              onPressed: () async {
                                DocumentReference topicRef = FirebaseFirestore.instance.collection('Topics').doc(topicsSnapshot.data![index].id);
                                await _removeTopicFromFolder(topicRef); // Gọi hàm removeTopicFromFolder với tham chiếu tài liệu
                                _reloadData(); // Load lại dữ liệu sau khi xóa
                              },  
                            ),
                            onTap: () {
                              // Xử lý khi nhấp vào item
                              String topicId = topicsSnapshot.data![index].id;
                              // Chuyển đến trang WordListPage và truyền topicId vào đó
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => WordListPage(topicId: topicId, userId: widget.userId,),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      );
    }

    void _showTopicsNotInFolderDialog() {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
            title: Text('Add Topic to Folder'),
            content: SizedBox(
              height: 300, // Adjust the height as needed
              child: FutureBuilder(
                future: _getTopicsNotInFolder(),
                builder: (context, AsyncSnapshot<List<DocumentSnapshot>> snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  }
                  if (snapshot.hasError || !snapshot.hasData) {
                    return Text('Error loading topics');
                  }
                  List<DocumentSnapshot> topics = snapshot.data!;
                  return SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: topics.map((topic) {
                        return ListTile(
                          title: Text(topic.get('topicName')),
                                  onTap: () async {
                                  await _folderService.addTopicToFolder(widget.folderId, topic.reference);
                                  Navigator.of(context).pop(); // Close the dialog
                                  _reloadData(); // Reload data after adding topic
                                },

                        );
                      }).toList(),
                    ),
                  );
                },
              ),
            ),
          );
        },
      );
    }
    // Hàm removeTopicFromFolder:
  // Hàm removeTopicFromFolder:
  Future<void> _removeTopicFromFolder(DocumentReference topicRef) async {
    try {
      await _folderService.removeTopicFromFolder(widget.folderId, topicRef);
    } catch (error) {
      print('Error removing topic from folder: $error');
      // Xử lý lỗi nếu có
    }
  }

  Future<List<DocumentSnapshot>> _getTopicsNotInFolder() async {
    try {
      // Lấy userId của folder
      DocumentSnapshot folderSnapshot = await FirebaseFirestore.instance.collection('Folder').doc(widget.folderId).get();
      String folderUserId = folderSnapshot['userId'];

      // Lấy danh sách tất cả các chủ đề có userId trùng với userId của folder
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('Topics')
          .where('userId', isEqualTo: folderUserId)
          .get();

      // Lấy danh sách các chủ đề trong thư mục hiện tại
      List<DocumentReference> topicReferences = List<DocumentReference>.from(folderSnapshot['Topics']);

      // Lọc ra các chủ đề chưa có trong thư mục và có userId trùng với userId của folder
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
void _reloadData() {
  setState(() {
    _folderFuture = _getFolder(widget.folderId);
    _topicsFuture = _getTopicsInFolder(widget.folderId);
  });
}
  }
