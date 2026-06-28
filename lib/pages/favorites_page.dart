import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    return Scaffold(
      appBar: AppBar(title: const Text('المفضلة')),
      body: appState.favorites.isEmpty
          ? const Center(child: Text('لا توجد عناصر محفوظة'))
          : ListView.builder(
              itemCount: appState.favorites.length,
              itemBuilder: (context, idx) {
                final f = appState.favorites[idx];
                return Dismissible(
                  key: ValueKey(f.toString() + idx.toString()),
                  direction: DismissDirection.endToStart,
                  onDismissed: (_) => appState.removeFavoriteAt(idx),
                  background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: const Icon(Icons.delete, color: Colors.white)),
                  child: ListTile(
                    title: Text(f['name'] ?? '${f['type']}'),
                    subtitle: Text('نوع: ${f['type']}'),
                    onTap: () {
                      if (f['type'] == 'sura') {
                        Navigator.of(context).pushNamed('/sura',
                            arguments: {'suraId': f['suraId']});
                      } else if (f['type'] == 'verse') {
                        Navigator.of(context).pushNamed('/sura', arguments: {
                          'suraId': f['suraId'],
                          'verseId': f['verseId']
                        });
                      }
                    },
                  ),
                );
              },
            ),
    );
  }
}
