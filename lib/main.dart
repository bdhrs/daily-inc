import 'package:flutter/material.dart';
import 'package:daily_inc/src/views/daily_things_view.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:daily_inc/src/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().init();
  await NotificationService().requestPermissions();
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
        textTheme: GoogleFonts.interTextTheme(
          ThemeData.dark().textTheme,
        ),
      ),
      home: const DailyThingsView(),
    );
  }
}
