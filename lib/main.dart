import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:daily_inc/src/views/daily_things_view.dart';
import 'package:daily_inc/src/services/notification_service.dart';
import 'package:daily_inc/src/theme/app_theme.dart';
import 'package:logging/logging.dart';

void main() async {
  final log = Logger('main');
  runZonedGuarded<Future<void>>(() async {
    try {
      WidgetsFlutterBinding.ensureInitialized();

      // Setup logging
      Logger.root.level = Level.ALL;
      Logger.root.onRecord.listen((record) {
        // ignore: avoid_print
        print('${record.level.name}: ${record.time}: ${record.message}');
        if (record.error != null) {
          // ignore: avoid_print
          print('Error: ${record.error}');
        }
        if (record.stackTrace != null) {
          // ignore: avoid_print
          print('StackTrace: ${record.stackTrace}');
        }
      });

      log.info("App starting");

      final notificationService = NotificationService();
      await notificationService.init();
      await notificationService.requestPermissions();
      runApp(const MyApp());
      log.info("App started successfully");
    } catch (e, stack) {
      log.severe('Error during app initialization', e, stack);
    }
  }, (error, stack) {
    log.severe('Unhandled error in zone', error, stack);
  });

  // Catch Flutter framework errors
  FlutterError.onError = (FlutterErrorDetails details) {
    log.severe('Flutter error caught', details.exception, details.stack);
  };

  // Catch other unhandled errors
  PlatformDispatcher.instance.onError = (error, stack) {
    log.severe('Platform error caught', error, stack);
    return true;
  };
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Daily Inc',
      theme: AppTheme.darkTheme,
      home: const DailyThingsView(),
    );
  }
}
