import 'package:flashcard/Configs/Constants.dart';
import 'package:flutter/material.dart';

final appTheme = ThemeData(
  // primaryColor: themeColor,
  textTheme: const TextTheme(
    bodyMedium: TextStyle(
      color: Colors.black,
      fontSize: 18,
    ) 
  ),
  appBarTheme: const AppBarTheme(
    elevation: 24,
    centerTitle: true,
    titleTextStyle: TextStyle(
      color: Colors.black,
      fontSize: 20,
      fontWeight: FontWeight.bold,
      
    ),
    backgroundColor: themeColor
    
    
  ),
  scaffoldBackgroundColor: Colors.deepPurple[300],
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: themeColor, // Đặt màu của BottomNavigationBar là màu của thanh bên trên
  ),
);
