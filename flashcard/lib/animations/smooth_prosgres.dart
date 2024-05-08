import 'package:flashcard/Configs/Constants.dart';
import 'package:flutter/material.dart';

class SmoothLinearProgressIndicator extends StatefulWidget {
  final double value;

  const SmoothLinearProgressIndicator({Key? key, required this.value}) : super(key: key);

  @override
  _SmoothLinearProgressIndicatorState createState() => _SmoothLinearProgressIndicatorState();
}

class _SmoothLinearProgressIndicatorState extends State<SmoothLinearProgressIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late double _currentValue = 0 ;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.value;
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
    _controller.value = _currentValue;
    _animation = Tween<double>(
      begin: 0.0,
      end: _currentValue,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    
     // Đặt giá trị ban đầu cho controller
  }

  @override
  void didUpdateWidget(covariant SmoothLinearProgressIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _currentValue = widget.value;
      _controller.animateTo(_currentValue, duration: Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return LinearProgressIndicator(
          value: _animation.value,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(oColor), // Thay đổi màu sắc tùy ý
          minHeight: 10,
          semanticsLabel: 'Progress',
          semanticsValue: '${(_animation.value * 100).toStringAsFixed(0)}%',
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
