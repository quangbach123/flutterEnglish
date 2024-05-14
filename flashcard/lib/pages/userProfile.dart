import 'dart:io' as io;
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flashcard/Services/RecordService.dart';
import 'package:flashcard/pages/change_pass.dart';
import 'package:flashcard/pages/login.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/widgets.dart';
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

  @override
  void initState() {
    super.initState();
    _userFuture = UserService().getUserById(widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<User?>(
        future: _userFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            User? user = snapshot.data;
            if (user == null) {
              return const Center(child: Text('User not found'));
            }
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (_isLoading) const CircularProgressIndicator(),
                        Image.asset(
                            'assets/images/background_avata.jpg'), // Đường dẫn ảnh mặc định của bạn
                        Stack(children: [
                          CircleAvatar(
                            radius: 80,
                            backgroundImage: _getImageProvider(user),
                          ),
                          Positioned(
                            bottom: -5,
                            right: -5,
                            child: IconButton(
                              onPressed: () {
                                _pickImage();
                                _updateAvatar(user.id);
                              },
                              icon: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 40,
                              ),
                            ),
                          ),
                        ]),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 10),
                        Text('Thông tin cá nhân',
                            style: TextStyle(fontSize: 20)),
                        ListTile(
                          leading: const Icon(
                            Icons.person,
                            color: Colors.deepPurpleAccent,
                          ),
                          title: Text('${user.name}'),
                        ),
                        ListTile(
                          leading: const Icon(
                            Icons.alternate_email,
                            color: Colors.deepPurpleAccent,
                          ),
                          title: Text('${user.email}'),
                        ),
                        const SizedBox(height: 10),
                        ListTile(
                          leading: const Icon(
                            Icons.archive,
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios),
                          title: Text('Thành tựu của bạn'),
                          onTap: () {
                            logoutAndNavigateToLogin(context);
                          },
                        ),
                        SizedBox(height: 10),
                        ListTile(
                          leading: const Icon(
                            Icons.password,
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios),
                          title: Text('Đổi mật khẩu'),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => ChangePasswordPage()),
                            );
                          },
                        ),
                        SizedBox(height: 10),
                        ListTile(
                          iconColor: Colors.red,
                          textColor: Colors.red,
                          leading: const Icon(
                            Icons.logout,
                          ),
                          title: Text('Đăng xuất'),
                          onTap: () {
                            logoutAndNavigateToLogin(context);
                          },
                        ),
                      ],
                    ),
                  ),
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
    } else if (user.avatarUrl != '') {
      return NetworkImage(user.avatarUrl!);
    }
    return const AssetImage(
        'assets/images/default-avatar.jpg'); // Đường dẫn ảnh mặc định của bạn
  }

  Future<void> _pickImage() async {
    try {
      if (kIsWeb) {
        final result =
            await FilePicker.platform.pickFiles(type: FileType.image);
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
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to pick image: $e')));
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
      MaterialPageRoute(
          builder: (BuildContext context) =>
              LogIn()), // Chuyển hướng đến trang Login
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
            await UserService()
                .updateUserAvatar(userId, (_imageFile as PlatformFile).bytes!);
          }
        }

        // Đóng tiến trình
        Navigator.of(context).pop();
        // Cập nhật lại giao diện
        setState(() {
          _userFuture = UserService().getUserById(userId);
          _imageFile = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Avatar updated successfully')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Please choose an image first')));
      }
    } catch (error) {
      // Đóng tiến trình nếu có lỗi xảy ra
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update avatar: $error')));
    }
  }

// Widget để hiển thị danh sách bản ghi
}
