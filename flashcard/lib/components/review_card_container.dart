import 'package:flashcard/Configs/Constants.dart';
import 'package:flutter/material.dart';

class CardReviewContainer extends StatelessWidget {
  const CardReviewContainer({
    super.key,
    required this.size,
    required this.content,
    required this.textColor,
    required this.ttsButton,
  });

  final Size size;
  final String content;
  final Color textColor;
  final Widget ttsButton;

  @override
  Widget build(BuildContext context) {
  return Container(
    width: size.width * 0.70,
    height: size.height * 0.20,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(25),
      color: oColor, // Thay oColor bằng màu mong muốn
    ),
    child: Stack(
      children: [
        Positioned(
          top: 10, // Điều chỉnh vị trí theo y nếu cần thiết
          left: 10, // Điều chỉnh vị trí theo x nếu cần thiết
          child: ttsButton, // Sử dụng tham số ttsButton thay cho IconButton mặc định
        ),
        Center(
          child: Text(
            content,
            style: TextStyle(fontSize: 20, color: textColor),
          ),
        ),
      ],
    ),
  );
}
}