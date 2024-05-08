import 'package:flashcard/Configs/Constants.dart';
import 'package:flutter/material.dart';

class AnswerOptionsWidget extends StatelessWidget {
  late String option;
  final VoidCallback onPressed;
  AnswerOptionsWidget({Key?key,required this.option, required this.onPressed}):super(key: key);
  @override
  Widget build(BuildContext context) {  
  return Column (
    children: [
      Container(
        height: 48,
        width: 240,
        child: ElevatedButton(
          onPressed: onPressed, // Hành động khi nút được nhấn
          style: ElevatedButton.styleFrom(
            primary: oColor, // Màu nền của nút
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20), // Bo tròn góc
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                option,
                style: TextStyle(
                  color: Colors.white, // Màu chữ
                  fontWeight: FontWeight.bold, // In đậm
                ),
              ),// Icon khi nút được chọn
            ],
          ),
        ),
      ),
    ],
  );
}

}


