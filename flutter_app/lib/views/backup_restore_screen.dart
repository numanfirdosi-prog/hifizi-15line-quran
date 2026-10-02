import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../services/preferences_service.dart';

/// Export / import a JSON backup of all preferences, plus a danger-zone
/// full reset.
class BackupRestoreScreen extends StatelessWidget {
  const BackupRestoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Backup & Restore')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          // Export card.
          Card(
            color: theme.colorScheme.surface,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Export Backup',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Save all your bookmarks, notes and settings as a backup.',
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => _showExportDialog(context),
                    child: const Text('Export Backup JSON'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Import card.
          Card(
            color: theme.colorScheme.surface,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Import Backup',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text('Paste a previously exported backup JSON.'),
                  const SizedBox(height: 12),
                  const _ImportField(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Danger zone card.
          Card(
            color: theme.colorScheme.surface,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Danger Zone',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Reset everything to defaults. This cannot be undone.',
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    icon: Icon(
                      Icons.warning_amber_outlined,
                      color: theme.colorScheme.error,
                    ),
                    label: Text(
                      'Reset all data',
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: theme.colorScheme.error),
                    ),
                    onPressed: () => _confirmReset(context),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showExportDialog(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final json =
        Provider.of<PreferencesService>(context, listen: false).exportJson();
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Export Backup'),
        content: SizedBox(
          width: double.maxFinite,
          height: 320,
          child: SingleChildScrollView(child: SelectableText(json)),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: json));
              if (ctx.mounted) {
                Navigator.of(ctx).pop();
                messenger.showSnackBar(
                  const SnackBar(content: Text('Backup copied to clipboard')),
                );
              }
            },
            child: const Text('Copy'),
          ),
          TextButton(
            onPressed: () async {
              try {
                final dir = await getApplicationDocumentsDirectory();
                final file = File('${dir.path}/nur_al_quran_backup.json');
                await file.writeAsString(json);
                if (ctx.mounted) {
                  Navigator.of(ctx).pop();
                  messenger.showSnackBar(
                    SnackBar(content: Text('Saved to ${file.path}')),
                  );
                }
              } catch (e) {
                if (ctx.mounted) {
                  Navigator.of(ctx).pop();
                  messenger.showSnackBar(
                    SnackBar(content: Text('Save failed: $e')),
                  );
                }
              }
            },
            child: const Text('Save to file'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final prefs = Provider.of<PreferencesService>(context, listen: false);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset all data?'),
        content: const Text(
          'All settings, bookmarks, notes and saved data will be erased.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Reset',
              style: TextStyle(color: Theme.of(ctx).colorScheme.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await prefs.resetAll();
      messenger.showSnackBar(
        const SnackBar(content: Text('All data has been reset')),
      );
    }
  }
}

/// Import card body: multiline JSON field + Import button. Stateful to hold
/// the text controller while [BackupRestoreScreen] stays stateless.
class _ImportField extends StatefulWidget {
  const _ImportField();

  @override
  State<_ImportField> createState() => _ImportFieldState();
}

class _ImportFieldState extends State<_ImportField> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _controller,
          maxLines: 6,
          decoration: const InputDecoration(
            hintText: 'Paste backup JSON here',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: () async {
            final prefs =
                Provider.of<PreferencesService>(context, listen: false);
            final ok = await prefs.importJson(_controller.text.trim());
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(ok ? 'Imported' : 'Invalid backup')),
              );
            }
          },
          child: const Text('Import'),
        ),
      ],
    );
  }
}
