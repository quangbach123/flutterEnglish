import 'dart:async';
import 'dart:isolate';

class SpeechIsolate {
  static late SendPort _sendPort;
  static late Isolate _isolate;
  
  static get flutterTts => null;

  static void _entryPoint(SendPort sendPort) async {
    _sendPort = sendPort;
    final receivePort = ReceivePort();
    sendPort.send(receivePort.sendPort);

    receivePort.listen((message) {
      if (message is String) {
        // Nhận tin nhắn từ luồng chính và thực hiện phát âm thanh
        _speak(message);
      }
    });
  }

  static Future<void> startIsolate() async {
    final receivePort = ReceivePort();
    _isolate = await Isolate.spawn(_entryPoint, receivePort.sendPort);
    final sendPort = await receivePort.first;
    _sendPort = sendPort;
  }

  static void _speak(String text) async {
    // Thực hiện việc phát âm thanh
    // Chú ý: Cần import flutter_tts và khởi tạo nó ở đây
    await flutterTts.setLanguage('en-US');
    await flutterTts.setPitch(1);
    await flutterTts.speak(text);
  }

  static void speak(String text) {
    _sendPort.send(text); // Gửi tin nhắn tới luồng con để thực hiện phát âm thanh
  }

  static void stopIsolate() {
    _isolate.kill();
  }
}
