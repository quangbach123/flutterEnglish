import 'package:firebase_auth/firebase_auth.dart';
import 'package:flashcard/pages/login.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:universal_html/html.dart' as html;
class ChangePasswordPage extends StatefulWidget {
  @override
  _ChangePasswordPageState createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  String currentPassword = '';
  String newPassword = '';
  String confirmPassword = '';
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

  void changePassword() async {
    if (_formKey.currentState!.validate()) {
      try {
        User user = FirebaseAuth.instance.currentUser!;
        AuthCredential credential = EmailAuthProvider.credential(email: user.email!, password: currentPassword);
        await user.reauthenticateWithCredential(credential);
        await user.updatePassword(newPassword);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Password changed successfully."),
        ));
        logoutAndNavigateToLogin(context);
        
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Failed to change password : $e"),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Change Password'),
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: InputDecoration(labelText: 'Current Password'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your current password.';
                  }
                  return null;
                },
                onChanged: (value) {
                  currentPassword = value;
                },
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'New Password'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a new password.';
                  }
                  return null;
                },
                onChanged: (value) {
                  newPassword = value;
                },
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Confirm New Password'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please confirm your new password.';
                  } else if (value != newPassword) {
                    return 'Passwords do not match.';
                  }
                  return null;
                },
                onChanged: (value) {
                  confirmPassword = value;
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: changePassword,
                child: Text('Change Password'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
