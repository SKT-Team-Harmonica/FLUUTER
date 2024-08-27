import 'package:flutter/material.dart';
import '../screen/sign2speech.dart';
import '../screen/speech2sign.dart';
import '../screen/multi.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '손말이음',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width; // Get screen width

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          const SizedBox(height: 30), // Add some spacing at the top
          Center(
            child: Image.asset(
              'assets/logo.png', // Path to your logo
              width: 173,
            ),
          ),
          const SizedBox(height: 30), // Space between logo and buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(
                width: screenWidth,
                height: 130,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) => CameraPage()));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(
                        0xffFFBEC1), // Set the button background color
                    foregroundColor: Colors.black, // Set the button text color
                    padding: EdgeInsets.symmetric(
                        horizontal: 25.0), // Padding from button edges
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero, // Remove border radius
                    ),
                    textStyle: const TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Inter',
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Image.asset(
                        'assets/logo1.png', // Path to your image
                        width: 100, // Set the height of the icon
                      ),
                      Text('수어 기반 음성 생성'),
                    ],
                  ),
                ),
              ),
            ],
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(
                width: screenWidth,
                height: 130,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) => VoicePage()));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(
                        0xffFF878C), // Set the button background color
                    foregroundColor: Colors.black, // Set the button text color
                    padding: EdgeInsets.symmetric(
                        horizontal: 25.0), // Padding from button edges
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero, // Remove border radius
                    ),
                    textStyle: const TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Inter',
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Image.asset(
                        'assets/logo2.png', // Path to your image
                        width: 100, // Set the height of the icon
                      ),
                      Text('음성 기반 수어 생성'),
                    ],
                  ),
                ),
              ),
            ],
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(
                width: screenWidth,
                height: 130,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) => MultiPage()));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(
                        0xffC4525A), // Set the button background color
                    foregroundColor: Colors.black, // Set the button text color
                    padding: EdgeInsets.symmetric(
                        horizontal: 25.0), // Padding from button edges
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero, // Remove border radius
                    ),
                    textStyle: const TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Inter',
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Image.asset(
                        'assets/logo3.png', // Path to your image
                        width: 100, // Set the height of the icon
                      ),
                      Text('다중 대화 기능'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
