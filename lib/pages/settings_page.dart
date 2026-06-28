import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_state.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  static const String _storeUrl =
      'https://play.google.com/store/apps/details?id=com.quran.quran_alkareem';
  static const String _shareText =
      'القران الكريم - تطبيق لقراءة السور وحفظ الآيات.';
  static const String _sourceUrl = 'https://tanzil.net';

  Future<void> _rateApp(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final uri = Uri.parse(_storeUrl);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) {
      messenger.showSnackBar(
        const SnackBar(content: Text('تعذر فتح رابط التقييم')),
      );
    }
  }

  Future<void> _shareApp(BuildContext context) async {
    await Share.share(_shareText);
  }

  Future<void> _openSource(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final uri = Uri.parse(_sourceUrl);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) {
      messenger.showSnackBar(
        const SnackBar(content: Text('تعذر فتح رابط المصدر')),
      );
    }
  }

  Future<PackageInfo> _loadInfo() => PackageInfo.fromPlatform();

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('الإعدادات')),
        body: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('وضع الليل'),
                Switch(
                  value: appState.isDarkMode,
                  onChanged: (v) => appState.setDarkMode(v),
                ),
              ],
            ),
            const Divider(height: 24),
            ListTile(
              leading: const Icon(Icons.star_rate),
              title: const Text('تقييم التطبيق'),
              onTap: () => _rateApp(context),
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('مشاركة التطبيق'),
              onTap: () => _shareApp(context),
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('نبذة عن التطبيق'),
              onTap: () => showDialog<void>(
                context: context,
                builder: (c) => AlertDialog(
                  title: const Text('نبذة عن التطبيق'),
                  content: const Text(
                    'تطبيق "قرآن كريم" هو رفيقك المسلم لقراءة وتدبر كتاب الله عز وجل في كل وقت وحين. تم تصميم التطبيق ليوفر تجربة قراءة مريحة وهادئة تحاكي المصحف الورقي، مع مميزات تقنية حديثة تساعدك على الالتزام بوردك اليومي.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(c).pop(),
                      child: const Text('إغلاق'),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 24),
            ListTile(
              leading: const Icon(Icons.source_outlined),
              title: const Text('المصدر'),
              subtitle: const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'يعتمد هذا التطبيق في عرض نص القرآن الكريم على\n'
                  'النص العثماني الصادر عن Tanzil Project.\n\n'
                  '© Tanzil Project\n'
                  'جميع الحقوق محفوظة للمشروع.\n'
                  'المصدر: https://tanzil.net',
                ),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.open_in_new),
                tooltip: 'فتح المصدر',
                onPressed: () => _openSource(context),
              ),
              onTap: () => _openSource(context),
            ),
            FutureBuilder<PackageInfo>(
              future: _loadInfo(),
              builder: (context, snapshot) {
                final version = snapshot.data?.version ?? '-';
                final build = snapshot.data?.buildNumber ?? '-';
                return ListTile(
                  leading: const Icon(Icons.verified),
                  title: const Text('رقم الإصدار'),
                  subtitle: Text('v$version+$build • by Ahmed Dev'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
