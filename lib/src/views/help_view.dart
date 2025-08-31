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
      category: 'Exercise',
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help'),
        actions: const [],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: <Widget>[
          Text(
            'App bar',
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
                      icon: const Icon(Icons.filter_list, color: Colors.white),
                      onPressed: null,
                      tooltip: 'Show/Hide Completed Items'),
                  IconButton(
                      icon: const Icon(Icons.expand_more, color: Colors.white),
                      onPressed: null,
                      tooltip: 'Expand/Collapse all items'),
                  IconButton(
                      icon: const Icon(Icons.add, color: Colors.white),
                      onPressed: null,
                      tooltip: 'Add an item'),
                  IconButton(
                      icon: const Icon(Icons.bar_chart, color: Colors.white),
                      onPressed: null,
                      tooltip: 'Category Graphs'),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.white),
                    tooltip: 'More options',
                    itemBuilder: (BuildContext context) =>
                        <PopupMenuEntry<String>>[
                      PopupMenuItem<String>(
                        value: 'toggle_due',
                        child: Row(
                          children: const [
                            Icon(Icons.visibility),
                            SizedBox(width: 8),
                            Text('Show/Hide Due Items'),
                          ],
                        ),
                      ),
                      const PopupMenuItem<String>(
                        value: 'settings',
                        child: Row(
                          children: [
                            Icon(Icons.settings),
                            SizedBox(width: 8),
                            Text('Settings'),
                          ],
                        ),
                      ),
                      const PopupMenuItem<String>(
                        value: 'help',
                        child: Row(
                          children: [
                            Icon(Icons.help),
                            SizedBox(width: 8),
                            Text('Help'),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
                      const PopupMenuItem<String>(
                        value: 'load_history',
                        child: Row(
                          children: [
                            Icon(Icons.folder_open),
                            SizedBox(width: 8),
                            Text('Load History'),
                          ],
                        ),
                      ),
                      const PopupMenuItem<String>(
                        value: 'save_history',
                        child: Row(
                          children: [
                            Icon(Icons.save_alt),
                            SizedBox(width: 8),
                            Text('Save History'),
                          ],
                        ),
                      ),
                    ],
                    enabled: false,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const ListTile(
            leading: Icon(Icons.filter_list),
            title: Text('Show/Hide Completed Items'),
            subtitle: Text('Toggle whether completed items are hidden.'),
          ),
          const ListTile(
            leading: Icon(Icons.expand_more),
            title: Text('Expand/Collapse all items'),
            subtitle: Text(
                'Expand or collapse all visible items to show or hide their details.'),
          ),
          const ListTile(
            leading: Icon(Icons.add),
            title: Text('Add an item'),
            subtitle: Text('Create a new daily thing.'),
          ),
          const ListTile(
            leading: Icon(Icons.bar_chart),
            title: Text('Category Graphs'),
            subtitle: Text('View graphs aggregated by category.'),
          ),

          const Divider(height: 32),
          Text(
            'Overflow menu',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Material(
            elevation: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              color: Theme.of(context).cardColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  ListTile(
                    leading: Icon(Icons.visibility),
                    title: Text('Show/Hide Due Items'),
                    subtitle: Text(
                        'Toggle between all items or only those due today.'),
                  ),
                  ListTile(
                    leading: Icon(Icons.settings),
                    title: Text('Settings'),
                    subtitle: Text('Configure app behavior and preferences.'),
                  ),
                  ListTile(
                    leading: Icon(Icons.help),
                    title: Text('Help'),
                    subtitle: Text('You are here!'),
                  ),
                  ListTile(
                    leading: Icon(Icons.folder_open),
                    title: Text('Load History'),
                    subtitle:
                        Text('Load previously exported data from a JSON file.'),
                  ),
                  ListTile(
                    leading: Icon(Icons.save_alt),
                    title: Text('Save History'),
                    subtitle: Text('Export your data to a JSON file.'),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 32),
          Text(
            'Understanding a Daily Task',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          const Text(
              "Here is an example of a task. \n\n- Tap it to reveal more controls. \n\n- Long hold and drag to reorder tasks. \n\n- Swipe right to snooze a task until tomorrow. "),
          const SizedBox(height: 8),
          const SizedBox(height: 16),
          // This is a non-functional representation for display only.
          DailyThingItem(
            item: dummyItem,
            dataManager: DataManager(), // Dummy manager
            onEdit: (_) {},
            onDelete: (_) {},
            onDuplicate: (_) {},
            onConfirmSnooze: (_) => Future.value(false),
            showFullscreenTimer: (item, {startInOvertime = false}) {},
            showRepsInputDialog: (_) {},
            showPercentageInputDialog: (_) {},
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
            leading: Icon(Icons.timelapse),
            title: Text('Target progression and Category'),
            subtitle: Text(
                '5m→25m (Exercise) Shows the start and end values and category'),
          ),
          const ListTile(
            leading: Icon(Icons.auto_graph),
            title: Text('View Stats'),
            subtitle: Text('Shows your progress over time for this task.'),
          ),
          const ListTile(
            leading: Icon(Icons.history),
            title: Text('Edit History'),
            subtitle: Text('Manually edit or view the history of this task.'),
          ),
          const ListTile(
            leading: Icon(Icons.note_add_outlined),
            title: Text('Edit Note'),
            subtitle: Text('Add or edit a note for this task.'),
          ),
          const ListTile(
            leading: Icon(Icons.pause),
            title: Text('Pause Increments'),
            subtitle: Text(
                'Temporarily pause the automatic incrementing of this task\'s target value.'),
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
        ],
      ),
    );
  }
}
