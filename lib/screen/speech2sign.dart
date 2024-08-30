// ignore_for_file: avoid_print, prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:video_player/video_player.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:convert';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

class VoicePage extends StatefulWidget {
  @override
  _VoicePageState createState() => _VoicePageState();
}

class _VoicePageState extends State<VoicePage> {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _recognizedText = ' ';
  VideoPlayerController? _videoController;
  bool _isVideoLoading = true; // Flag to show loading state
  final String _defaultImage = 'assets/default.png';
  bool _isVideoError = false;
  List<String> _videoQueue = [];
  bool _isPlaying = false; //
  String _selectedLanguage = '한국어';

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  void startListening() async {
    var status = await Permission.microphone.request();
    if (status.isDenied) {
      print('Microphone permission denied.');
    }
    bool available = await _speech.initialize(
        onStatus: (val) => print('onStatus: $val'),
        onError: (val) => print('onError: $val'));
    if (available) {
      setState(() => _isListening = true);
      _speech.listen(
        onResult: (result) {
          if (result.finalResult) {
            setState(() {
              _recognizedText = "$_recognizedText ${result.recognizedWords}";
              List<String> words = _recognizedText.trim().split(' ');

              // Add each recognized word to the video queue
              for (String word in words) {
                if (word.isNotEmpty) {
                  _videoQueue.add(word); // Add to video queue
                  _videoQueue.add(".");
                }
              }

              // Start playing the next video if not already playing
              if (!_isPlaying && _videoQueue.isNotEmpty) {
                playNextVideo();
              }
            });
          }
        },
        listenFor: Duration(seconds: 60),
        pauseFor: Duration(seconds: 10),
        listenMode: stt.ListenMode.dictation,
        localeId: 'ko_KR',
      );
    }
  }

  Future<void> stopListening() async {
    await _speech.stop();
    setState(() => _isListening = false);
  }

  Future<void> fetchSignVideo(String gloss) async {
    setState(() {
      _isVideoLoading = true;
    });
    try {
      print('Fetching video for: $gloss');
      final response = await http.get(Uri.parse(
          'https://fc58-203-236-3-227.ngrok-free.app/similar?gloss=$gloss'));
      if (response.statusCode == 200) {
        // Save the MP4 file received from the server locally
        final Directory tempDir = await getTemporaryDirectory();
        final File file = File('${tempDir.path}/$gloss.mp4');
        await file.writeAsBytes(response.bodyBytes);

        // Initialize the video player with the downloaded MP4
        VideoPlayerController newController = VideoPlayerController.file(file);
        await newController.initialize();

        // Set the last frame image as the placeholder
        setState(() {
          _isVideoLoading = false;
          _videoController?.dispose(); // Dispose the old controller
          _videoController = newController;
        });

        // Start playing the new video
        _videoController!.play();
        setState(() => _isPlaying = true);

        // Wait until the video is finished before moving to the next
        _videoController!.addListener(() async {
          if (_videoController!.value.position >=
              _videoController!.value.duration) {
            _videoController!.removeListener(() {}); // Remove listener
            setState(() => _isPlaying = false); // Video finished playing
            await playNextVideo(); // Play the next video in the queue
          }
        });
      } else {
        print('Failed to load video: ${response.statusCode}');
        setState(() {
          _isVideoLoading = false;
          _isVideoError = true;
        });
      }
    } catch (e) {
      print('Error fetching video: $e');
      setState(() => _isVideoLoading = false);
    }
  }

  Future<void> playNextVideo() async {
    if (_videoQueue.isNotEmpty) {
      // Get the next video from the queue
      String nextGloss = _videoQueue.removeAt(0);
      await fetchSignVideo(nextGloss); // Fetch and play the next video
    }
  }

  void _onLanguageChanged(String? newLanguage) {
    if (newLanguage != null) {
      setState(() {
        _selectedLanguage = newLanguage;
      });
      if (_recognizedText.isNotEmpty) {
        _translateText(_recognizedText, newLanguage);
      }
    }
  }

  Future<void> _translateText(String text, String targetLanguage) async {
    final url = 'https://6afa-203-236-3-227.ngrok-free.app/translate';
    final headers = {'Content-Type': 'application/json'};
    final body = json.encode({
      'string': text,
      'target_language': targetLanguage,
    });

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final String translatedText =
            data['generated_sentence'] ?? 'Translation error';
        setState(() {
          _recognizedText =
              translatedText; // Assuming the API responds with the translated text directly
        });
      } else {
        print('Failed to translate text: ${response.statusCode}');
      }
    } catch (e) {
      print('Error translating text: $e');
    }
  }

  void _onMicButtonPressed() {
    if (_isListening) {
      stopListening();
    } else {
      startListening();
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Container(
          decoration: BoxDecoration(
            color: Color(0x20FFBEC1),
            borderRadius: BorderRadius.circular(15),
          ),
          padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
          child: Text(
            '음성 기반 수어 생성',
            style: TextStyle(
                color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            height: 25.0,
          ),
          Container(
            width: double.infinity,
            color: Color(0xFFFFBEC1),
            padding: EdgeInsets.all(10),
            child: Center(
              child: Text(
                '3D 아바타 생성',
                style: TextStyle(
                    color: Colors.black,
                    fontSize: 25,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
          if (_isVideoLoading || _isVideoError)
            Image.asset(_defaultImage) // Show default image while loading
          else if (_videoController != null &&
              _videoController!.value.isInitialized)
            AspectRatio(
              aspectRatio: _videoController!.value.aspectRatio,
              child: VideoPlayer(_videoController!),
            ),
          Container(
            width: double.infinity,
            color: Color(0xFFFFBEC1),
            padding: EdgeInsets.all(10),
            child: Center(
              child: Text(
                '입력된 문장',
                style: TextStyle(
                    color: Colors.black,
                    fontSize: 25,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
          if (_recognizedText.isNotEmpty)
            Container(
                width: double.infinity,
                height: 170,
                padding: EdgeInsets.all(16),
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: Center(
                    child: Text(
                      _recognizedText,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                )),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: _onMicButtonPressed,
                  child: Image.asset(
                    _isListening ? 'assets/mic_off.png' : 'assets/mic.png',
                    width: 61,
                    height: 61,
                  ),
                ),

                // Dropdown Button
                DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    padding: const EdgeInsets.only(left: 60),
                    value: _selectedLanguage,
                    onChanged: _onLanguageChanged,
                    borderRadius: BorderRadius.circular(20),
                    items: <String>['한국어', 'English']
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(
                          value,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
