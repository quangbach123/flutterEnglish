import 'package:flashcard/Models/Topic.dart';
import 'package:flutter/material.dart';

class FlashCardNotifier extends ChangeNotifier{

  late Topic topic  ;
  setTopic({required Topic topic}){
    this.topic=topic;
    notifyListeners();
  }

}