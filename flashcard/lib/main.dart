// import 'package:flashcard/Configs/themes.dart';
// import 'package:flashcard/firebase_options.dart';
// import 'package:flashcard/pages/Topic_home_page.dart';
// import 'package:flashcard/pages/login.dart';
// import 'package:flutter/material.dart';
// import 'package:firebase_core/firebase_core.dart';

// import 'package:permission_handler/permission_handler.dart';

// // Thay your_package_name bằng tên package của bạn

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await Firebase.initializeApp(
//   options: DefaultFirebaseOptions.currentPlatform,
// );
//   await Permission.microphone.request(); // Yêu cầu quyền truy cập microphone
//   runApp(MyApp());
  
// }


// class MyApp extends StatelessWidget {
  
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Your App Title',
//       theme: appTheme,
//       debugShowCheckedModeBanner: false,
//       // home: HomePage(userId: 'O3LHP89cZCZtYKRmGs8aZc1D7th2',)
//       home:LogIn()
//     );
//   }
// }

import 'package:universal_html/html.dart' as html;
import 'package:flashcard/Configs/themes.dart';
import 'package:flashcard/firebase_options.dart';
import 'package:flashcard/pages/Topic_home_page.dart';

import 'package:flashcard/pages/login.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await Permission.microphone.request(); // Yêu cầu quyền truy cập microphone
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Your App Title',
      theme: appTheme,
      debugShowCheckedModeBanner: false,
      home: AuthenticationWrapper(),
    );
  }
}

class AuthenticationWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: checkLoggedIn(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        } else {
          if (snapshot.data == true) {
            // Lấy userId từ local storage hoặc SharedPreferences
            String userId = '';
            if (kIsWeb) {
              userId = html.window.localStorage['id'] ?? '';
            } else {
              return FutureBuilder<String>(
                future: _fetchUserId(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Scaffold(
                      body: Center(
                        child: CircularProgressIndicator(),
                      ),
                    );
                  } else {
                    return snapshot.hasData
                        ? HomePage(userId: snapshot.data!)
                        : Scaffold(
                            body: Center(
                              child: CircularProgressIndicator(),
                            ),
                          ); // Có thể thay thế bằng một widget khác tạm thời
                  }
                },
              );
            }
            return HomePage(userId: userId);
          } else {
            return LogIn(); // Chuyển hướng đến trang đăng nhập nếu chưa đăng nhập
          }
        }
      },
    );
  }

  Future<String> _fetchUserId() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('id') ?? '';
  }
}

Future<bool> checkLoggedIn() async {
  // Kiểm tra xem người dùng đã đăng nhập hay chưa
  String savedId = '';
  if (kIsWeb) {
    savedId = html.window.localStorage['id'] ?? '';
  } else {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    savedId = prefs.getString('id') ?? '';
  }
  return savedId.isNotEmpty;
}

