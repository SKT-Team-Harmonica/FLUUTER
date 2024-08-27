import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:http/http.dart' as http;

class VoicePage extends StatefulWidget {
  @override
  _VoicePageState createState() => _VoicePageState();
}

class _VoicePageState extends State<VoicePage> {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _text = '';

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  void startListening() async {
    bool available = await _speech.initialize(
        onStatus: (val) => print('onStatus: $val'),
        onError: (val) => print('onError: $val'));
    if (available) {
      setState(() => _isListening = true);
      _speech.listen(
        onResult: (val) => setState(() {
          _text = val.recognizedWords;
        }),
        localeId: 'ko_KR',
      );
    }
  }

  void stopListening() {
    _speech.stop();
    setState(() => _isListening = false);
    sendTextToServer(_text);
  }

  Future<void> sendTextToServer(String text) async {
    final response = await http.post(
      Uri.parse('https://yourserver.com/process_text'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"text": text}),
    );

    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);
      // Assuming the server sends back a URL for the video
      String videoUrl = result['video_url'];
      // You can play the video using a video player package
    } else {
      // Handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('음성 기반 수어 생성'),
      ),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: _isListening ? stopListening : startListening,
            child: Text(_isListening ? 'Stop' : 'Start'),
          ),
          if (_text.isNotEmpty) Text('Recognized text: $_text'),
        ],
      ),
    );
  }
}
