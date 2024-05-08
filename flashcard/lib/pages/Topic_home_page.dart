
import 'package:flashcard/Configs/Constants.dart';
import 'package:flashcard/Models/Topic.dart';
import 'package:flashcard/Services/WordServices.dart';
import 'package:flashcard/animations/fade_in_animation.dart';
import 'package:flashcard/components/home_page/Topic_Tile.dart';
import 'package:flashcard/pages/Topic_Real_Home_Page.dart';
import 'package:flashcard/pages/home_page_Folder.dart';
import 'package:flashcard/pages/public_topic_page.dart';
import 'package:flashcard/pages/userProfile.dart';
import 'package:flashcard/pages/word_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  final String userId;
  const HomePage({Key? key, required this.userId}) : super(key: key);  
  State<HomePage> createState() => _HomePageState();
}


class _HomePageState extends State<HomePage> {
 TextEditingController _searchController = TextEditingController();
  List<Topic> _topics = [];
  WordService _wordService = WordService();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Flashcard'),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Image.network(
            'https://ouch-cdn2.icons8.com/7H0yiDQ-2jzTJ-XeLKCgfXyE2CaeiJpCsyQeMWu8nPU/rs:fit:368:485/czM6Ly9pY29uczgu/b3VjaC1wcm9kLmFz/c2V0cy9wbmcvMTE1/L2Q1MWY3MWI5LWUz/NjYtNDk2ZC1hZmYz/LTYzMjRlZWFmYjM4/Yi5wbmc.png',
            height: MediaQuery.of(context).size.height * 0.4,
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
      backgroundColor: Colors.black, // Màu nền của navigation bar là màu đen
      elevation: 8, // Độ nổi
      items: [
        BottomNavigationBarItem(
          icon: Icon(Icons.home, color: Colors.black), // Màu icon trắng
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.search, color: Colors.black), // Màu icon trắng
          label: 'Search',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.bookmark, color: Colors.black), // Màu icon trắng
          label: 'Bookmarks',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings, color: Colors.black), // Màu icon trắng
          label: 'Settings',
        ),
      ],
      currentIndex: 0,
      selectedItemColor: Colors.black, // Màu chữ và icon của label được chọn là màu trắng
      onTap: (index) {
        if (index == 0) {
          Navigator.push(context, MaterialPageRoute(builder: (context) =>  UserTopicScreen(userId: widget.userId,)));
        }
        if(index==1){
          Navigator.push(context, MaterialPageRoute(builder: (context) =>  UserFoldersScreen(userId: widget.userId,)));
        }
        if(index==2){
           Navigator.push(context, MaterialPageRoute(builder: (context) => PublicTopicsPage(userId: widget.userId,)));
        }
        if(index==3){
          Navigator.push(context, MaterialPageRoute(builder: (context) => UserProfileScreen(userId: widget.userId,)));
        }
      },
    ),

      
    );
  }
}






