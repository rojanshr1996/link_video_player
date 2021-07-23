import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter/cupertino.dart';

class SpeechApi {
  static final _speech = SpeechToText();

  static Future<bool> toggleRecording({
    required Function(String text) onResult,
    required ValueChanged<bool> onListening,
  }) async {
    if (_speech.isListening) {
      _speech.stop();
      return true;
    }
    final isAvailable = await _speech.initialize(
      onStatus: (status) => onListening(_speech.isListening),
      onError: (e) => print("Error: $e"),
      debugLogging: true,
    );

    if (isAvailable) {
      _speech.listen(
        onResult: (value) => onResult(value.recognizedWords),
        listenFor: Duration(seconds: 6),
        pauseFor: Duration(seconds: 5),
        // listenMode: ListenMode.confirmation,
      );
    }

    return isAvailable;
  }
}
