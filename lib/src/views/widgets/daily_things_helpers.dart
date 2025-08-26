import 'dart:convert';
import 'dart:io';
import 'package:daily_inc/src/models/daily_thing.dart';
import 'package:daily_inc/src/models/item_type.dart';
import 'package:daily_inc/src/theme/color_palette.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

/// Pure helper to compute the next undone index in a displayed list.
int getNextUndoneIndex(List<DailyThing> items) {
  for (int i = 0; i < items.length; i++) {
    final item = items[i];
    if (item.itemType == ItemType.check && !item.completedForToday) {
      return i;
    } else if (item.itemType == ItemType.reps) {
      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);
      final hasActualValueToday = item.history.any((entry) {
        final entryDate =
            DateTime(entry.date.year, entry.date.month, entry.date.day);
        return entryDate == todayDate && entry.actualValue != null;
      });
      if (!hasActualValueToday) {
        return i;
      }
    } else if (item.itemType == ItemType.minutes) {
      if (!item.completedForToday) {
        return i;
      }
    }
  }
  return -1;
}

/// Show a generic snackbar with theme-aware background.
void showThemedSnackBar({
  required BuildContext context,
  required String message,
  Duration duration = const Duration(seconds: 2),
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      duration: duration,
      backgroundColor: Theme.of(context).snackBarTheme.backgroundColor,
      behavior: SnackBarBehavior.floating,
    ),
  );
}

/// Show delete confirmation dialog and return true if confirmed.
Future<bool> confirmDeleteDialog(BuildContext context, String name) async {
  final bool? shouldDelete = await showDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text(
            'Are you sure you want to delete "$name"? This cannot be undone.'),
        actions: <Widget>[
          TextButton(
            child: const Text('Cancel',
                style: TextStyle(color: ColorPalette.warningOrange)),
            onPressed: () {
              Navigator.of(context).pop(false);
            },
          ),
          TextButton(
            child: const Text('Delete',
                style: TextStyle(color: ColorPalette.warningOrange)),
            onPressed: () {
              Navigator.of(context).pop(true);
            },
          ),
        ],
      );
    },
  );
  return shouldDelete == true;
}

/// Save a structured JSON to a chosen location (desktop shows path, mobile returns null on success).
Future<bool> saveJsonToFile({
  required BuildContext context,
  required Map<String, dynamic> json,
  String defaultFileName = 'daily_inc_history.json',
}) async {
  try {
    final jsonString = const JsonEncoder.withIndent('  ').convert(json);
    final bytes = utf8.encode(jsonString);
    
    String? outputFile;
    
    if (Platform.isLinux) {
      // On Linux, use ANY file type
      outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Data',
        fileName: defaultFileName,
        type: FileType.any,
        bytes: bytes,
      );
    } else {
      // On other platforms, use custom type with JSON extension
      outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Data',
        fileName: defaultFileName,
        allowedExtensions: const ['json'],
        type: FileType.custom,
        bytes: bytes,
      );
    }
    
    if (outputFile != null || Platform.isAndroid || Platform.isIOS) {
      showThemedSnackBar(
          context: context, message: 'File saved successfully');
      return true;
    }
    return false;
  } catch (_) {
    return false;
  }
}
