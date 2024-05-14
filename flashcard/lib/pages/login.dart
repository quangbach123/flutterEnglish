// ignore_for_file: use_build_context_synchronously
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flashcard/Services/UserServices.dart';
import 'package:flashcard/components/navigation.dart';
import 'package:flashcard/pages/forgot_pass.dart';
import 'package:flashcard/pages/signup.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flashcard/Models/User.dart' as LocalUser;
import 'package:universal_html/html.dart' as html;

class LogIn extends StatefulWidget {
  const LogIn({super.key});

  @override
  State<LogIn> createState() => _LogInState();
}

class _LogInState extends State<LogIn> with WidgetsBindingObserver {
  String email = "", password = "";
  TextEditingController mailcontroller = new TextEditingController();
  TextEditingController passwordcontroller = new TextEditingController();
  final _formkey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();

    // checkLoggedIn();
  }

  // check xem đã đăng nhập chưa
  void checkLoggedIn() async {
    String savedId = '';
    if (kIsWeb) {
      // Chạy trên web
      savedId = html.window.localStorage['id'] ?? '';
    } else {
      // Chạy trên mobile
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      savedId = prefs.getString('id') ?? '';
    }
    print('Saved ID: $savedId');
    if (savedId.isNotEmpty) {
      print('chuyen huong');
      // Đã có thông tin đăng nhập trước đó, chuyển hướng người dùng đến trang chính
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MyNavigation(userId: savedId)),
      );
    }
  }

  Future<void> saveUserInformation(String email, String id) async {
    if (kIsWeb) {
      // Chạy trên web, sử dụng localStorage
      html.window.localStorage['email'] = email;
      html.window.localStorage['id'] = id;
      if (html.window.localStorage['email'] == email &&
          html.window.localStorage['id'] == id) {
        print('User information saved successfully on web!');
      } else {
        print('Failed to save user information on web!');
      }
    } else {
      // Chạy trên mobile, sử dụng SharedPreferences
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('email', email);
      await prefs.setString('id', id);
      if (prefs.getString('email') == email && prefs.getString('id') == id) {
        print('User information saved successfully on mobile!');
      } else {
        print('Failed to save user information on mobile!');
      }
    }
  }

  userLogin() async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Lấy user từ hàm getUserByEmail, đợi kết quả trả về
      UserService userService = UserService();
      LocalUser.User? user = await userService.getUserByEmail(email);
      // Kiểm tra xem user có tồn tại không trước khi chuyển hướng
      if (user != null) {
        saveUserInformation(email, user.id);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => MyNavigation(userId: user.id)),
        );
      } else {
        // Xử lý trường hợp không tìm thấy user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.orangeAccent,
            content: Text(
              "Sai tên đăng nhập hoặc mật khẩu",
              style: TextStyle(fontSize: 18.0),
            ),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.orangeAccent,
          content: Text(
            "Sai tên đăng nhập hoặc mật khẩu",
            style: TextStyle(fontSize: 18.0),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(
                height: 30.0,
              ),
              const Text("Let's Sign You In",
                  style: TextStyle(
                      color: Colors.black,
                      fontSize: 30.0,
                      fontWeight: FontWeight.w700)),
              SizedBox(
                height: 10.0,
              ),
              Padding(
                padding: const EdgeInsets.only(left: 20.0, right: 20.0),
                child: Form(
                  key: _formkey,
                  child: Column(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                            vertical: 2.0, horizontal: 30.0),
                        decoration: BoxDecoration(
                            color: Color(0xFFedf0f8),
                            borderRadius: BorderRadius.circular(30)),
                        child: TextFormField(
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please Enter E-mail';
                            }
                            return null;
                          },
                          controller: mailcontroller,
                          decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: "Email",
                              hintStyle: TextStyle(
                                  color: Color(0xFFb2b7bf), fontSize: 18.0)),
                        ),
                      ),
                      SizedBox(
                        height: 30.0,
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                            vertical: 2.0, horizontal: 30.0),
                        decoration: BoxDecoration(
                            color: Color(0xFFedf0f8),
                            borderRadius: BorderRadius.circular(30)),
                        child: TextFormField(
                          controller: passwordcontroller,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please Enter Password';
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: "Password",
                              hintStyle: TextStyle(
                                  color: Color(0xFFb2b7bf), fontSize: 18.0)),
                          obscureText: true,
                        ),
                      ),
                      SizedBox(
                        height: 30.0,
                      ),
                      GestureDetector(
                        onTap: () {
                          if (_formkey.currentState!.validate()) {
                            setState(() {
                              email = mailcontroller.text;
                              password = passwordcontroller.text;
                            });
                          }
                          userLogin();
                        },
                        child: Container(
                            width: MediaQuery.of(context).size.width,
                            padding: EdgeInsets.symmetric(
                                vertical: 13.0, horizontal: 30.0),
                            decoration: BoxDecoration(
                                color: Color(0xFF273671),
                                borderRadius: BorderRadius.circular(30)),
                            child: Center(
                                child: Text(
                              "Sign In",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22.0,
                                  fontWeight: FontWeight.w500),
                            ))),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                height: 20.0,
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => ForgotPassword()));
                },
                child: Text("Forgot Password?",
                    style: TextStyle(
                        color: Color(0xFF8c8e98),
                        fontSize: 18.0,
                        fontWeight: FontWeight.w500)),
              ),
              SizedBox(
                height: 40.0,
              ),
              Text(
                "or Log In with",
                style: TextStyle(
                    color: Color(0xFF273671),
                    fontSize: 22.0,
                    fontWeight: FontWeight.w500),
              ),
              const SizedBox(
                height: 30.0,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () {},
                    child: const Icon(
                      Icons.facebook,
                      size: 50,
                      color: Color(0xFF273671),
                    ),
                  ),
                  const SizedBox(
                    width: 30.0,
                  ),
                  GestureDetector(
                    onTap: () {
                      // AuthMethods().signInWithApple();
                    },
                    child: const Icon(
                      Icons.g_mobiledata,
                      size: 50,
                      color: Color(0xFF273671),
                    ),
                  ),
                  const SizedBox(
                    width: 30.0,
                  ),
                  GestureDetector(
                    onTap: () {
                      // AuthMethods().signInWithApple();
                    },
                    child: const Icon(
                      Icons.apple,
                      size: 50,
                      color: Color(0xFF273671),
                    ),
                  )
                ],
              ),
              SizedBox(
                height: 40.0,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Don't have an account?",
                      style: TextStyle(
                          color: Color(0xFF8c8e98),
                          fontSize: 18.0,
                          fontWeight: FontWeight.w500)),
                  SizedBox(
                    width: 5.0,
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (context) => SignUp()));
                    },
                    child: Text(
                      "Sign Up",
                      style: TextStyle(
                          color: Color(0xFF273671),
                          fontSize: 20.0,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
