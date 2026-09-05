import 'package:flutter/material.dart';
import 'package:shiftly/features/home/presentation/home_screen.dart';

class ShiftlyApp extends StatelessWidget {
  const ShiftlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Shiftly',
      home: Scaffold(body: HomeScreen()),
    );
  }
}
