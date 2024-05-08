import 'dart:io' as io;
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flashcard/Services/RecordService.dart';
import 'package:flashcard/pages/change_pass.dart';
import 'package:flashcard/pages/login.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:universal_html/html.dart' as html;
import 'package:flashcard/Models/User.dart';
import 'package:flashcard/Services/UserServices.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;

  const UserProfileScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  late Future<User?> _userFuture;
  dynamic _imageFile;
  bool _isLoading = false;
  List<DocumentSnapshot> _userAchievements = [];

  @override
  void initState() {
    super.initState();
    _userFuture = UserService().getUserById(widget.userId);
    _getUserAchievements();
  }
    // Hàm để lấy danh sách bản ghi
  Future<void> _getUserAchievements() async {
    try {
      List<DocumentSnapshot> records = await RecordService().getRecordsByUserIdAndPercentageCorrect(widget.userId);
      setState(() {
        _userAchievements = records;
      });
    } catch (error) {
      print("Error getting user achievements: $error");
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User Profile'),
      ),
      body: FutureBuilder<User?>(
        future: _userFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            User? user = snapshot.data;
            if (user == null) {
              return Center(child: Text('User not found'));
            }
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (_isLoading)
                          CircularProgressIndicator(),
                        CircleAvatar(
                          radius: 50,
                          backgroundImage: _getImageProvider(user),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  Text('Name: ${user.name}'),
                  SizedBox(height: 10),
                  Text('Email: ${user.email}'),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      _pickImage();
                    },
                    child: Text('Choose Avatar'),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      _updateAvatar(user.id);
                    },
                    child: Text('Update Avatar'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                     logoutAndNavigateToLogin(context);
                    },
                    child: Text('Dang Xuat'),
                  ),

                  ElevatedButton(
                    onPressed: () {
                         Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => ChangePasswordPage()),
                        );
                    },
                    child: Text('Doi mat khau'),
                  ),
                  SizedBox(height: 20),
                  _getUserAchievementsWidget(),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  ImageProvider _getImageProvider(User user) {
    if (_imageFile != null) {
      if (_imageFile is io.File) {
        return FileImage(_imageFile);
      } else if (_imageFile is PlatformFile) {
        return MemoryImage(_imageFile.bytes!);
      }
    } else if (user.avatarUrl != null) {
      return NetworkImage(user.avatarUrl!);
    }
    return AssetImage('assets/default_avatar.png'); // Đường dẫn ảnh mặc định của bạn
  }

  Future<void> _pickImage() async {
    try {
      if (kIsWeb) {
        final result = await FilePicker.platform.pickFiles(type: FileType.image);
        if (result != null) {
          setState(() {
            _imageFile = result.files.first;
          });
        }
      } else {
        final picker = ImagePicker();
        final pickedFile = await picker.pickImage(source: ImageSource.gallery);
        if (pickedFile != null) {
          setState(() {
            _imageFile = io.File(pickedFile.path);
          });
        }
      }
    } catch (e) {
      print("Error picking image: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to pick image: $e')));
    }
  }

void logoutAndNavigateToLogin(BuildContext context) async {
  if (kIsWeb) {
    // Chạy trên web, xóa thông tin đăng nhập từ localStorage
    html.window.localStorage.remove('id');
    html.window.localStorage.remove('email');
  } else {
    // Chạy trên mobile, xóa thông tin đăng nhập từ SharedPreferences
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove('id');
    prefs.remove('email');
  }
  
  // Thực hiện đổi hướng đến trang Login và xóa hết các trang trong ngăn xếp
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(builder: (BuildContext context) => LogIn()), // Chuyển hướng đến trang Login
    (route) => false, // Xóa hết các trang trước đó khỏi ngăn xếp
  );
}




Future<void> _updateAvatar(String userId) async {
  try {
    if (_imageFile != null) {
      // Hiển thị tiến trình
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Updating Avatar'),
            content: CircularProgressIndicator(),
          );
        },
      );

      if (_imageFile is io.File) {
        final file = _imageFile as io.File;
        final bytes = await file.readAsBytes();
        await UserService().updateUserAvatar(userId, bytes);
      } else if (_imageFile is PlatformFile) {
        if (kIsWeb) {
          final bytes = (_imageFile as PlatformFile).bytes;
          if (bytes != null) {
            await UserService().updateUserAvatar(userId, bytes);
          }
        } else {
          await UserService().updateUserAvatar(userId, (_imageFile as PlatformFile).bytes!);
        }
      }

      // Đóng tiến trình
      Navigator.of(context).pop();
      // Cập nhật lại giao diện
      setState(() {
        _userFuture = UserService().getUserById(userId);
        _imageFile = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Avatar updated successfully')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please choose an image first')));
    }
  } catch (error) {
    // Đóng tiến trình nếu có lỗi xảy ra
    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update avatar: $error')));
  }
}
// Widget để hiển thị danh sách bản ghi
Widget _getUserAchievementsWidget() {
  if (_userAchievements.isNotEmpty) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 20),
        Text(
          'Achievements',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 10),
        // Hiển thị danh sách các bản ghi
        ListView.builder(
          shrinkWrap: true,
          itemCount: _userAchievements.length,
          itemBuilder: (context, index) {
            // Lấy ra các trường từ mỗi bản ghi
            final topicId = _userAchievements[index]['topicId'];
            final typeTest = _userAchievements[index]['typeTest'];
            final percentageCorrect = _userAchievements[index]['percentageCorrect'];
            final elapsedTime = _userAchievements[index]['elapsedTime'];
            final topicName = _userAchievements[index]['topicName'];

            // Hiển thị thông tin của mỗi bản ghi dưới dạng ListTile
            return ListTile(
              title: Text('Topic Name: $topicName'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Id: $topicId'),
                  Text('Type Test: $typeTest'),
                  Text('Percentage Correct: $percentageCorrect'),
                  Text('Elapsed Time: $elapsedTime'),
                ],
              ),
            );
          },
        ),
      ],
    );
  } else {
    // Nếu không có bản ghi nào được tìm thấy
    return SizedBox.shrink();
  }
}

}
