import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io' show Platform, exit;
import 'package:daily_inc/src/views/daily_things_view.dart';
import 'package:daily_inc/src/data/data_manager.dart';
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

      // Initialize data manager and load initial data
      final dataManager = DataManager();
      await dataManager.loadData();

      runApp(const MyApp());
      log.info("App started successfully");
    } catch (e, stack) {
      log.severe('Error during app initialization', e, stack);
      rethrow;
    }
  }, (error, stackTrace) {
    log.severe('Uncaught error', error, stackTrace);
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: FocusNode(),
      onKeyEvent: (KeyEvent event) {
        if (HardwareKeyboard.instance.isControlPressed &&
            event.logicalKey == LogicalKeyboardKey.keyQ) {
          if (event is KeyDownEvent) {
            // Handle quit action based on platform
            if (Platform.isAndroid || Platform.isIOS) {
              SystemNavigator.pop();
            } else if (Platform.isWindows ||
                Platform.isLinux ||
                Platform.isMacOS) {
              exit(0);
            }
          }
        }
      },
      child: MaterialApp(
        title: 'Daily Increment Timer',
        theme: ThemeData.light(),
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const DailyThingsView(),
      ),
    );
  }
}
