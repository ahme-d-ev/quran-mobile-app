import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppState extends ChangeNotifier {
  final SharedPreferences prefs;

  double fontSize;
  bool isDarkMode;
  List<Map<String, dynamic>>
      favorites; // {type: 'sura'|'verse', suraId, verseId?, name}
  Map<String, dynamic>? lastRead; // {suraId, verseId}
  Map<int, int> readCounts; // {suraId: count}

  AppState(this.prefs)
      : fontSize = prefs.getDouble('fontSize') ?? 20.0,
        isDarkMode = prefs.getBool('isDarkMode') ?? false,
        favorites = (prefs.getString('favorites') != null)
            ? List<Map<String, dynamic>>.from(
                jsonDecode(prefs.getString('favorites')!))
            : [],
        lastRead = prefs.getString('lastRead') != null
            ? Map<String, dynamic>.from(
                jsonDecode(prefs.getString('lastRead')!))
            : null,
        readCounts = prefs.getString('readCounts') != null
            ? Map<String, dynamic>.from(
                    jsonDecode(prefs.getString('readCounts')!))
                .map((k, v) => MapEntry(int.parse(k), (v as num).toInt()))
            : {};

  Future<void> setFontSize(double v) async {
    fontSize = v;
    await prefs.setDouble('fontSize', fontSize);
    notifyListeners();
  }

  Future<void> setDarkMode(bool v) async {
    isDarkMode = v;
    await prefs.setBool('isDarkMode', isDarkMode);
    notifyListeners();
  }

  Future<void> addFavorite(Map<String, dynamic> fav) async {
    favorites.add(fav);
    await prefs.setString('favorites', jsonEncode(favorites));
    notifyListeners();
  }

  Future<void> removeFavoriteAt(int index) async {
    favorites.removeAt(index);
    await prefs.setString('favorites', jsonEncode(favorites));
    notifyListeners();
  }

  Future<void> saveLastRead(int suraId, int verseId) async {
    lastRead = {'suraId': suraId, 'verseId': verseId};
    await prefs.setString('lastRead', jsonEncode(lastRead));
    notifyListeners();
  }

  Future<void> incrementSuraRead(int suraId) async {
    readCounts[suraId] = (readCounts[suraId] ?? 0) + 1;
    final saveMap = readCounts.map((k, v) => MapEntry(k.toString(), v));
    await prefs.setString('readCounts', jsonEncode(saveMap));
    notifyListeners();
  }
}
