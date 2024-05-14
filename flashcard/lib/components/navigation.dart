import 'package:flashcard/components/tabbar.dart';
import 'package:flashcard/pages/Topic_Real_Home_Page.dart';
import 'package:flashcard/pages/achievement_page.dart';
import 'package:flashcard/pages/home_page_Folder.dart';
import 'package:flashcard/pages/public_topic_page.dart';
import 'package:flashcard/pages/userProfile.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MyNavigation extends StatefulWidget {
  final String userId;
  const MyNavigation({super.key, required this.userId});
  @override
  State<MyNavigation> createState() => _MyNavigationState();
}

class _MyNavigationState extends State<MyNavigation> {
  int _currentIndex = 0;

  Color _selectedItemColor(BuildContext context) {
    // Determine a color that contrasts well with both light and dark themes
    return Theme.of(context).brightness == Brightness.light
        ? Colors.black // Color for light theme
        : Colors.amber; // Color for dark theme
  }

  BottomNavigationBar _buildBottomNavigationBar(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      selectedItemColor: _selectedItemColor(
          context), // Set the color for selected item (icon and label)
      unselectedItemColor: Theme.of(context).unselectedWidgetColor,
      showSelectedLabels: true,
      showUnselectedLabels: false,
      iconSize: 24,
      onTap: (int newIndex) {
        setState(() {
          _currentIndex = newIndex;
        });
      },
      items: const [
        BottomNavigationBarItem(
            label: "Trang Chủ",
            icon: Icon(
              Icons.home,
            )),
        BottomNavigationBarItem(
            label: "Chủ đề",
            icon: Icon(
              Icons.book,
            )),
        BottomNavigationBarItem(
            label: "Thư viện",
            icon: Icon(
              Icons.folder_shared,
            )),
        BottomNavigationBarItem(
            label: "Hồ sơ",
            icon: Icon(
              Icons.person,
            )),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> body = [
      PublicTopicsPage(
        userId: widget.userId,
      ),
      AchievementPage(userId: widget.userId),
      TabBarExample(userId: widget.userId),
      UserProfileScreen(
        userId: widget.userId,
      ),
    ];
    return Scaffold(
        body: SafeArea(child: body[_currentIndex]),
        bottomNavigationBar: _buildBottomNavigationBar(context));
  }
}
