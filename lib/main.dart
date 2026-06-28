import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_state.dart';
import 'pages/splash_page.dart';
import 'pages/home_page.dart';
import 'pages/sura_page.dart';
import 'pages/favorites_page.dart';
import 'pages/settings_page.dart';
import 'pages/about_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final appState = AppState(prefs);
  runApp(ChangeNotifierProvider.value(
    value: appState,
    child: const MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final baseLight = ThemeData.light();
    final baseDark = ThemeData.dark();
    return MaterialApp(
      title: 'القران الكريم',
      debugShowCheckedModeBanner: false,
      theme: baseLight.copyWith(
          textTheme: baseLight.textTheme.apply(fontFamily: 'Amiri')),
      darkTheme: baseDark.copyWith(
          textTheme: baseDark.textTheme.apply(fontFamily: 'Amiri')),
      themeMode: appState.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      initialRoute: '/',
      routes: {
        '/': (c) => const SplashPage(),
        '/home': (c) => const HomePage(),
        '/favorites': (c) => const FavoritesPage(),
        '/settings': (c) => const SettingsPage(),
        '/about': (c) => const AboutPage(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/sura') {
          final args = settings.arguments as Map<String, dynamic>?;
          return MaterialPageRoute(builder: (_) => SuraPage(args: args ?? {}));
        }
        return null;
      },
    );
  }
}
