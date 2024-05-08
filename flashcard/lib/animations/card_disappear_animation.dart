import 'package:flutter/material.dart';


class FadeOutAnimation extends StatefulWidget {
  final Widget child;
  final VoidCallback onAnimationComplete;

  const FadeOutAnimation({
    required this.child,
    required this.onAnimationComplete,
  });

  @override
  _FadeOutAnimationState createState() => _FadeOutAnimationState();
}

class _FadeOutAnimationState extends State<FadeOutAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500), // Thời gian của animation
    );
    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(_animationController);
    _animationController.forward().then((_) {
      widget.onAnimationComplete();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacityAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value, // Giá trị opacity sẽ thay đổi theo animation
          child: widget.child,
        );
      },
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  void startAnimation() {
  _animationController.forward();
}

}

