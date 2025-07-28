import 'package:daily_inc/src/data/data_manager.dart';
import 'package:daily_inc/src/models/daily_thing.dart';
import 'package:daily_inc/src/models/item_type.dart';
import 'package:daily_inc/src/theme/color_palette.dart';
import 'package:daily_inc/src/views/daily_thing_item.dart';
import 'package:flutter/material.dart';

class HelpView extends StatelessWidget {
  const HelpView({super.key});

  @override
  Widget build(BuildContext context) {
    // A dummy item for demonstration purposes
    final dummyItem = DailyThing(
      id: 'dummy',
      name: 'Example Task',
      itemType: ItemType.minutes,
      startValue: 5,
      endValue: 25,
      duration: 30,
      icon: '🏃',
      history: [],
      startDate: DateTime.now(),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Help'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: <Widget>[
          Text(
            'App Bar',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Material(
            elevation: 4,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).appBarTheme.backgroundColor ??
                    Theme.of(context).primaryColor,
                border: Border.all(width: 0.5, color: Colors.white),
              ),
              height: kToolbarHeight,
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  Text(
                    'Daily Inc',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: (Theme.of(context)
                                      .appBarTheme
                                      .titleTextStyle
                                      ?.color ??
                                  Theme.of(context)
                                      .primaryTextTheme
                                      .titleLarge
                                      ?.color) ??
                              Colors.white,
                        ),
                  ),
                  const Spacer(),
                  IconButton(
                      icon: const Icon(Icons.visibility, color: Colors.white),
                      onPressed: null,
                      tooltip: 'Show/Hide Due Items'),
                  IconButton(
                      icon: const Icon(Icons.filter_list, color: Colors.white),
                      onPressed: null,
                      tooltip: 'Hide Completed Items'),
                  IconButton(
                      icon: const Icon(Icons.add, color: Colors.white),
                      onPressed: null,
                      tooltip: 'Add Item'),
                  IconButton(
                      icon: const Icon(Icons.settings, color: Colors.white),
                      onPressed: null,
                      tooltip: 'Settings'),
                  IconButton(
                      icon: const Icon(Icons.help, color: Colors.white),
                      onPressed: null,
                      tooltip: 'Help'),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.save, color: Colors.white),
                    tooltip: 'Save/Load Menu',
                    itemBuilder: (BuildContext context) =>
                        <PopupMenuEntry<String>>[],
                    enabled: false,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const ListTile(
            leading: Icon(Icons.visibility),
            title: Text('Show/Hide Due Items'),
            subtitle:
                Text('Toggle between showing all items and only due items.'),
          ),
          const ListTile(
            leading: Icon(Icons.filter_list),
            title: Text('Hide Completed Items'),
            subtitle: Text('Toggle to hide or show completed tasks.'),
          ),
          const ListTile(
            leading: Icon(Icons.add),
            title: Text('Add Item'),
            subtitle: Text('Add a new daily task.'),
          ),
          const ListTile(
            leading: Icon(Icons.settings),
            title: Text('Settings Icon'),
            subtitle: Text('Access settings to configure app behavior.'),
          ),
          const ListTile(
            leading: Icon(Icons.help),
            title: Text('Help'),
            subtitle: Text('You are here!'),
          ),
          const ListTile(
            leading: Icon(Icons.save),
            title: Text('Save/Load Menu'),
            subtitle: Text(
                'Access options to save your data to a file or load data from a file.'),
          ),
          const Divider(height: 32),
          Text(
            'Understanding a Daily Task',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          const Text(
              "Here is an example of a task. Tap it to reveal more controls. Long hold and drag to reorder tasks"),
          const SizedBox(height: 16),
          // This is a non-functional representation for display only.
          DailyThingItem(
            item: dummyItem,
            dataManager: DataManager(), // Dummy manager
            onEdit: (_) {},
            onDelete: (_) {},
            onDuplicate: (_) {},
            showFullscreenTimer: (_) {},
            showRepsInputDialog: (_) {},
            checkAndShowCompletionSnackbar: () {},
            isExpanded: true, // Keep it expanded for the help view
            onExpansionChanged: (_) {},
            allTasksCompleted: false,
          ),
          const SizedBox(height: 24),
          ListTile(
            leading: Icon(Icons.close, color: ColorPalette.warningOrange),
            title: const Text('Completion Status'),
            subtitle: const Text(
                'Shows if a task is done for today. Starts as a red cross and turns into a green checkmark upon completion.'),
          ),
          ListTile(
            leading:
                Text(dummyItem.icon!, style: const TextStyle(fontSize: 24)),
            title: const Text('Icon & Name'),
            subtitle: const Text('The emoji and name you chose for your task.'),
          ),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: ColorPalette.warningOrange,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '5m',
                style:
                    TextStyle(color: Theme.of(context).colorScheme.onPrimary),
              ),
            ),
            title: const Text('Action Button'),
            subtitle: const Text(
                'Tap here to complete the task. For timers, it starts the countdown. For reps, it opens an input dialog. For checks, it toggles completion.'),
          ),
          const SizedBox(height: 16),
          const Divider(height: 32),
          Text(
            'Expanded Controls',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          const ListTile(
            leading: Icon(Icons.auto_graph),
            title: Text('View Stats'),
            subtitle:
                Text('Opens a graph to visualize your progress over time.'),
          ),
          const ListTile(
            leading: Icon(Icons.edit),
            title: Text('Edit'),
            subtitle: Text('Modify the task\'s properties.'),
          ),
          const ListTile(
            leading: Icon(Icons.content_copy),
            title: Text('Duplicate'),
            subtitle: Text('Creates a copy of the task.'),
          ),
          const ListTile(
            leading: Icon(Icons.delete),
            title: Text('Delete'),
            subtitle: Text('Permanently removes the task and its history.'),
          ),
          const Divider(height: 32),
          Text(
            'Settings',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
