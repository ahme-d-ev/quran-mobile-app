import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../services/quran_data_loader.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<dynamic>? suras;
  List<dynamic> filteredSuras = [];
  // استخدام viewportFraction لإظهار أطراف البطاقات الجانبية كما في الصورة
  final PageController _cardsPageController =
      PageController(viewportFraction: 0.88);
  Timer? _cardsTimer;
  int _cardsIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadSuras();
    _startCardsAutoSlide();
  }

  void _startCardsAutoSlide() {
    _cardsTimer?.cancel();
    _cardsTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!_cardsPageController.hasClients) return;
      _cardsIndex = (_cardsIndex + 1) % 3;
      _cardsPageController.animateToPage(
        _cardsIndex,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  Future<void> _loadSuras() async {
    try {
      final list = await QuranDataLoader.loadSuras();
      if (!mounted) return;
      setState(() {
        suras = list;
        filteredSuras = List.from(list);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        suras = [];
        filteredSuras = [];
      });
    }
  }

  void _openSura(int id, {int? verseId}) {
    Navigator.of(context).pushNamed('/sura', arguments: {
      'suraId': id,
      'verseId': verseId,
      'highlightVerseId': verseId,
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final topRead = _topReadSuras(appState);
    final baseTheme = Theme.of(context);
    final isDark = baseTheme.brightness == Brightness.dark;
    final titleColor =
        isDark ? Colors.white.withValues(alpha: 0.92) : Colors.black87;
    final subtitleColor = isDark ? Colors.white70 : Colors.black54;
    final iconColor = isDark ? Colors.white70 : Colors.black54;
    final pageTheme = baseTheme.copyWith(
      textTheme: baseTheme.textTheme.apply(fontFamily: 'IBMPlexSansArabic'),
    );

    return Theme(
      data: pageTheme,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            title: Text(
              'الصفحة الرئيسية',
              style: TextStyle(
                color: titleColor,
                fontWeight: FontWeight.w800,
                fontSize: 20,
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.favorite, color: iconColor),
                onPressed: () => Navigator.of(context).pushNamed('/favorites'),
              ),
              IconButton(
                icon: Icon(Icons.settings, color: iconColor),
                onPressed: () => Navigator.of(context).pushNamed('/settings'),
              ),
            ],
          ),
          body: Container(
            // تدرج الخلفية العام للتطبيق كما في الصورة
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? const [
                        Color(0xFF0F1C1B),
                        Color(0xFF1E2A2A),
                      ]
                    : const [
                        Color(0xFFE5EFEA), // أخضر مائي فاتح
                        Color(0xFFF3EDD7), // بيج / أصفر فاتح
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              child: suras == null
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      children: [
                        // قسم البطاقات العلوية
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 150,
                          child: PageView(
                            controller: _cardsPageController,
                            onPageChanged: (i) =>
                                setState(() => _cardsIndex = i),
                            children: [
                              _buildImageLikeCard(isDark),
                              _buildTopReadCard(topRead, isDark),
                              _buildQuickLinksCard(isDark),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // مؤشرات النقاط (Dots)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(3, (i) {
                            final active = i == _cardsIndex;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: active ? 10 : 7,
                              height: active ? 10 : 7,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                color: active
                                    ? const Color(
                                        0xFFC7A35F) // لون ذهبي مأخوذ من الصورة
                                    : (isDark
                                        ? Colors.white.withValues(alpha: 0.18)
                                        : Colors.black.withValues(alpha: 0.15)),
                                shape: BoxShape.circle,
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 20),

                        // شريط البحث
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: TextField(
                            decoration: InputDecoration(
                              suffixIcon: Icon(Icons.search, color: iconColor),
                              hintText: 'ابحث عن السورة',
                              hintStyle: TextStyle(
                                  color:
                                      isDark ? Colors.white54 : Colors.black38,
                                  fontSize: 15),
                              filled: true,
                              fillColor: isDark
                                  ? const Color(0xFF1F2A2A)
                                      .withValues(alpha: 0.75)
                                  : Colors.white.withValues(alpha: 0.6),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 14),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(999),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(999),
                                borderSide: BorderSide(
                                    color:
                                        isDark ? Colors.white24 : Colors.white,
                                    width: 1.5),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(999),
                                borderSide: const BorderSide(
                                    color: Color(0xFF639796), width: 1.5),
                              ),
                            ),
                            onChanged: (v) {
                              setState(() {
                                filteredSuras = suras!
                                    .where((s) =>
                                        (s['name'] as String).contains(v) ||
                                        (s['transliteration'] as String)
                                            .toLowerCase()
                                            .contains(v.toLowerCase()))
                                    .toList();
                              });
                            },
                          ),
                        ),
                        const SizedBox(height: 16),

                        // قائمة السور
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 8),
                            itemCount: filteredSuras.length,
                            itemBuilder: (context, idx) {
                              final s = filteredSuras[idx];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: (isDark
                                          ? const Color(0xFF1F2626)
                                          : Colors.white)
                                      .withValues(alpha: isDark ? 0.75 : 0.65),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.12)
                                        : Colors.white.withValues(alpha: 0.9),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                          alpha: isDark ? 0.25 : 0.04),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(16),
                                    onTap: () => _openSura(s['id']),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 14),
                                      child: Row(
                                        children: [
                                          // الدائرة التي تحتوي على رقم السورة
                                          Container(
                                            width: 44,
                                            height: 44,
                                            alignment: Alignment.center,
                                            decoration: BoxDecoration(
                                              color: isDark
                                                  ? const Color(0xFF3A3A2D)
                                                  : const Color(0xFFE2DDD1),
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: isDark
                                                    ? Colors.white
                                                        .withValues(alpha: 0.15)
                                                    : Colors.white
                                                        .withValues(alpha: 0.8),
                                                width: 2,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withValues(alpha: 0.05),
                                                  blurRadius: 4,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: Text(
                                              '${s['id']}',
                                              style: TextStyle(
                                                color: isDark
                                                    ? Colors.white
                                                        .withValues(alpha: 0.9)
                                                    : Colors.black87,
                                                fontWeight: FontWeight.w800,
                                                fontSize: 15,
                                              ),
                                            ),
                                          ),
                                          // توسيط النصوص كما في الصورة
                                          Expanded(
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  '${s['name']}',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w800,
                                                    fontSize: 17,
                                                    color: titleColor,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  '${s['total_verses']} آيات',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: subtitleColor,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          // أيقونة السهم
                                          Icon(
                                            Icons.chevron_left,
                                            color: titleColor,
                                            size: 26,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
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

  // بطاقة مطابقة تماماً لتصميم الصورة الأولى
  Widget _buildImageLikeCard(bool isDark) {
    return _buildSpiritualCard(
      isDark: isDark,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Align(
            alignment: Alignment.centerRight,
            child: Text(
              'تطبيق القرآن الكريم\nلقراءة السور، حفظ\nالآيات، ومتابعة القراءة\nبسهولة.',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                height: 1.5,
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: 65,
              height: 65,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.25),
              ),
              alignment: Alignment.center,
              child: Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                alignment: Alignment.center,
                // يمكنك استبدال هذه الأيقونة بصورة الكتاب إذا توفرت لديك
                child: const Icon(Icons.menu_book,
                    color: Color(0xFF639796), size: 24),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopReadCard(List<Map<String, int>> topRead, bool isDark) {
    return _buildSpiritualCard(
      isDark: isDark,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'السور الأكثر قراءة',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 8),
            if (topRead.isEmpty)
              const Text(
                'لا توجد بيانات قراءة بعد',
                style: TextStyle(color: Colors.white70),
              )
            else
              Expanded(
                child: ListView.separated(
                  padding: EdgeInsets.zero,
                  itemCount: topRead.length,
                  physics: const BouncingScrollPhysics(),
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (context, index) {
                    final item = topRead[index];
                    final suraId = item['suraId'] as int;
                    final count = item['count'] as int;
                    return InkWell(
                      onTap: () => _openSura(suraId),
                      borderRadius: BorderRadius.circular(12),
                      child: Row(
                        children: [
                          Container(
                            width: 26,
                            height: 26,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.25),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '$suraId',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _suraNameById(suraId),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$count',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickLinksCard(bool isDark) {
    return _buildSpiritualCard(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'وصلات سريعة',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _quickChip('الملك', () => _openSura(67)),
              _quickChip('السجدة', () => _openSura(32)),
              _quickChip('الكهف', () => _openSura(18)),
              _quickChip('آية الكرسي', () => _openSura(2, verseId: 255)),
              _quickChip('يس', () => _openSura(36)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _quickChip(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // دالة بناء البطاقة العلوية بتدرج الألوان المتطابق مع التصميم
  Widget _buildSpiritualCard({required Widget child, required bool isDark}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: isDark
              ? const [
                  Color(0xFF2B4F4E),
                  Color(0xFF6D5A2A),
                ]
              : const [
                  Color(0xFF639796), // أخضر مائي داكن
                  Color(0xFFD3A85C), // ذهبي
                ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: child,
    );
  }

  List<Map<String, int>> _topReadSuras(AppState appState) {
    final items = appState.readCounts.entries
        .map((e) => {'suraId': e.key, 'count': e.value})
        .toList();
    items.sort((a, b) => (b['count']!).compareTo(a['count']!));
    return items.take(3).toList();
  }

  String _suraNameById(int id) {
    if (suras == null) return 'سورة $id';
    final match = suras!.firstWhere(
      (e) => e['id'] == id,
      orElse: () => {'name': 'سورة $id'},
    );
    return match['name'] as String? ?? 'سورة $id';
  }

  @override
  void dispose() {
    _cardsTimer?.cancel();
    _cardsPageController.dispose();
    super.dispose();
  }
}
