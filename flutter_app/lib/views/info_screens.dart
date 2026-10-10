import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/static_content.dart';
import '../services/preferences_service.dart';

/// Email address that receives all bug reports from the app.
const String supportEmail = 'numanfirdosi@gmail.com';

/// Frequently asked questions.
class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUrdu = Provider.of<PreferencesService>(context).isUrdu;
    final dir = isUrdu ? TextDirection.rtl : TextDirection.ltr;
    return Scaffold(
      appBar:
          AppBar(title: Text(isUrdu ? 'سوالات و جوابات' : 'Questions & FAQ')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          for (final faq in faqs)
            Card(
              color: theme.colorScheme.surface,
              margin: const EdgeInsets.only(bottom: 8),
              child: ExpansionTile(
                title: Text(
                  isUrdu ? faq.qUr : faq.qEn,
                  textDirection: dir,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Text(
                      isUrdu ? faq.aUr : faq.aEn,
                      textDirection: dir,
                      style: theme.textTheme.bodyMedium,
                    ),
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
    final isUrdu =
        Provider.of<PreferencesService>(context, listen: false).isUrdu;
    final controller = TextEditingController();
    final description = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isUrdu ? 'مسئلہ رپورٹ کریں' : 'Report an Issue'),
        content: TextField(
          controller: controller,
          maxLines: 5,
          textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
          decoration: InputDecoration(
            hintText: isUrdu
                ? 'مسئلے کی تفصیل لکھیں…'
                : 'Describe the issue…',
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(isUrdu ? 'منسوخ کریں' : 'Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(ctx).pop(controller.text.trim()),
            child: Text(isUrdu ? 'بھیجیں' : 'Send'),
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
    // Launch directly: canLaunchUrl gives false negatives for mailto: URIs
    // with query parameters on some devices, so go straight to the email app.
    bool launched = false;
    try {
      launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      launched = false;
    }
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isUrdu
              ? 'ای میل ایپ نہیں کھل سکی۔ براہِ کرم $supportEmail پر ای میل کریں۔'
              : 'Could not open the email app. Please email $supportEmail.'),
          action: SnackBarAction(
            label: isUrdu ? 'کاپی' : 'Copy',
            onPressed: () =>
                Clipboard.setData(ClipboardData(text: supportEmail)),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isUrdu = Provider.of<PreferencesService>(context).isUrdu;
    final dir = isUrdu ? TextDirection.rtl : TextDirection.ltr;
    // Fetch once per build; shared by the version label and What's New.
    final packageInfoFuture = PackageInfo.fromPlatform();
    return Scaffold(
      appBar:
          AppBar(title: Text(isUrdu ? 'ایپ کے بارے میں' : 'About the App')),
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
                  FutureBuilder<PackageInfo>(
                    future: packageInfoFuture,
                    builder: (context, snapshot) {
                      final version = snapshot.data?.version;
                      return Text(
                        version == null ? 'Version…' : 'Version $version',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.6),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _section(
            context,
            isUrdu ? 'ایپ کے بارے میں' : 'About the App',
            isUrdu ? aboutIntroUr : aboutIntroEn,
            textDirection: dir,
          ),
          FutureBuilder<PackageInfo>(
            future: packageInfoFuture,
            builder: (context, snapshot) {
              final version = snapshot.data?.version ?? '1.0.51';
              return _section(
                context,
                isUrdu ? 'نیا کیا ہے' : "What's New",
                aboutFeaturesForLang(version, isUrdu),
                textDirection: dir,
              );
            },
          ),
          _section(
            context,
            isUrdu ? 'ذرائع' : 'Data Sources',
            isUrdu ? aboutSourcesUr : aboutSourcesEn,
            textDirection: dir,
          ),
          _section(
            context,
            isUrdu ? 'لائسنس' : 'Licenses',
            isUrdu ? aboutLicensesUr : aboutLicensesEn,
            textDirection: dir,
          ),
          const SizedBox(height: 4),
          Card(
            color: cs.surface,
            child: ListTile(
              leading: Icon(Icons.bug_report_outlined, color: cs.primary),
              title: Text(
                isUrdu ? 'مسئلہ رپورٹ کریں' : 'Report an Issue',
                textDirection: dir,
              ),
              subtitle: Text(
                isUrdu
                    ? 'کوئی مسئلہ ہو تو ہمیں ای میل کریں'
                    : 'Found a problem? Email us',
                textDirection: dir,
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _reportIssue(context),
            ),
          ),
          const SizedBox(height: 4),
          Card(
            color: cs.surface,
            child: ListTile(
              leading: Icon(Icons.email_outlined, color: cs.primary),
              title: Text(isUrdu ? 'رابطہ' : 'Contact', textDirection: dir),
              subtitle: const Text(supportEmail),
              trailing: IconButton(
                icon: const Icon(Icons.copy_outlined),
                onPressed: () {
                  Clipboard.setData(
                      const ClipboardData(text: supportEmail));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isUrdu
                            ? 'ای میل ایڈریس کاپی ہو گیا'
                            : 'Email address copied',
                        textDirection: dir,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(
    BuildContext context,
    String title,
    String body, {
    TextDirection? textDirection,
  }) {
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
              textDirection: textDirection,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              textDirection: textDirection,
              style: theme.textTheme.bodyMedium,
            ),
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
    final cs = theme.colorScheme;
    final isUrdu = Provider.of<PreferencesService>(context).isUrdu;
    final dir = isUrdu ? TextDirection.rtl : TextDirection.ltr;
    return Scaffold(
      appBar:
          AppBar(title: Text(isUrdu ? 'پرائیویسی پالیسی' : 'Privacy Policy')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _section(
            context,
            icon: Icons.smartphone,
            title: isUrdu ? '100٪ آن ڈیوائس ایپ' : '100% On-Device App',
            body: isUrdu
                ? 'نور القرآن میں کوئی اکاؤنٹ نہیں بنتا، کوئی ٹریکنگ یا اینالیٹکس نہیں ہے۔ '
                    'آپ کا کوئی ذاتی ڈیٹا کسی سرور پر بھیجا یا محفوظ نہیں کیا جاتا۔'
                : 'Nur-ul-Quran has no accounts, no tracking and no analytics. '
                    'None of your personal data is sent to or stored on any server.',
            textDirection: dir,
          ),
          _section(
            context,
            icon: Icons.location_on_outlined,
            title: isUrdu ? 'لوکیشن' : 'Location',
            body: isUrdu
                ? 'آپ کی لوکیشن صرف آپ کے فون پر نماز کے اوقات اور قبلہ کی سمت '
                    'حساب کرنے کے لیے استعمال ہوتی ہے۔ یہ کبھی کسی سرور کو نہیں بھیجی جاتی۔'
                : 'Your location is used only on your phone to calculate prayer times '
                    'and the Qibla direction. It is never sent to any server.',
            textDirection: dir,
          ),
          _section(
            context,
            icon: Icons.cloud_download_outlined,
            title: isUrdu ? 'انٹرنیٹ کا استعمال' : 'Internet Usage',
            body: isUrdu
                ? 'قرآن کے پیج امیجز اور آڈیو تلاوت صرف تب انٹرنیٹ سے لوڈ ہوتے ہیں '
                    'جب آپ انہیں دیکھتے یا سنتے ہیں۔ ایک بار لوڈ ہونے کے بعد صفحات آف لائن بھی کام کرتے ہیں۔'
                : 'Quran page images and audio recitation load from the internet only when '
                    'you view or listen to them. Once loaded, pages also work offline.',
            textDirection: dir,
          ),
          _section(
            context,
            icon: Icons.bookmark_outline,
            title: isUrdu ? 'آپ کا ڈیٹا' : 'Your Data',
            body: isUrdu
                ? 'بک مارکس، نوٹس، ڈرائنگ، ترجیحات اور بیک اپ — سب کچھ صرف آپ کے '
                    'ڈیوائس پر محفوظ رہتا ہے۔ ایپ ان انسٹال کرنے پر یہ ڈیٹا حذف ہو جاتا ہے۔'
                : 'Bookmarks, notes, drawings, preferences and backups — everything stays '
                    'safe only on your device. Uninstalling the app deletes this data.',
            textDirection: dir,
          ),
          _section(
            context,
            icon: Icons.email_outlined,
            title: isUrdu ? 'رابطہ' : 'Contact',
            body: isUrdu
                ? 'اگر آپ "Report an Issue" سے ای میل بھیجتے ہیں تو صرف وہی تفصیل ہمیں ملتی ہے '
                    'جو آپ خود لکھتے ہیں۔ کوئی خودکار ڈیٹا جمع نہیں کیا جاتا۔'
                : 'If you send an email via "Report an Issue", we only receive the details '
                    'you write yourself. No data is collected automatically.',
            textDirection: dir,
          ),
          const SizedBox(height: 8),
          Text(
            isUrdu
                ? 'کوئی سوال ہو تو $supportEmail پر رابطہ کریں۔'
                : 'Questions? Contact us at $supportEmail.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurface.withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
            textDirection: dir,
          ),
        ],
      ),
    );
  }

  Widget _section(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String body,
    TextDirection? textDirection,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Card(
      color: cs.surface,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: cs.primary, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    textDirection: textDirection,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: cs.primary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    body,
                    textDirection: textDirection,
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
