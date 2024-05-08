import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TtsButton extends StatefulWidget {
  final String language;
  final String text;

  const TtsButton({Key? key, required this.language, required this.text}) : super(key: key);

  @override
  State<TtsButton> createState() => _TtsButtonState();
}

class _TtsButtonState extends State<TtsButton> {
  bool _isTapped = false;
  FlutterTts _tts = FlutterTts();

  @override
  void dispose() {
    super.dispose();
    _tts.stop();
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () {
        _isTapped = true;
        setState(() {});
        Future.delayed(Duration(milliseconds: 300), () {
          _isTapped = false;
          setState(() {});
        });
        setUpTts(widget.language);
        _runTts(text: widget.text); // Sử dụng widget.text làm tham số cho hàm _runTts
        print(widget.text);
      },
      icon: Icon(
        Icons.audiotrack_rounded,
        size: 40,
        color: _isTapped ? Colors.white : Colors.black,
      ),
    );
  }

  setUpTts(String language) async {
    await _tts.setLanguage(language);
    await _tts.setSpeechRate(0.40);
    print(language);
  }

  _runTts({required String text}) async {
    await _tts.speak(text);
  }
}