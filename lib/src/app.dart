import 'package:clicky/src/features/camera/presentation/camera_screen.dart';
import 'package:flutter/material.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static void initialize() {
    runApp(const MyApp());
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Clicky',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: CameraScreen(),
    );
  }
}
