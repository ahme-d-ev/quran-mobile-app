import 'dart:convert';

import 'package:flutter/services.dart';

class QuranDataLoader {
  static const List<String> _suraNames = [
    'الفاتحة',
    'البقرة',
    'آل عمران',
    'النساء',
    'المائدة',
    'الأنعام',
    'الأعراف',
    'الأنفال',
    'التوبة',
    'يونس',
    'هود',
    'يوسف',
    'الرعد',
    'إبراهيم',
    'الحجر',
    'النحل',
    'الإسراء',
    'الكهف',
    'مريم',
    'طه',
    'الأنبياء',
    'الحج',
    'المؤمنون',
    'النور',
    'الفرقان',
    'الشعراء',
    'النمل',
    'القصص',
    'العنكبوت',
    'الروم',
    'لقمان',
    'السجدة',
    'الأحزاب',
    'سبأ',
    'فاطر',
    'يس',
    'الصافات',
    'ص',
    'الزمر',
    'غافر',
    'فصلت',
    'الشورى',
    'الزخرف',
    'الدخان',
    'الجاثية',
    'الأحقاف',
    'محمد',
    'الفتح',
    'الحجرات',
    'ق',
    'الذاريات',
    'الطور',
    'النجم',
    'القمر',
    'الرحمن',
    'الواقعة',
    'الحديد',
    'المجادلة',
    'الحشر',
    'الممتحنة',
    'الصف',
    'الجمعة',
    'المنافقون',
    'التغابن',
    'الطلاق',
    'التحريم',
    'الملك',
    'القلم',
    'الحاقة',
    'المعارج',
    'نوح',
    'الجن',
    'المزمل',
    'المدثر',
    'القيامة',
    'الإنسان',
    'المرسلات',
    'النبأ',
    'النازعات',
    'عبس',
    'التكوير',
    'الانفطار',
    'المطففين',
    'الانشقاق',
    'البروج',
    'الطارق',
    'الأعلى',
    'الغاشية',
    'الفجر',
    'البلد',
    'الشمس',
    'الليل',
    'الضحى',
    'الشرح',
    'التين',
    'العلق',
    'القدر',
    'البينة',
    'الزلزلة',
    'العاديات',
    'القارعة',
    'التكاثر',
    'العصر',
    'الهمزة',
    'الفيل',
    'قريش',
    'الماعون',
    'الكوثر',
    'الكافرون',
    'النصر',
    'المسد',
    'الإخلاص',
    'الفلق',
    'الناس',
  ];

  static Future<List<dynamic>> loadSuras() async {
    try {
      final txtData =
          await rootBundle.loadString('assets/quran/quran-uthmani.txt');
      final verseMap = _parseUthmaniText(txtData);
      if (verseMap.isEmpty) {
        return [];
      }
      return _buildSurasFromTxt(verseMap);
    } catch (_) {
      return [];
    }
  }

  static Map<int, Map<int, String>> _parseUthmaniText(String txtData) {
    final Map<int, Map<int, String>> verseMap = {};

    for (final line in const LineSplitter().convert(txtData)) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) {
        continue;
      }

      final parts = trimmed.split('|');
      if (parts.length < 3) {
        continue;
      }

      final suraPart = parts[0].replaceFirst('\uFEFF', '').trim();
      final versePart = parts[1].trim();

      final suraId = int.tryParse(suraPart);
      final verseId = int.tryParse(versePart);
      if (suraId == null || verseId == null) {
        continue;
      }

      final verseText = parts.sublist(2).join('|').trim();
      if (verseText.isEmpty) {
        continue;
      }

      verseMap.putIfAbsent(suraId, () => {})[verseId] = verseText;
    }

    return verseMap;
  }

  static List<Map<String, dynamic>> _buildSurasFromTxt(
      Map<int, Map<int, String>> verseMap) {
    final suraIds = verseMap.keys.toList()..sort();

    return suraIds.map((suraId) {
      final versesMap = verseMap[suraId]!;
      final verseIds = versesMap.keys.toList()..sort();

      final verses = verseIds
          .map((verseId) => {
                'id': verseId,
                'text': versesMap[verseId],
              })
          .toList(growable: false);

      return {
        'id': suraId,
        'name': _suraNameById(suraId),
        'transliteration': '',
        'type': '',
        'total_verses': verses.length,
        'verses': verses,
      };
    }).toList(growable: false);
  }

  static String _suraNameById(int suraId) {
    if (suraId >= 1 && suraId <= _suraNames.length) {
      return _suraNames[suraId - 1];
    }
    return 'سورة $suraId';
  }
}
