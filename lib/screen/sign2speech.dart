import 'dart:convert';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class CameraPage extends StatefulWidget {
  @override
  _CameraPageState createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  CameraController? _controller;
  String _textFromServer = '';

  @override
  void initState() {
    super.initState();
    initializeCamera();
  }

  Future<void> initializeCamera() async {
    final cameras = await availableCameras();
    _controller = CameraController(cameras[0], ResolutionPreset.high);
    await _controller?.initialize();
    setState(() {});
  }

  Future<void> captureAndSendImage() async {
    if (_controller != null && _controller!.value.isInitialized) {
      final image = await _controller!.takePicture();
      final bytes = await image.readAsBytes();

      // Send the image to the server
      final response = await http.post(
        Uri.parse('https://yourserver.com/upload'),
        headers: {"Content-Type": "application/octet-stream"},
        body: bytes,
      );

      // Fetch the text result
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        setState(() {
          _textFromServer = result['text'];
        });
      } else {
        // Handle error
      }
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
          if (_controller != null && _controller!.value.isInitialized)
            AspectRatio(
              aspectRatio: _controller!.value.aspectRatio,
              child: CameraPreview(_controller!),
            ),
          ElevatedButton(
            onPressed: captureAndSendImage,
            child: Text('Capture and Send Image'),
          ),
          if (_textFromServer.isNotEmpty)
            Text('Text from server: $_textFromServer'),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}
