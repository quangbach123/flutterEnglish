import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flashcard/Services/FolderService.dart';
import 'package:flashcard/Services/UserServices.dart';
import 'package:flashcard/pages/Folder_details_page.dart';
import 'package:flutter/material.dart';
import 'package:flashcard/Models/Topic.dart';
import 'package:flashcard/Models/User.dart';
import 'package:flashcard/Models/Folder.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserFoldersScreen extends StatefulWidget {
  final String userId;

  UserFoldersScreen({required this.userId});

  @override
  _UserFoldersScreenState createState() => _UserFoldersScreenState();
}

class _UserFoldersScreenState extends State<UserFoldersScreen> {
  final UserService _userService = UserService();
  final FolderService _folderService = FolderService();

  List<Folder> _folders = [];
  late User _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    isLoggedIn();
  }

// hàm kiểm tra xem đã đăng nhập chưa
  Future<bool> isLoggedIn() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? email = prefs.getString('email');
    String? password = prefs.getString('password');

    // Kiểm tra xem email và password có tồn tại hay không để xác định trạng thái đăng nhập
    if (email != null && password != null) {
      return true; // Đã đăng nhập
    } else {
      return false; // Chưa đăng nhập
    }
  }

  void deleteFolder1(String userId, String folderId) async {
    try {
      // Xóa folder khỏi danh sách của user trong Firestore
      await _userService.deleteFolder(userId, folderId);

      // Xóa folder khỏi danh sách _folders của widget
      setState(() {
        _folders.removeWhere((folder) => folder.documentId == folderId);
      });
    } catch (error) {
      print("Error deleting folder: $error");
    }
  }

  Future<void> updateFolderName(String folderId, String newName) async {
    try {
      // Tạo một tham chiếu đến folder trong Firestore
      DocumentReference folderRef =
          FirebaseFirestore.instance.collection('Folder').doc(folderId);

      // Cập nhật trường 'Name' của folder trong Firestore
      await folderRef.update({'Name': newName});

      // Cập nhật trên giao diện người dùng
      setState(() {
        // Tìm folder cần cập nhật trong danh sách _folders
        int index =
            _folders.indexWhere((folder) => folder.documentId == folderId);
        if (index != -1) {
          _folders[index] = Folder(
            documentId: _folders[index].documentId,
            name: newName,
            Topics: _folders[index].Topics,
            userId: _folders[index].userId,
          );
        }
      });
    } catch (error) {
      // Xử lý lỗi nếu có
      print("Error updating folder name: $error");
    }
  }

  Future<void> showEditFolderDialog(Folder folder) async {
    TextEditingController folderNameController =
        TextEditingController(text: folder.name);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit Folder Name'),
          content: TextField(
            controller: folderNameController,
            decoration: InputDecoration(hintText: 'Enter new folder name'),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                String newName = folderNameController.text.trim();
                if (newName.isNotEmpty) {
                  updateFolderName(folder.documentId, newName);
                  Navigator.of(context).pop();
                }
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _loadData() async {
    try {
      // Load user data
      User? user = await _userService.getUserById(widget.userId);
      if (user != null) {
        if (!mounted) return;
        setState(() {
          _user = user;
        });

        // Load folders data
        List<Folder> folders =
            await _userService.getAllFoldersByUserId(widget.userId);
        if (!mounted) return;
        setState(() {
          _folders = folders;
          _isLoading = false; // Dữ liệu đã được tải xong
        });
      } else {
        // Handle user not found
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      print("Error loading data: $error");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading ? _buildLoadingIndicator() : _buildUserInfo(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddFolderScreen(userId: widget.userId),
            ),
          ).then((value) {
            if (value == true) {
              _loadData();
            }
          });
        },
        child: Icon(Icons.add),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildUserInfo() {
    if (_user == null) {
      return Center(
        child: Text('User data is not loaded yet.'),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            'Name: ${_user.name}',
            style: TextStyle(fontSize: 18),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            'Email: ${_user.email}',
            style: TextStyle(fontSize: 18),
          ),
        ),
        Expanded(
          child: _folders.isEmpty
              ? Center(child: Text('No folders found'))
              : ListView.builder(
                  itemCount: _folders.length,
                  itemBuilder: (BuildContext context, int index) {
                    return Card.outlined(
                      child: ListTile(
                        leading: Icon(Icons.folder),
                        title: Text(_folders[index].name),
                        onTap: () {
                          // Chuyển sang FolderDetailPage và truyền folderId
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FolderDetailPage(
                                folderId: _folders[index].documentId,
                                userId: widget.userId,
                              ),
                            ),
                          );
                        },
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit),
                              onPressed: () {
                                showEditFolderDialog(_folders[index]);
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.delete),
                              onPressed: () {
                                deleteFolder1(
                                    _user.id, _folders[index].documentId);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class AddFolderScreen extends StatefulWidget {
  final String userId;

  AddFolderScreen({required this.userId});

  @override
  _AddFolderScreenState createState() => _AddFolderScreenState();
}

class _AddFolderScreenState extends State<AddFolderScreen> {
  final TextEditingController _folderNameController = TextEditingController();

  final UserService _userService = UserService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Folder'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _folderNameController,
              decoration: InputDecoration(
                labelText: 'Folder Name',
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _addFolder();
              },
              child: Text('Add Folder'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addFolder() async {
    String folderName = _folderNameController.text.trim();
    if (folderName.isNotEmpty) {
      await _userService.addFolderToUser(widget.userId, folderName);
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Please enter folder name'),
        duration: Duration(seconds: 2),
      ));
    }
  }

  @override
  void dispose() {
    _folderNameController.dispose();
    super.dispose();
  }
}
