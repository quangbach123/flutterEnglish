import 'package:flashcard/Models/Topic.dart';
import 'package:flashcard/Notifiers/flashcard_notifier.dart';
import 'package:flashcard/pages/flashcard_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

loadSession({required BuildContext context , required Topic topic} ){
  Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context)=> FlashCardPage(topic: topic, words: [], isEnglishFirst: true, userId: '', isRecord:true,)));
  Provider.of<FlashCardNotifier>(context, listen:false).setTopic(topic:topic);

}