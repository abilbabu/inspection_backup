import 'dart:async';

import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

class SignatureSpeechController  extends ChangeNotifier {
  final SpeechToText _speechToText = SpeechToText();

  bool speechEnabled = false;
  bool isListening = false;
  Timer? silenceTimer;

  String _baseText = "";
  String _currentSpeech = "";

  TextEditingController? _speechController;

  Future<void> initSpeech() async {
    speechEnabled = await _speechToText.initialize();
    notifyListeners();
  }

  void startSilenceTimer() {
    silenceTimer?.cancel();

    silenceTimer = Timer(const Duration(seconds: 2), () async {
      if (isListening) {
        await stopListening();
      }
    });
  }

  Future<void> startListening({
    required TextEditingController controller,
  }) async {
    if (!speechEnabled) {
      speechEnabled = await _speechToText.initialize();
    }

    if (!speechEnabled) return;

    _speechController = controller;

    // Save existing note
    _baseText = controller.text.trim();

    _currentSpeech = "";

    isListening = true;
    notifyListeners();

    await _speechToText.listen(
      listenMode: ListenMode.dictation,
      partialResults: true,
      cancelOnError: true,
      onResult: onSpeechResult,
    );
  }

  void onSpeechResult(SpeechRecognitionResult result) {
    if (_speechController == null) return;

    _currentSpeech = result.recognizedWords.trim();

    // Show live text while speaking
    if (_baseText.isEmpty) {
      _speechController!.text = _currentSpeech;
    } else {
      _speechController!.text = "$_baseText $_currentSpeech";
    }

    _speechController!.selection = TextSelection.fromPosition(
      TextPosition(offset: _speechController!.text.length),
    );

    // Stop when speech is finished
    if (result.finalResult) {
      stopListening();
    }

    notifyListeners();
  }

  Future<void> stopListening() async {
    await _speechToText.stop();

    isListening = false;

    // Save the final text so the next recording appends after it
    _baseText = _speechController?.text.trim() ?? "";

    notifyListeners();
  }

  @override
  void dispose() {
    silenceTimer?.cancel();
    _speechToText.stop();
    super.dispose();
  }
}
