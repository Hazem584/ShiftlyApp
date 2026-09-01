import 'package:flutter/material.dart';

class ShiftlyApp extends StatelessWidget {
  const ShiftlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Shiftly',
      home: Scaffold(body: Center(child: Text('Hello, Shiftly!'))),
    );
  }
}
