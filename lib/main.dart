import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'screens/project_list_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Camera Overlay App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: SafeArea(child: ProjectListScreen()),
      debugShowCheckedModeBanner: false,
    );
  }
}
