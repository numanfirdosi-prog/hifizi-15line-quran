import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// "Check Update" menu tile: compares the installed app version against the
/// latest GitHub release. Green check when up to date, red download icon
/// when a newer APK exists — tapping the red icon opens the APK download
/// link in the browser.
class CheckUpdateTile extends StatefulWidget {
  const CheckUpdateTile({super.key});

  @override
  State<CheckUpdateTile> createState() => _CheckUpdateTileState();
}

enum _UpdateStatus { idle, checking, upToDate, updateAvailable, error }

class _CheckUpdateTileState extends State<CheckUpdateTile> {
  static const _releasesUrl =
      'https://api.github.com/repos/numanfirdosi-prog/hifizi-15line-quran/releases/latest';

  _UpdateStatus _status = _UpdateStatus.idle;
  String _installedVersion = '';
  String _latestVersion = '';
  String _downloadUrl = '';

  @override
  void initState() {
    super.initState();
    _loadInstalledVersion();
  }

  Future<void> _loadInstalledVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) setState(() => _installedVersion = info.version);
    } catch (_) {
      // Version label stays empty; the check still works.
    }
  }

  Future<void> _checkForUpdate() async {
    if (_status == _UpdateStatus.checking) return;
    // Update already found: tapping opens the APK download link.
    if (_status == _UpdateStatus.updateAvailable && _downloadUrl.isNotEmpty) {
      await _openDownload();
      return;
    }
    setState(() => _status = _UpdateStatus.checking);
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 15);
      final request = await client.getUrl(Uri.parse(_releasesUrl));
      // GitHub API rejects requests without a User-Agent.
      request.headers.set('User-Agent', 'Nur-Al-Quran-App');
      request.headers.set('Accept', 'application/vnd.github+json');
      final response =
          await request.close().timeout(const Duration(seconds: 20));
      final body = await response.transform(utf8.decoder).join();
      client.close();
      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }
      final data = jsonDecode(body) as Map<String, dynamic>;
      final tag = (data['tag_name'] as String? ?? '')
          .replaceFirst(RegExp(r'^v'), '');
      var url = '';
      final assets = data['assets'] as List? ?? [];
      for (final a in assets) {
        final name = (a as Map)['name'] as String? ?? '';
        if (name.endsWith('.apk')) {
          url = a['browser_download_url'] as String? ?? '';
          break;
        }
      }
      if (!mounted) return;
      final isNewer =
          _compareVersions(_installedVersion, tag) < 0 && url.isNotEmpty;
      setState(() {
        _latestVersion = tag;
        _downloadUrl = url;
        _status =
            isNewer ? _UpdateStatus.updateAvailable : _UpdateStatus.upToDate;
      });
      if (_status == _UpdateStatus.upToDate && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Aap latest version par hain — update ki zaroorat nahi')),
        );
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _status = _UpdateStatus.error);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Update check nahi ho saka — internet check karein')),
      );
    }
  }

  /// Compares dotted version strings ("1.0.34"). Negative if [a] < [b].
  int _compareVersions(String a, String b) {
    final pa = a.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final pb = b.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final len = pa.length > pb.length ? pa.length : pb.length;
    for (var i = 0; i < len; i++) {
      final x = i < pa.length ? pa[i] : 0;
      final y = i < pb.length ? pb[i] : 0;
      if (x != y) return x.compareTo(y);
    }
    return 0;
  }

  Future<void> _openDownload() async {
    final uri = Uri.parse(_downloadUrl);
    var opened = false;
    try {
      if (await canLaunchUrl(uri)) {
        opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      opened = false;
    }
    // Never fail silently: tell the user when the browser could not open.
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Download link nahi khul saka — dobara try karein'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final Widget trailing;
    final String subtitle;
    switch (_status) {
      case _UpdateStatus.checking:
        trailing = const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2.5),
        );
        subtitle = 'Check ho raha hai...';
        break;
      case _UpdateStatus.upToDate:
        trailing =
            const Icon(Icons.check_circle, color: Colors.green, size: 28);
        subtitle = 'Aap latest version par hain';
        break;
      case _UpdateStatus.updateAvailable:
        trailing = const Icon(Icons.download, color: Colors.red, size: 28);
        subtitle =
            'Nayi version $_latestVersion available hai — tap karke download karein';
        break;
      case _UpdateStatus.error:
        trailing = Icon(Icons.error_outline, color: cs.error, size: 28);
        subtitle = 'Check nahi ho saka — dobara try karein';
        break;
      case _UpdateStatus.idle:
        trailing = Icon(Icons.system_update, color: cs.primary, size: 28);
        subtitle = _installedVersion.isEmpty
            ? 'Tap karke check karein'
            : 'Version $_installedVersion — tap karke check karein';
        break;
    }
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: CircleAvatar(
        backgroundColor: cs.primary.withOpacity(0.15),
        child: Icon(Icons.system_update, color: cs.primary),
      ),
      title: Text(
        'Check Update',
        style: TextStyle(
          color: cs.onSurface,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: cs.onSurface.withOpacity(0.6),
          fontSize: 12,
        ),
      ),
      trailing: trailing,
      onTap: _checkForUpdate,
    );
  }
}
