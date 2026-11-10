import 'package:flutter/material.dart';
import 'package:mercyocean/config/app_state.dart';
import 'package:mercyocean/pages/mushaf_bookmarks_page.dart';
import 'package:mercyocean/pages/mushaf_page.dart';
import 'package:mercyocean/pages/surah_list_reader_screen.dart';
import 'package:mercyocean/pages/juz_list_screen.dart';
import 'package:mercyocean/service/mushaf_bookmark_service.dart';
import 'package:qcf_quran_plus/qcf_quran_plus.dart';
// import '../config/app_theme.dart';
// import '../models/quran_model.dart';
// import '../service/quran_service.dart';
// import 'surah_detail_page.dart';

class QuranPage extends StatefulWidget {
  const QuranPage({super.key});

  @override
  State<QuranPage> createState() => _QuranPageState();
}

class _QuranPageState extends State<QuranPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Map> _searchResults = [];
  int _searchOccurrences = 0;

  int _selectedSurah = 1;
  int _selectedAyah = 1;

  List<MushafBookmark> _bookmarks = [];

  @override
  void initState() {
    super.initState();
    _loadBookmarks();
  }

  Future<void> _loadBookmarks() async {
    final bookmarks = await MushafBookmarkService.getBookmarks();
    if (mounted) setState(() => _bookmarks = bookmarks);
  }

  Future<void> _openMushafAtPage(int page) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MushafScreen(initialPage: page)),
    );
    _loadBookmarks();
  }

  Future<void> _openBookmarksPage() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MushafBookmarksScreen()),
    );
    _loadBookmarks();
  }

  void _performSearch(String query) {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _searchOccurrences = 0;
      });
      return;
    }
    String cleanedQuery = normalise(query);
    Map results = searchWords(cleanedQuery);
    setState(() {
      _searchOccurrences = results['occurences'];
      _searchResults = List<Map>.from(results['result']);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Holy Quran',
          style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: () {
              themeNotifier.value = isDark ? ThemeMode.light : ThemeMode.dark;
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // --- Navigation Buttons ---
            const SizedBox(height: 12),
            _buildSectionTitle('Recitation Options', primaryColor),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildNavButton(
                    context,
                    title: 'Mushaf wise',
                    icon: Icons.menu_book,
                    color: primaryColor,

                    onTap: () => _openMushafAtPage(1),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildNavButton(
                    context,
                    title: 'Surah wise',
                    icon: Icons.format_list_numbered_rtl,
                    color: Theme.of(context).colorScheme.secondary,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SurahListReaderScreen(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildNavButton(
              context,
              title: 'Juz wise',
              icon: Icons.layers_outlined,
              color: const Color(0xFFD4AF37),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const JuzListScreen()),
              ),
            ),
            const SizedBox(height: 25),

            // --- Statistics Section ---
            _buildSectionTitle('Statistics of Quran', primaryColor),
            const SizedBox(height: 10),
            Row(
              children: [
                _buildStatCard(
                  'Number of Surahs',
                  '$totalSurahCount',
                  Icons.library_books,
                ),
                const SizedBox(width: 10),
                _buildStatCard(
                  'Number of Verses',
                  '$totalVerseCount',
                  Icons.format_list_numbered_rtl,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _buildStatCard(
                  'Makki Surahs',
                  '$totalMakkiSurahs',
                  Icons.location_on,
                ),
                const SizedBox(width: 10),
                _buildStatCard(
                  'Madani Surahs',
                  '$totalMadaniSurahs',
                  Icons.location_city,
                ),
              ],
            ),
            const SizedBox(height: 25),

            // --- Bookmarks Section ---
            _buildSectionTitle('My Bookmarks', primaryColor),
            const SizedBox(height: 12),
            _buildBookmarksEntry(primaryColor),
            const SizedBox(height: 30),

            // --- API Demo Section ---
            // _buildSectionTitle('استكشاف دوال الآيات (API Demo)', primaryColor),
            // const SizedBox(height: 10),
            // _buildAyahExplorerDemo(context),
            // const SizedBox(height: 30),

            // // --- Search Section ---
            // _buildSectionTitle('محرك البحث المدمج', primaryColor),
            // const SizedBox(height: 10),
            // TextField(
            //   controller: _searchController,
            //   onSubmitted: _performSearch,
            //   style: TextStyle(
            //     color: Theme.of(context).textTheme.bodyLarge!.color,
            //   ),
            //   decoration: InputDecoration(
            //     hintText: 'ابحث (مثال: الله، الرحمن)...',
            //     hintStyle: TextStyle(
            //       color: Theme.of(context).textTheme.bodyMedium!.color,
            //     ),
            //     prefixIcon: Icon(Icons.search, color: primaryColor),
            //     suffixIcon: IconButton(
            //       icon: const Icon(Icons.clear),
            //       onPressed: () {
            //         _searchController.clear();
            //         _performSearch('');
            //       },
            //     ),
            //     border: OutlineInputBorder(
            //       borderRadius: BorderRadius.circular(15),
            //       borderSide: BorderSide(color: primaryColor.withOpacity(0.5)),
            //     ),
            //     enabledBorder: OutlineInputBorder(
            //       borderRadius: BorderRadius.circular(15),
            //       borderSide: BorderSide(color: primaryColor.withOpacity(0.2)),
            //     ),
            //     filled: true,
            //     fillColor: Theme.of(context).cardColor,
            //   ),
            // ),
            // const SizedBox(height: 15),

            // // --- Search Results ---
            // if (_searchOccurrences > 0) ...[
            //   Text(
            //     'تم العثور على $_searchOccurrences نتيجة:',
            //     style: TextStyle(
            //       fontWeight: FontWeight.bold,
            //       color: primaryColor,
            //     ),
            //   ),
            //   const SizedBox(height: 10),
            //   ListView.builder(
            //     shrinkWrap: true,
            //     physics: const NeverScrollableScrollPhysics(),
            //     itemCount: _searchResults.length > 50
            //         ? 50
            //         : _searchResults.length,
            //     itemBuilder: (context, index) {
            //       final result = _searchResults[index];
            //       int sNum = result['sora'];
            //       int vNum = result['aya_no'];
            //       String sName = getSurahNameArabic(sNum);
            //       int pNum = getPageNumber(sNum, vNum);
            //       String verseText = getVerse(sNum, vNum, verseEndSymbol: true);

            //       return Card(
            //         elevation: 1,
            //         margin: const EdgeInsets.only(bottom: 8),
            //         shape: RoundedRectangleBorder(
            //           borderRadius: BorderRadius.circular(12),
            //         ),
            //         child: Padding(
            //           padding: const EdgeInsets.all(12.0),
            //           child: Column(
            //             crossAxisAlignment: CrossAxisAlignment.start,
            //             children: [
            //               Text(
            //                 verseText,
            //                 style: QuranTextStyles.hafsStyle(fontSize: 23.55),
            //               ),
            //               const SizedBox(height: 8),
            //               Row(
            //                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //                 children: [
            //                   Text(
            //                     'سورة $sName - آية $vNum (صفحة $pNum)',
            //                     style: TextStyle(
            //                       color: primaryColor,
            //                       fontSize: 12,
            //                     ),
            //                   ),
            //                   Row(
            //                     children: [
            //                       IconButton(
            //                         icon: Icon(
            //                           Icons.menu_book,
            //                           color: Theme.of(
            //                             context,
            //                           ).colorScheme.primary,
            //                           size: 20,
            //                         ),
            //                         tooltip: 'افتح في المصحف',
            //                         onPressed: () {
            //                           Navigator.push(
            //                             context,
            //                             MaterialPageRoute(
            //                               builder: (context) => MushafScreen(
            //                                 initialPage: pNum,
            //                                 highlightSurah: sNum,
            //                                 highlightAyah: vNum,
            //                               ),
            //                             ),
            //                           );
            //                         },
            //                       ),
            //                       IconButton(
            //                         icon: Icon(
            //                           Icons.format_list_numbered_rtl,
            //                           color: Theme.of(
            //                             context,
            //                           ).colorScheme.secondary,
            //                           size: 20,
            //                         ),
            //                         tooltip: 'افتح في القائمة',
            //                         onPressed: () {
            //                           Navigator.push(
            //                             context,
            //                             MaterialPageRoute(
            //                               builder: (context) =>
            //                                   SurahListReaderScreen(
            //                                     initialSurah: sNum,
            //                                     highlightAyah: vNum,
            //                                   ),
            //                             ),
            //                           );
            //                         },
            //                       ),
            //                     ],
            //                   ),
            //                 ],
            //               ),
            //             ],
            //           ),
            //         ),
            //       );
            //     },
            //   ),
            //const SizedBox(height: 20),
            //],
          ],
        ),
      ),
    );
  }

  Widget _buildBookmarksEntry(Color primaryColor) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: _openBookmarksPage,
        leading: Icon(Icons.bookmark, color: primaryColor),
        title: const Text(
          'View saved bookmarks',
          style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
        ),
        subtitle: Text(
          _bookmarks.isEmpty
              ? 'No bookmarks yet'
              : '${_bookmarks.length} saved page${_bookmarks.length == 1 ? '' : 's'}',
          style: const TextStyle(fontFamily: 'Poppins'),
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color color) {
    return Row(
      children: [
        Icon(Icons.brightness_4, size: 12, color: color),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
            fontFamily: 'Poppins',
          ),
        ),
      ],
    );
  }

  Widget _buildNavButton(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                //fontWeight: FontWeight.bold,
                color: color,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAyahExplorerDemo(BuildContext context) {
    int maxAyahs = getVerseCount(_selectedSurah);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: _selectedSurah,
                    decoration: InputDecoration(
                      labelText: 'السورة',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    items: List.generate(
                      114,
                      (i) => DropdownMenuItem(
                        value: i + 1,
                        child: Text(getSurahNameArabic(i + 1)),
                      ),
                    ),
                    onChanged: (val) {
                      setState(() {
                        _selectedSurah = val!;
                        _selectedAyah = 1;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: _selectedAyah,
                    decoration: InputDecoration(
                      labelText: 'رقم الآية',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    items: List.generate(
                      maxAyahs,
                      (i) => DropdownMenuItem(
                        value: i + 1,
                        child: Text('${i + 1}'),
                      ),
                    ),
                    onChanged: (val) {
                      setState(() => _selectedAyah = val!);
                    },
                  ),
                ),
              ],
            ),
            const Divider(height: 30),
            _demoTextRow(
              context,
              'الآية بالتشكيل:',
              getVerse(_selectedSurah, _selectedAyah),
            ),
            _demoTextRow(
              context,
              'بدون تشكيل:',
              removeDiacritics(getVerse(_selectedSurah, _selectedAyah)),
            ),
            _demoTextRow(
              context,
              'اسم السورة:',
              getSurahNameArabic(_selectedSurah),
            ),
            _demoTextRow(
              context,
              'الجزء / الربع:',
              'الجزء ${getJuzNumber(_selectedSurah, _selectedAyah)} - الربع ${getQuarterNumber(_selectedSurah, _selectedAyah)}',
            ),

            const SizedBox(height: 15),
            Text(
              'الرمز العثماني للآية:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Theme.of(context).textTheme.bodyMedium!.color,
              ),
            ),
            Center(
              child: Text(
                getAyaNoQCFLite(_selectedSurah, _selectedAyah),
                style: QuranTextStyles.hafsStyle(
                  fontSize: 40,
                  color: isDark ? const Color(0xFFD4AF37) : primaryColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _demoTextRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: RichText(
        text: TextSpan(
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyLarge!.color,
            fontSize: 14,
          ),
          children: [
            TextSpan(
              text: '$label ',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
                fontSize: 12,
              ),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Expanded(
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Icon(icon, color: const Color(0xFFD4AF37), size: 30),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(fontSize: 14, fontFamily: 'Poppins'),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
