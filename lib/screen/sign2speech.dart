// ignore_for_file: prefer_const_constructors

import 'dart:convert';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

class CameraPage extends StatefulWidget {
  @override
  _CameraPageState createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  CameraController? _controller;
  late List<CameraDescription> cameras;
  bool _isRecording = false;
  String _filePath = '';
  String _text = '';
  bool _isCameraAvailable = false;
  String _selectedLanguage = '한국어';
  final FlutterTts flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    await Permission.camera.request();

    try {
      cameras = await availableCameras();
      _controller = CameraController(
        cameras[0],
        ResolutionPreset.medium,
        enableAudio: true,
      );
      await _controller?.initialize();
      setState(() {
        _isCameraAvailable = true;
      });
    } catch (e) {
      print('No camera found or camera initialization failed: $e');
      setState(() {
        _isCameraAvailable = false;
      });
    }
  }

  Future<void> _startRecording() async {
    if (_controller != null && !_controller!.value.isRecordingVideo) {
      try {
        await _controller?.startVideoRecording();
        setState(() {
          _isRecording = true;
        });
      } catch (e) {
        // Handle error if any
        print('Error starting video recording: $e');
      }
    }
  }

  Future<void> _stopRecording() async {
    if (_controller != null && _controller!.value.isRecordingVideo) {
      try {
        final XFile videoFile = await _controller!.stopVideoRecording();
        setState(() {
          _isRecording = false;
        });
        _sendVideoToServer(videoFile); // Sending the recorded video file
      } catch (e) {
        // Handle error if any
        print('Error stopping video recording: $e');
      }
    }
  }

  Future<void> _sendVideoToServer(XFile videoFile) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('https://294a-203-236-8-208.ngrok-free.app/predict'),
    );
    request.files
        .add(await http.MultipartFile.fromPath('video', videoFile.path));

    final response = await request.send();

    if (response.statusCode == 200) {
      final responseBody = await response.stream.bytesToString();
      final responseData = json.decode(responseBody);
      print(responseData['prediction']);
      setState(() {
        _text = responseData['prediction'] ?? 'No text found';
      });
    } else {
      setState(() {
        _text = 'Error: Failed to upload video';
      });
    }
  }

  void _onLanguageChanged(String? newLanguage) {
    if (newLanguage != null) {
      setState(() {
        _selectedLanguage = newLanguage;
      });
      if (_text.isNotEmpty) {
        _translateText(_text, newLanguage);
      }
    }
  }

  Future<void> _translateText(String text, String targetLanguage) async {
    final url = 'https://294a-203-236-8-208.ngrok-free.app/translate';
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
          _text =
              translatedText; // Assuming the API responds with the translated text directly
        });
      } else {
        print('Failed to translate text: ${response.statusCode}');
      }
    } catch (e) {
      print('Error translating text: $e');
    }
  }

  void _onMicButtonPressed() async {
    await flutterTts.setLanguage(_selectedLanguage == '한국어'
        ? 'ko-KR'
        : _selectedLanguage == 'English'
            ? 'en-US'
            : 'ja-JP');
    await flutterTts.speak(_text);
  }

  @override
  void dispose() {
    _controller?.dispose();
    flutterTts.stop();
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
            '수어 기반 음성 생성',
            style: TextStyle(
                color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          if (_isCameraAvailable && _controller?.value.isInitialized == true)
            SizedBox(
              height: 282,
              child: CameraPreview(_controller!),
            )
          else
            Container(
              height: 282,
              color: Colors.grey,
              child: Center(
                child: Text(
                  'Camera not available',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          SizedBox(
            height: 5,
          ),
          Container(
            width: double.infinity,
            color: Color(0xFFFFBEC1),
            padding: EdgeInsets.all(10),
            child: Center(
              child: Text(
                '수어 번역 문장',
                style: TextStyle(
                    color: Colors.black,
                    fontSize: 25,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Container(
            width: double.infinity,
            height: 170,
            padding: EdgeInsets.all(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Center(
                child: Text(
                  _text,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: _onMicButtonPressed,
                  child: Image.asset(
                    'assets/mic.png',
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
          ElevatedButton(
            onPressed: _isRecording ? _stopRecording : _startRecording,
            child: Text(_isRecording ? 'Stop' : 'Record'),
          ),
        ],
      ),
    );
  }
}
