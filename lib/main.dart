import 'package:flutter/material.dart';
import 'package:daily_inc_timer_flutter/src/views/daily_things_view.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Daily Inc Timer',
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.blue,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blueGrey,
        ),
      ),
      home: const DailyThingsView(),
    );
  }
}
