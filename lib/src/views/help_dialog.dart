import 'package:flutter/material.dart';

class HelpDialog extends StatelessWidget {
  const HelpDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Help'),
      content: SingleChildScrollView(
        child: ListBody(
          children: <Widget>[
            const Row(
              children: [
                Icon(Icons.add),
                SizedBox(width: 8),
                Text('Add an item: Tap the "+" icon to add a new daily item.'),
              ],
            ),
            const Row(
              children: [
                Icon(Icons.settings),
                SizedBox(width: 8),
                Text(
                    'Settings: Tap the "Settings" icon to change app settings.'),
              ],
            ),
            const Row(
              children: [
                Icon(Icons.save),
                SizedBox(width: 8),
                Text(
                    'Save and Load History: Tap the "Save" icon to save or load history.'),
              ],
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('Close'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}
