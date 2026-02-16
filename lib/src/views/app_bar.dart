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
import 'dart:io';
import 'dart:async';

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
  final bool showArchivedItems;
  final VoidCallback onShowAboutDialog;
  final VoidCallback onToggleShowOnlyDueItems;
  final VoidCallback onToggleShowArchivedItems;
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
    required this.showArchivedItems,
    required this.onShowAboutDialog,
    required this.onToggleShowOnlyDueItems,
    required this.onToggleShowArchivedItems,
    required this.log,
  });

  @override
  State<DailyThingsAppBar> createState() => _DailyThingsAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _DailyThingsAppBarState extends State<DailyThingsAppBar> {
  final UpdateService _updateService = UpdateService();

  Future<void> _handleUpdate() async {
    if (Platform.isAndroid) {
      final hasPermission = await _updateService.hasInstallPermission();
      if (!hasPermission) {
        if (mounted) {
          final bool? proceed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Update Permission Required'),
              content: const Text(
                  'To install updates automatically, Daily Inc needs permission to install unknown apps. \n\nWould you like to grant this permission now, or manually download from the Release Page?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Release Page'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Grant Permission'),
                ),
              ],
            ),
          );

          if (proceed == true) {
            final granted = await _updateService.requestInstallPermission();
            if (granted) {
              _startAutomatedUpdate();
            } else {
              _openReleasePage();
            }
          } else if (proceed == false) {
            _openReleasePage();
          }
        }
      } else {
        _startAutomatedUpdate();
      }
    } else {
      _openReleasePage();
    }
  }

  void _startAutomatedUpdate() async {
    File? apkFile;
    try {
      if (!mounted) return;

      apkFile = await _downloadWithProgress();
      if (apkFile != null) {
        if (mounted) Navigator.of(context).pop(); // Close progress dialog
        await _updateService.installUpdate(apkFile);
      }
    } catch (e) {
      widget.log.severe('Automated update failed', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Installation failed: $e')),
        );
        _openReleasePage(); // Fallback to manual if automated fails
      }
    } finally {
      if (apkFile != null) {
        // Give the system installer time to read the file before deleting it
        Future.delayed(const Duration(seconds: 30)).then((_) async {
          await _updateService.deleteDownloadedUpdate(apkFile!);
        });
      }
    }
  }

  void _openReleasePage() async {
    try {
      final url = await _updateService.getReleasePageUrl();
      if (url != null) {
        if (await launchUrl(Uri.parse(url),
            mode: LaunchMode.externalApplication)) {
          widget.log.info('Opened Release Page: $url');
        } else {
          throw Exception('Could not launch browser');
        }
      }
    } catch (e) {
      widget.log.severe('Failed to open Release Page', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to open browser: $e')),
        );
      }
    }
  }

  Future<File?> _downloadWithProgress() async {
    return showDialog<File>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _DownloadProgressDialog(
        updateService: _updateService,
        log: widget.log,
      ),
    );
  }

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
            onPressed: _handleUpdate,
          ),
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
                      onDataRestored: widget.onRefreshDisplay,
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

class _DownloadProgressDialog extends StatefulWidget {
  final UpdateService updateService;
  final Logger log;

  const _DownloadProgressDialog({
    required this.updateService,
    required this.log,
  });

  @override
  State<_DownloadProgressDialog> createState() =>
      _DownloadProgressDialogState();
}

class _DownloadProgressDialogState extends State<_DownloadProgressDialog> {
  double _progress = 0;
  bool _cancelled = false;

  @override
  void initState() {
    super.initState();
    _startDownload();
  }

  void _startDownload() {
    widget.updateService
        .downloadUpdate(
      onProgress: (count, total) {
        if (total > 0 && !_cancelled && mounted) {
          setState(() {
            _progress = count / total;
          });
        }
      },
    )
        .then((file) {
      if (!_cancelled && mounted) {
        Navigator.of(context).pop(file);
      }
    }).catchError((e) {
      if (!_cancelled && mounted) {
        widget.log.severe('Download error', e);
        Navigator.of(context).pop(null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Download failed: $e')),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Downloading Update'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LinearProgressIndicator(value: _progress > 0 ? _progress : null),
          const SizedBox(height: 16),
          Text('${(_progress * 100).toStringAsFixed(1)}%'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            _cancelled = true;
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
