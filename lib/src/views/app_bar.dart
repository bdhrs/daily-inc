import 'package:daily_inc/src/models/daily_thing.dart';
import 'package:daily_inc/src/services/update_service.dart';
import 'package:daily_inc/src/theme/color_palette.dart';
import 'package:daily_inc/src/views/category_graph_view.dart';
import 'package:daily_inc/src/views/help_view.dart';
import 'package:daily_inc/src/views/settings_view.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:logging/logging.dart';

class DailyThingsAppBar extends StatefulWidget implements PreferredSizeWidget {
  final bool updateAvailable;
  final VoidCallback onOpenAddDailyItemPopup;
  final VoidCallback onRefreshHideWhenDoneSetting;
  final VoidCallback onRefreshDisplay;
  final VoidCallback onExpandAllVisibleItems;
  final Future<void> Function() onLoadHistoryFromFile;
  final Future<void> Function() onSaveHistoryToFile;
  final Future<void> Function() onLoadTemplateFromFile;
  final Future<void> Function() onSaveTemplateToFile;
  final VoidCallback onResetAllData;
  final List<DailyThing> dailyThings;
  final bool hideWhenDone;
  final bool allExpanded;
  final bool showOnlyDueItems;
  final bool showArchivedItems; // New parameter for showing archived items
  final VoidCallback onShowAboutDialog;
  final VoidCallback onToggleShowOnlyDueItems;
  final VoidCallback
      onToggleShowArchivedItems; // New parameter for toggle callback
  final Logger log;

  const DailyThingsAppBar({
    super.key,
    required this.updateAvailable,
    required this.onOpenAddDailyItemPopup,
    required this.onRefreshHideWhenDoneSetting,
    required this.onRefreshDisplay,
    required this.onExpandAllVisibleItems,
    required this.onLoadHistoryFromFile,
    required this.onSaveHistoryToFile,
    required this.onLoadTemplateFromFile,
    required this.onSaveTemplateToFile,
    required this.onResetAllData,
    required this.dailyThings,
    required this.hideWhenDone,
    required this.allExpanded,
    required this.showOnlyDueItems,
    required this.showArchivedItems, // New parameter
    required this.onShowAboutDialog,
    required this.onToggleShowOnlyDueItems,
    required this.onToggleShowArchivedItems, // New parameter
    required this.log,
  });

  @override
  State<DailyThingsAppBar> createState() => _DailyThingsAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _DailyThingsAppBarState extends State<DailyThingsAppBar> {
  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text('Daily Inc'),
      actions: [
        if (widget.updateAvailable)
          IconButton(
            tooltip: 'Download the latest release',
            icon: const Icon(
              Icons.download,
              color: ColorPalette.primaryBlue,
            ),
            onPressed: () async {
              // Get the latest release URL and open it in browser
              final updateService = UpdateService();
              final url = await updateService.getDownloadUrl();
              if (url != null) {
                // Open the URL in browser
                if (await launchUrl(Uri.parse(url))) {
                  // Successfully opened URL
                  widget.log.info('Opened download URL in browser: $url');
                } else {
                  // Failed to open URL
                  widget.log.warning('Could not launch download URL: $url');
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content:
                            Text('Could not open download page in browser.'),
                        duration: Duration(seconds: 3),
                      ),
                    );
                  }
                }
              } else {
                // Could not get download URL
                widget.log.warning('Could not get download URL from GitHub');
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Could not get download URL.'),
                      duration: Duration(seconds: 3),
                    ),
                  );
                }
              }
            },
          ),
        // Essential actions that should always be visible
        IconButton(
          tooltip: widget.hideWhenDone
              ? 'Show Completed Items'
              : 'Hide Completed Items',
          icon: Icon(
            widget.hideWhenDone ? Icons.filter_list : Icons.filter_list_off,
          ),
          onPressed: () async {
            final newValue = !widget.hideWhenDone;
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool('hideWhenDone', newValue);
            widget.onRefreshHideWhenDoneSetting();
            widget.onRefreshDisplay();
          },
        ),
        IconButton(
          tooltip:
              widget.allExpanded ? 'Collapse all items' : 'Expand all items',
          icon: Icon(
            widget.allExpanded ? Icons.expand_less : Icons.expand_more,
          ),
          onPressed: widget.onExpandAllVisibleItems,
        ),
        IconButton(
          tooltip: 'Add an item',
          icon: const Icon(Icons.add),
          onPressed: widget.onOpenAddDailyItemPopup,
        ),
        // Category Graphs button moved from overflow menu
        IconButton(
          tooltip: 'Category Graphs',
          icon: const Icon(Icons.bar_chart),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    CategoryGraphView(dailyThings: widget.dailyThings),
              ),
            );
          },
        ),
        // All other actions in a single overflow menu to prevent title cropping
        PopupMenuButton<String>(
          tooltip: 'More options',
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            switch (value) {
              case 'toggle_due':
                widget.onToggleShowOnlyDueItems();
                widget.onRefreshDisplay();
                break;
              case 'toggle_archived':
                widget.onToggleShowArchivedItems();
                widget.onRefreshDisplay();
                break;
              case 'settings':
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SettingsView(
                      onResetAllData: widget.onResetAllData,
                    ),
                  ),
                ).then((_) => widget.onRefreshHideWhenDoneSetting());
                break;
              case 'help':
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HelpView(),
                  ),
                );
                break;
              case 'load_history':
                widget.onLoadHistoryFromFile();
                break;
              case 'save_history':
                widget.onSaveHistoryToFile();
                break;
              case 'load_template':
                widget.onLoadTemplateFromFile();
                break;
              case 'save_template':
                widget.onSaveTemplateToFile();
                break;
              case 'about':
                widget.onShowAboutDialog();
                break;
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem<String>(
              value: 'toggle_due',
              child: Row(
                children: [
                  Icon(widget.showOnlyDueItems
                      ? Icons.visibility
                      : Icons.visibility_off),
                  const SizedBox(width: 8),
                  Text(widget.showOnlyDueItems
                      ? 'Show All Items'
                      : 'Only Show Today\'s Items'),
                ],
              ),
            ),
            PopupMenuItem<String>(
              value: 'toggle_archived',
              child: Row(
                children: [
                  Icon(widget.showArchivedItems
                      ? Icons.inventory_2
                      : Icons.inventory),
                  const SizedBox(width: 8),
                  Text(widget.showArchivedItems
                      ? 'Show Active Items'
                      : 'Show Archived Items'),
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
            const PopupMenuDivider(),
            const PopupMenuItem<String>(
              value: 'load_template',
              child: Row(
                children: [
                  Icon(Icons.folder_open),
                  SizedBox(width: 8),
                  Text('Load Template'),
                ],
              ),
            ),
            const PopupMenuItem<String>(
              value: 'save_template',
              child: Row(
                children: [
                  Icon(Icons.save_alt),
                  SizedBox(width: 8),
                  Text('Save Template'),
                ],
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem<String>(
              value: 'about',
              child: Row(
                children: [
                  Icon(Icons.info),
                  SizedBox(width: 8),
                  Text('About'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
