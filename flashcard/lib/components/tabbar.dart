import 'package:flashcard/pages/Topic_Real_Home_Page.dart';
import 'package:flashcard/pages/home_page_Folder.dart';
import 'package:flutter/material.dart';

/// Flutter code sample for [TabBar].

class TabBarExample extends StatefulWidget {
  final String userId;

  const TabBarExample({super.key, required this.userId});

  @override
  State<TabBarExample> createState() => _TabBarExampleState();
}

class _TabBarExampleState extends State<TabBarExample> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      initialIndex: 0,
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Thư viện'),
          bottom: const TabBar(
            tabs: <Widget>[
              Tab(
                text: 'Học phần',
              ),
              Tab(
                text: 'Thư mục',
              ),
            ],
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TabBarView(
              children: <Widget>[
                UserTopicScreen(userId: widget.userId),
                UserFoldersScreen(
                  userId: widget.userId,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
