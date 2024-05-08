import 'package:flashcard/Configs/Constants.dart';
import 'package:flashcard/Models/Topic.dart';
import 'package:flashcard/animations/fade_in_animation.dart';
import 'package:flashcard/utils/methods.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class Topic_Tile extends StatelessWidget {
  const Topic_Tile({
    super.key,
    required this.topic
  }) ;

  final Topic topic;

  @override
 @override
Widget build(BuildContext context) {
  return FadeInAnimation(
    child: GestureDetector(
      onTap:(){
        if (kDebugMode) {
          print(topic.topicName);
        }
        loadSession(context: context, topic: topic);
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          color: oColor,
        ),
        child: Column(
          children: [
            // Expanded(
            //   flex: 2,
            //   child: Hero(
            //     tag: topic.topicName,
            //         child: topic.topicImageUrl != null && topic.topicImageUrl.isNotEmpty
            //             ? Image.network(
            //                 topic.topicImageUrl,
            //                 fit: BoxFit.cover,
            //               )
            //             : Image.network(
            //                 'https://cdn-icons-png.flaticon.com/128/1042/1042339.png',
            //                 fit: BoxFit.cover,
            //               ),
            //   ),
            // ),
            Expanded(
              child: Text(
                topic.topicName,
              ),
            )
          ],
        ),
      ),
    ),
  );
}
}
