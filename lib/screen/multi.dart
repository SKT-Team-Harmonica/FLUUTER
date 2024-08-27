// ignore_for_file: avoid_print, prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as path;

class MultiPage extends StatefulWidget {
  @override
  _MultiPageState createState() => _MultiPageState();
}

class _MultiPageState extends State<MultiPage> {
  CameraController? _cameraController;
  late List<CameraDescription> cameras;
  late stt.SpeechToText _speech;
  String _text = '';
  bool _isRecording = false;
  bool _isListening = false;
  bool _isClicked = false;
  FlutterSoundRecorder? _recorder;
  bool _isCameraAvailable = false;
  String _filePath = '';
  static const platform = MethodChannel('com.project.skflyai/clova_speech');
  String _response = '녹음 중';

  @override
  void initState() {
    super.initState();
    initializeCamera();
    _speech = stt.SpeechToText();
    _recorder = FlutterSoundRecorder();
  }

  Future<void> initializeCamera() async {
    await Permission.camera.request();
    try {
      cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        _cameraController =
            CameraController(cameras[0], ResolutionPreset.medium);
        await _cameraController?.initialize();
        setState(() {
          _isCameraAvailable = true;
        });
      }
    } catch (e) {
      print('No camera found or camera initialization failed: $e');
      setState(() {
        _isCameraAvailable = false;
      });
    }
  }

  Future<void> startListeningAndRecording() async {
    var status1 = await Permission.storage.request();
    if (status1.isDenied) {
      print('Storage permission denied.');
    }
    var status = await Permission.microphone.request();
    if (status.isDenied) {
      print('Microphone permission denied.');
    }

    // Start Listening (STT)
    _isListening = await _speech.initialize();
    if (_isListening) {
      _speech.listen(
        onResult: (result) {
          if (result.finalResult) {
            setState(() {
              _text += result.recognizedWords;
            });
          }
        },
        listenFor: Duration(seconds: 60),
        pauseFor: Duration(seconds: 10),
        listenMode: stt.ListenMode.dictation,
        localeId: 'ko_KR',
      );
    }

    // Start Recording
    Directory tempDir = await getTemporaryDirectory();
    _filePath = '${tempDir.path}/result.mp4';
    print(_filePath);

    await _recorder?.openRecorder();
    await _recorder?.startRecorder(
      toFile: _filePath,
      codec: Codec.aacMP4, // Specify the codec
    );

    setState(() {
      _isRecording = true;
    });
  }

  Future<void> stopListeningAndRecording() async {
    print("stop");
    // Stop STT
    try {
      if (_isListening) {
        await _speech.stop();
        await _recorder?.stopRecorder();
        setState(() {
          _isListening = false;
          _isRecording = false;
        });

        // Upload the recorded file
        await uploadFile(File(_filePath));
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> handleRecordButton() async {
    if (_isListening) {
      _isClicked = false;
      await stopListeningAndRecording();
    } else {
      _isClicked = true;
      await startListeningAndRecording();
    }
  }

  Future<void> uploadFile(File file) async {
    try {
      final String result =
          await platform.invokeMethod('uploadFile', file.path);
      setState(() {
        _response = result;
      });
    } on PlatformException catch (e) {
      setState(() {
        _response = "Failed to upload file: '${e.message}'.";
      });
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _recorder?.closeRecorder();
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
            '다중 화자 분류 및 인식',
            style: TextStyle(
                color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Container(
            color: Colors.white,
            height: 25.0,
          ),
          if (_isCameraAvailable &&
              _cameraController?.value.isInitialized == true)
            SizedBox(
              height: 282,
              child: CameraPreview(_cameraController!),
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
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.white.withOpacity(0.7),
            child: SingleChildScrollView(
              child: Text(
                _text,
                style: TextStyle(fontSize: 18),
              ),
            ),
          ),
          Container(
            width: double.infinity,
            color: Color(0xFFFFBEC1),
            padding: EdgeInsets.all(10),
            child: Center(
              child: Text(
                '음성 기록',
                style: TextStyle(
                    color: Colors.black,
                    fontSize: 25,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Container(
            color: Color(0x10FFBEC1),
            width: double.infinity,
            height: 250,
            padding: EdgeInsets.all(16),
            child: Text(
              _response,
              style: TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 0),
          Container(
            color: Colors.white, // White background for the row
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.center,
                    child: Container(
                      width: 161,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Color(0xFFFFBEC1),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Center(
                        child: Text(
                          '저장하기',
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
                ),
                SizedBox(width: 0),
                FloatingActionButton(
                  onPressed: handleRecordButton,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  highlightElevation: 0,
                  focusElevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(0)),
                  child: _isClicked
                      ? Icon(Icons.stop, size: 48)
                      : Image.asset('assets/record.png', width: 48, height: 48),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
