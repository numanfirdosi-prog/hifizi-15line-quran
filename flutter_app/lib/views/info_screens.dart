import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/static_content.dart';

/// Email address that receives all bug reports from the app.
const String supportEmail = 'numanfirdosi@gmail.com';

/// Frequently asked questions.
class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Questions & FAQ')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          for (final faq in faqs)
            Card(
              color: theme.colorScheme.surface,
              margin: const EdgeInsets.only(bottom: 8),
              child: ExpansionTile(
                title: Text(
                  faq.q,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Text(faq.a, style: theme.textTheme.bodyMedium),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// About the app and licenses.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  Future<void> _reportIssue(BuildContext context) async {
    final controller = TextEditingController();
    final description = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Report an Issue'),
        content: TextField(
          controller: controller,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: 'Masle ki tafseel likhein…',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(ctx).pop(controller.text.trim()),
            child: const Text('Send'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (description == null || description.isEmpty) return;
    final uri = Uri(
      scheme: 'mailto',
      path: supportEmail,
      queryParameters: {
        'subject': 'Nur-ul-Quran Bug Report',
        'body': description,
      },
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Email app nahi khul saki. Barah-e-karam $supportEmail par email karein.'),
          action: SnackBarAction(
            label: 'Copy',
            onPressed: () =>
                Clipboard.setData(const ClipboardData(text: supportEmail)),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('About & Licenses')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: cs.surface,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: cs.primary,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(
                      Icons.menu_book,
                      size: 40,
                      color: cs.onPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'نور القرآن',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: cs.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Nur-ul-Quran',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Version 1.0.12',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _section(context, 'App ke baare me', aboutIntro),
          _section(context, 'Khaas features', aboutFeatures),
          _section(context, 'Data sources', aboutSources),
          _section(context, 'Licenses', aboutLicenses),
          const SizedBox(height: 4),
          Card(
            color: cs.surface,
            child: ListTile(
              leading: Icon(Icons.bug_report_outlined, color: cs.primary),
              title: const Text('Report an Issue'),
              subtitle:
                  const Text('Koi masla ho to humein email karein'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _reportIssue(context),
            ),
          ),
          const SizedBox(height: 4),
          Card(
            color: cs.surface,
            child: ListTile(
              leading: Icon(Icons.email_outlined, color: cs.primary),
              title: const Text('Contact'),
              subtitle: const Text(supportEmail),
              trailing: IconButton(
                icon: const Icon(Icons.copy_outlined),
                onPressed: () {
                  Clipboard.setData(
                      const ClipboardData(text: supportEmail));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Email address copy ho gaya')),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(BuildContext context, String title, String body) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.surface,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(body, style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

/// Privacy policy.
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: theme.colorScheme.surface,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(privacyText, style: theme.textTheme.bodyMedium),
            ),
          ),
        ],
      ),
    );
  }
}
