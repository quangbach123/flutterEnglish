import 'package:flutter/material.dart';

class CardAppearAnimation extends StatefulWidget {
  final Widget child; // Widget con cần áp dụng animation

   const CardAppearAnimation({Key? key, required this.child}) : super(key: key);

  @override
  _CardAppearAnimationState createState() => _CardAppearAnimationState();
}

class _CardAppearAnimationState extends State<CardAppearAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );
    _animation = Tween<double>(
      begin: 0.0, // Thay đổi giá trị này để bắt đầu từ dưới cùng của màn hình
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut, // Sử dụng Curves.easeInOut để tạo hiệu ứng chuyển động mềm mại
    ));
    // Start the animation
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Transform.translate(
            offset: Offset(0.0, (1 - _animation.value) * 100), // Di chuyển phần tử từ dưới lên
            child: widget.child,
          ),
        );
      },
    );
  }
}
