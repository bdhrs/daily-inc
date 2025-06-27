import 'package:flutter/material.dart';
import 'package:daily_inc/src/views/daily_things_view.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Daily Inc',
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.blue,
      ),
      home: const DailyThingsView(),
    );
  }
}
