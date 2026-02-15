import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io' show Platform, exit;
import 'package:daily_inc/src/views/daily_things_view.dart';
import 'package:daily_inc/src/data/data_manager.dart';
import 'package:daily_inc/src/services/notification_service.dart';
import 'package:daily_inc/src/theme/app_theme.dart';
import 'package:logging/logging.dart';

final _notificationService = NotificationService();
final _dataManager = DataManager();
final _navigatorKey = GlobalKey<NavigatorState>();

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

      // Initialize notification service
      await _notificationService.initialize(navigatorKey: _navigatorKey);
      await _notificationService.requestPermissions();

      // Load data and reschedule notifications
      final items = await _dataManager.loadData();
      await _notificationService.rescheduleAllNotifications(items);

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

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _rescheduleNotifications();
    }
  }

  Future<void> _rescheduleNotifications() async {
    try {
      final items = await _dataManager.loadData();
      await _notificationService.rescheduleAllNotifications(items);
    } catch (e) {
      // ignore: avoid_print
      print('Error rescheduling notifications: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
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
        navigatorKey: _navigatorKey,
        home: const DailyThingsView(),
      ),
    );
  }
}
