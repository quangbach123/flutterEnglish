import 'package:flashcard/Notifiers/flashcard_notifier.dart';
import 'package:flashcard/components/navigation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CustomAppBar extends StatelessWidget {
  const CustomAppBar({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<FlashCardNotifier>(
      builder: (_, notifier, __) => Scaffold(
        appBar: AppBar(
          actions: [
            IconButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (context) => MyNavigation(
                                userId: '',
                              )),
                      (route) => false);
                },
                icon: Icon(Icons.clear))
          ],
          title: Text(notifier.topic.topicName),
          leading: Padding(
            padding: const EdgeInsets.all(7.0),
            // child: Hero(
            //   tag: notifier.topic.topicName,
            //   child: Image.network(
            //     notifier.topic.topicImageUrl,
            //     fit: BoxFit.cover, // Đảm bảo hình ảnh phù hợp với kích thước đã chọn
            //   ),
            // ),
          ),
        ),
      ),
    );
  }
}
