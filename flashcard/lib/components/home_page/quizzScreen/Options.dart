import 'package:flashcard/Configs/Constants.dart';
import 'package:flutter/material.dart';

class AnswerOptionsWidget extends StatelessWidget {
  late String option;
  final VoidCallback onPressed;
  AnswerOptionsWidget({Key? key, required this.option, required this.onPressed})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onPressed, // Hành động khi nút được nhấn

        title: Text(
          option,
          style: TextStyle(
            color: Colors.black, // Màu chữ
            fontWeight: FontWeight.bold, // In đậm
          ),
          // Icon khi nút được chọn
        ),
      ),
    );
  }
}
