import 'package:daily_inc/src/data/data_manager.dart';
import 'package:daily_inc/src/models/daily_thing.dart';
import 'package:daily_inc/src/models/history_entry.dart';
import 'package:daily_inc/src/models/item_type.dart';
import 'package:daily_inc/src/theme/color_palette.dart';
import 'package:daily_inc/src/views/daily_thing_item.dart';
import 'package:flutter/material.dart';

class HelpView extends StatelessWidget {
  const HelpView({super.key});

  @override
  Widget build(BuildContext context) {
    // A dummy item for demonstration purposes with realistic history data
    final dummyItem = DailyThing(
      id: 'dummy',
      name: 'Example Task',
      itemType: ItemType.minutes,
      startValue: 5,
      endValue: 25,
      duration: 30,
      icon: '🏃',
      history: _createExampleHistory(),
      startDate: DateTime.now().subtract(const Duration(days: 30)),
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
                border: Border.all(
                    width: 0.5, color: Theme.of(context).colorScheme.onPrimary),
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
                              Theme.of(context).colorScheme.onPrimary,
                        ),
                  ),
                  const Spacer(),
                  // Download button (shown when update available)
                  IconButton(
                      icon: Icon(
                        Icons.download,
                        color: ColorPalette.primaryBlue,
                      ),
                      onPressed: null,
                      tooltip: 'Download the latest release'),
                  IconButton(
                      icon: Icon(
                        Icons.filter_list_off,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                      onPressed: null,
                      tooltip: 'Show Completed Items'),
                  IconButton(
                      icon: Icon(
                        Icons.expand_less,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                      onPressed: null,
                      tooltip: 'Collapse all items'),
                  IconButton(
                      icon: Icon(
                        Icons.add,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                      onPressed: null,
                      tooltip: 'Add an item'),
                  IconButton(
                      icon: Icon(
                        Icons.bar_chart,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                      onPressed: null,
                      tooltip: 'Category Graphs'),
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                    tooltip: 'More options',
                    itemBuilder: (BuildContext context) =>
                        <PopupMenuEntry<String>>[
                      PopupMenuItem<String>(
                        value: 'toggle_due',
                        child: Row(
                          children: [
                            Icon(
                              Icons.visibility_off,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Only Show Today\'s Items',
                              style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.onSurface),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'toggle_archived',
                        child: Row(
                          children: [
                            Icon(
                              Icons.inventory,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Show Active Items',
                              style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.onSurface),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'settings',
                        child: Row(
                          children: [
                            Icon(
                              Icons.settings,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Settings',
                              style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.onSurface),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'help',
                        child: Row(
                          children: [
                            Icon(
                              Icons.help,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Help',
                              style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.onSurface),
                            ),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
                      PopupMenuItem<String>(
                        value: 'load_history',
                        child: Row(
                          children: [
                            Icon(
                              Icons.folder_open,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Load History',
                              style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.onSurface),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'save_history',
                        child: Row(
                          children: [
                            Icon(
                              Icons.save_alt,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Save History',
                              style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.onSurface),
                            ),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
                      PopupMenuItem<String>(
                        value: 'load_template',
                        child: Row(
                          children: [
                            Icon(
                              Icons.folder_open,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Load Template',
                              style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.onSurface),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'save_template',
                        child: Row(
                          children: [
                            Icon(
                              Icons.save_alt,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Save Template',
                              style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.onSurface),
                            ),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
                      PopupMenuItem<String>(
                        value: 'about',
                        child: Row(
                          children: [
                            Icon(
                              Icons.info,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'About',
                              style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.onSurface),
                            ),
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
          ListTile(
            leading: Icon(
              Icons.download,
              color: ColorPalette.primaryBlue,
            ),
            title: const Text('Download Update'),
            subtitle:
                const Text('Download the latest app release when available.'),
          ),
          const ListTile(
            leading: Icon(Icons.filter_list_off),
            title: Text('Show Completed Items'),
            subtitle:
                Text('Currently showing completed items. Toggle to hide them.'),
          ),
          const ListTile(
            leading: Icon(Icons.expand_less),
            title: Text('Collapse all items'),
            subtitle: Text(
                'Currently expanded. Click to collapse all visible items to hide their details.'),
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
                    leading: Icon(Icons.visibility_off),
                    title: Text('Only Show Today\'s Items'),
                    subtitle: Text(
                        'Currently showing only items due today. Toggle to show all items.'),
                  ),
                  ListTile(
                    leading: Icon(Icons.inventory),
                    title: Text('Show Active Items'),
                    subtitle: Text(
                        'Currently showing active items. Toggle to show archived items.'),
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
                  Divider(height: 1),
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
                  Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.folder_open),
                    title: Text('Load Template'),
                    subtitle: Text(
                        'Load a template without history data from a JSON file.'),
                  ),
                  ListTile(
                    leading: Icon(Icons.save_alt),
                    title: Text('Save Template'),
                    subtitle: Text(
                        'Export your data without history to a JSON template file.'),
                  ),
                  Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.info),
                    title: Text('About'),
                    subtitle: Text('View information about the app.'),
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
            showFullscreenStopwatch: (_) {},
            showRepsInputDialog: (_) {},
            showPercentageInputDialog: (_) {},
            showTrendInputDialog: (_) {},
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
            leading: Icon(Icons.inventory),
            title: Text('Archive'),
            subtitle: Text(
                'Moves the task to archived items (hidden from main view).'),
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

  /// Creates realistic example history data for the help view
  /// Starting from 5 minutes, incrementing by 40 seconds (0.6667 minutes) each day
  /// with some skipped days to make it realistic
  List<HistoryEntry> _createExampleHistory() {
    final history = <HistoryEntry>[];
    final now = DateTime.now();
    final startDate = now.subtract(const Duration(days: 30));
    double currentValue = 5.0; // Start at 5 minutes
    const increment = 40.0 / 60.0; // 40 seconds = 0.6667 minutes

    for (int i = 0; i < 30; i++) {
      final date = startDate.add(Duration(days: i));

      // Skip some days to make it realistic (skip weekends occasionally)
      final isWeekend =
          date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
      final shouldSkip = (i % 7 == 0 && i > 0) || (isWeekend && i % 3 == 0);

      if (!shouldSkip) {
        // Add some variation - sometimes complete the full target, sometimes a bit less
        final completedValue = currentValue * (0.8 + 0.4 * (i % 5 / 5.0));

        history.add(HistoryEntry(
          date: date,
          targetValue: currentValue,
          doneToday: true,
          actualValue: completedValue,
          comment: i % 5 == 0 ? 'Good session!' : null,
        ));

        // Increment for next day
        currentValue += increment;
      } else {
        // Skipped day - no entry, but still increment target
        currentValue += increment;
      }
    }

    return history;
  }
}
