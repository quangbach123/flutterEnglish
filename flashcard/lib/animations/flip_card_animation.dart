import 'package:flutter/material.dart';

enum FlipDirections {
  horizontal,
  vertical,
}

class FlipCardAnimation extends StatefulWidget {
  final Widget frontWidget;
  final Widget backWidget;
  final FlipDirections direction;

  const FlipCardAnimation({
    Key? key,
    required this.frontWidget,
    required this.backWidget,
    this.direction = FlipDirections.horizontal,
    required Null Function() onAnimationStart,
    required Null Function() onAnimationEnd,
  }) : super(key: key);

  @override
  _FlipCardAnimationState createState() => _FlipCardAnimationState();
}

class _FlipCardAnimationState extends State<FlipCardAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  bool _isFront = true;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 100),
    );

    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _isFront = !_isFront;
          _controller.reverse();
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _flipCard() {
    if (_controller.status == AnimationStatus.completed ||
        _controller.status == AnimationStatus.forward) {
      _controller.reverse();
    } else {
      _controller.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _flipCard,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final value = _animation.value;
          final frontRotation = _isFront ? 0.0 : -1 * value * 3.14;
          final backRotation = _isFront ? value * 3.14 : 0.0;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.002)
              ..rotateY(widget.direction == FlipDirections.horizontal
                  ? frontRotation
                  : 0)
              ..rotateX(widget.direction == FlipDirections.vertical
                  ? backRotation
                  : 0),
            child: _isFront ? widget.frontWidget : widget.backWidget,
          );
        },
      ),
    );
  }
}
