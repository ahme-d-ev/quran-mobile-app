import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../services/quran_data_loader.dart';

class SuraPage extends StatefulWidget {
  final Map<String, dynamic> args;
  const SuraPage({super.key, required this.args});

  @override
  State<SuraPage> createState() => _SuraPageState();
}

class _SuraPageState extends State<SuraPage> {
  Map<String, dynamic>? sura;
  bool _isLoading = true;
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _verseKeys = {};
  Timer? _autoScrollTimer;
  double _scrollSpeed = 30.0;
  bool _isAutoScrolling = false;

  @override
  void initState() {
    super.initState();
    _loadSura();
  }

  int _asInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim()) ?? fallback;
    return fallback;
  }

  Future<void> _loadSura() async {
    final id = _asInt(widget.args['suraId'], fallback: 1);

    List<dynamic> list;
    try {
      list = await QuranDataLoader.loadSuras();
    } catch (_) {
      list = const [];
    }

    Map<String, dynamic>? found;
    for (final item in list) {
      if (item is Map && _asInt(item['id']) == id) {
        found = Map<String, dynamic>.from(item);
        break;
      }
    }

    if (found == null && id > 0 && id <= list.length) {
      final fallback = list[id - 1];
      if (fallback is Map) {
        found = Map<String, dynamic>.from(fallback);
      }
    }

    if (!mounted) return;
    setState(() {
      sura = found;
      _isLoading = false;
      _verseKeys.clear();
      if (sura != null) {
        for (final v in (sura!['verses'] as List<dynamic>)) {
          final verseId = _asInt((v as Map)['id']);
          if (verseId > 0) {
            _verseKeys[verseId] = GlobalKey();
          }
        }
      }
    });

    if (sura == null) {
      return;
    }

    try {
      await Provider.of<AppState>(context, listen: false).incrementSuraRead(id);
    } catch (_) {}

    final parsedVerseId = _asInt(widget.args['verseId'], fallback: 0);
    final verseId = parsedVerseId > 0 ? parsedVerseId : null;
    if (verseId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToVerse(verseId);
      });
    }
  }

  Future<void> _scrollToVerse(int verseId) async {
    final key = _verseKeys[verseId];
    final targetContext = key?.currentContext;
    if (targetContext == null) return;
    await Scrollable.ensureVisible(
      targetContext,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
      alignment: 0.2,
    );
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    _isAutoScrolling = true;
    const tick = Duration(milliseconds: 100);
    _autoScrollTimer = Timer.periodic(tick, (_) {
      final dy = _scrollSpeed * (tick.inMilliseconds / 1000);
      final max = _scrollController.position.maxScrollExtent;
      final next = (_scrollController.offset + dy).clamp(0.0, max);
      if (next >= max) {
        _stopAutoScroll();
      } else {
        _scrollController.jumpTo(next);
      }
    });
    setState(() {});
  }

  void _stopAutoScroll() {
    _autoScrollTimer?.cancel();
    _isAutoScrolling = false;
    setState(() {});
  }

  void _toggleAutoScroll() {
    if (_isAutoScrolling) {
      _stopAutoScroll();
    } else {
      _startAutoScroll();
    }
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final parsedHighlightVerseId =
        _asInt(widget.args['highlightVerseId'], fallback: 0);
    final parsedVerseId = _asInt(widget.args['verseId'], fallback: 0);
    final highlightVerseId = parsedHighlightVerseId > 0
        ? parsedHighlightVerseId
        : (parsedVerseId > 0 ? parsedVerseId : null);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title:
              Text(sura != null ? '${sura!['id']}. ${sura!['name']}' : '...'),
          actions: [
            IconButton(
              icon: Icon(_isAutoScrolling ? Icons.pause : Icons.play_arrow),
              tooltip: _isAutoScrolling
                  ? 'إيقاف التمرير التلقائي'
                  : 'تشغيل التمرير التلقائي',
              onPressed: _toggleAutoScroll,
            ),
            IconButton(
              icon: const Icon(Icons.speed),
              onPressed: () async {
                final v = await showModalBottomSheet<double>(
                  context: context,
                  builder: (c) {
                    double tmp = _scrollSpeed;
                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('سرعة التمرير (بكسل/ثانية)'),
                          StatefulBuilder(builder: (ctx, setSt) {
                            return Slider(
                              min: 0,
                              max: 200,
                              divisions: 40,
                              value: tmp,
                              label: tmp.toStringAsFixed(0),
                              onChanged: (val) {
                                setSt(() => tmp = val);
                              },
                            );
                          }),
                          ElevatedButton(
                            child: const Text('حفظ'),
                            onPressed: () => Navigator.of(c).pop(tmp),
                          )
                        ],
                      ),
                    );
                  },
                );
                if (v != null) {
                  setState(() => _scrollSpeed = v);
                  if (_isAutoScrolling) {
                    _startAutoScroll();
                  }
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.remove),
              onPressed: () => appState
                  .setFontSize((appState.fontSize - 2).clamp(12.0, 48.0)),
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => appState
                  .setFontSize((appState.fontSize + 2).clamp(12.0, 48.0)),
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : sura == null
                ? const Center(child: Text('تعذر تحميل السورة'))
                : Scrollbar(
                    controller: _scrollController,
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surface
                              .withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Theme.of(context)
                                .colorScheme
                                .outlineVariant
                                .withValues(alpha: 0.35),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (_shouldShowBasmala(_asInt(sura!['id'])))
                              Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: Text(
                                  'بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ',
                                  textDirection: TextDirection.rtl,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: appState.fontSize + 2,
                                    height: 1.8,
                                    fontWeight: FontWeight.w600,
                                    color:
                                        Theme.of(context).colorScheme.tertiary,
                                  ),
                                ),
                              ),
                            SelectableText.rich(
                              TextSpan(
                                children: _buildVerseSpans(
                                  sura!,
                                  appState.fontSize,
                                  appState,
                                  highlightVerseId,
                                ),
                              ),
                              textDirection: TextDirection.rtl,
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontSize: appState.fontSize,
                                height: 1.95,
                                color: Theme.of(context).colorScheme.onSurface,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
      ),
    );
  }

  List<InlineSpan> _buildVerseSpans(Map<String, dynamic> sura, double fontSize,
      AppState appState, int? highlightVerseId) {
    final verses = sura['verses'] as List<dynamic>;
    final suraId = _asInt(sura['id']);
    final showBasmala = _shouldShowBasmala(suraId);
    final List<InlineSpan> spans = [];
    for (var v in verses) {
      final id = (v['id'] as num).toInt();
      final rawText = v['text'] as String;
      final text =
          showBasmala && id == 1 ? _removeLeadingBasmala(rawText) : rawText;
      final isHighlighted = highlightVerseId != null && id == highlightVerseId;
      spans.add(
        TextSpan(
          text: '$text ',
          style: TextStyle(
            fontSize: fontSize,
            height: 1.95,
            color: Theme.of(context).colorScheme.onSurface,
            backgroundColor: isHighlighted
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.14)
                : null,
            shadows: isHighlighted
                ? const [
                    Shadow(
                        color: Colors.black26,
                        blurRadius: 8,
                        offset: Offset(0, 1)),
                  ]
                : null,
          ),
        ),
      );
      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: GestureDetector(
            key: _verseKeys[id],
            behavior: HitTestBehavior.opaque,
            onTap: () {
              appState.saveLastRead(sura['id'] as int, id);
              showModalBottomSheet<void>(
                context: context,
                builder: (c) => SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.bookmark),
                        title: const Text('حفظ كمكان القراءة الأخير'),
                        onTap: () {
                          Navigator.of(c).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('تم حفظ المكان')));
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.favorite_border),
                        title: const Text('أضف إلى المفضلة'),
                        onTap: () {
                          appState.addFavorite({
                            'type': 'verse',
                            'suraId': sura['id'],
                            'verseId': id,
                            'name': '${sura['name']} : $id'
                          });
                          Navigator.of(c).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('أضيف إلى المفضلة')));
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.close),
                        title: const Text('إغلاق'),
                        onTap: () => Navigator.of(c).pop(),
                      ),
                    ],
                  ),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
              decoration: BoxDecoration(
                color: isHighlighted
                    ? Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.14)
                    : null,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '﴿$id﴾ ',
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  fontSize: fontSize * 0.85,
                  color: isHighlighted
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                  shadows: isHighlighted
                      ? const [
                          Shadow(
                              color: Colors.black26,
                              blurRadius: 8,
                              offset: Offset(0, 1)),
                        ]
                      : null,
                ),
              ),
            ),
          ),
        ),
      );
    }
    return spans;
  }

  bool _shouldShowBasmala(int suraId) {
    return suraId != 1 && suraId != 9;
  }

  String _removeLeadingBasmala(String text) {
    const phrases = [
      'بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ',
      'بِسۡمِ ٱللَّهِ ٱلرَّحۡمَٰنِ ٱلرَّحِيمِ',
      'بسم الله الرحمن الرحيم',
    ];

    var normalized = text.trimLeft();
    for (final phrase in phrases) {
      if (normalized.startsWith(phrase)) {
        normalized = normalized.substring(phrase.length).trimLeft();
        break;
      }
    }

    return normalized.isEmpty ? text : normalized;
  }
}
