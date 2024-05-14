import 'package:flashcard/components/navigation.dart';
import 'package:flashcard/errors/views/404_error/not_found_error.dart';
import 'package:flashcard/main.dart';
import 'package:flashcard/pages/login.dart';
import 'package:flutter/material.dart';

class RouteGenerator {
  static const String authenticationWrapper = 'authenticationWrapper';

  static const String loginPage = 'loginPage';
  static const String homePage = 'homePage';
  static const String findStudentPage = 'findStudentPage';
  static const String payment = 'payment';
  static const String confirmation = 'confirmation';
  static const String successPage = 'successPage';
  static const String updateInfoPage = 'updateInfoPage';
  static const String articleNotFoundPage = 'articleNotFoundPage';
  static const String historyPage = 'historyPage';

  RouteGenerator._();

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case authenticationWrapper:
        return MaterialPageRoute(
            settings: settings, builder: (_) => const AuthenticationWrapper());
      case homePage:
        final userId = settings.arguments as String;
        return MaterialPageRoute(
            settings: settings, builder: (_) => MyNavigation(userId: userId));
      case loginPage:
        return MaterialPageRoute(
            settings: settings, builder: (_) => const LogIn());
      default:
        return MaterialPageRoute(
            settings: settings, builder: (_) => const NotFound404Error());
    }
  }
}
