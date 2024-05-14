import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class card extends StatelessWidget {
  final String english;
  final double size;
  final Color color;
  final Widget ttsButton;

  card(
      {Key? key,
      required this.english,
      required this.size,
      required this.color,
      required this.ttsButton})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Stack(
          children: [
            Container(
              height: size,
              width: double.infinity,
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: color, width: 2.0)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
            Positioned(
              bottom: 10, // Điều chỉnh vị trí theo y nếu cần thiết
              right: 10, // Điều chỉnh vị trí theo x nếu cần thiết
              child:
                  ttsButton, // Sử dụng tham số ttsButton thay cho IconButton mặc định
            ),
            Center(
              child: Text(english,
                  style: TextStyle(
                      fontSize: 18, color: color, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
