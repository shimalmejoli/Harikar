// lib/screens/dashboard_screen.dart
// ─────────────────────────────────────────────────────────────
// Uses: ApiService, CacheService, AppConstants, AppTheme, AppLogger
// All API calls go through ApiService — no raw http here.
// Cache-first: shows cached data instantly, refreshes in background.
// ─────────────────────────────────────────────────────────────

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:upgrader/upgrader.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/app_constants.dart';
import '../core/app_logger.dart';
import '../core/app_strings.dart';
import '../core/app_theme.dart';
import '../main.dart' show LocaleContext;
import '../services/api_service.dart';
import '../services/cache_service.dart';
import '../widgets/app_scaffold.dart';
import 'AboutUsPage.dart';
import 'WorkDetailsScreen.dart';
import 'form_search_work.dart';
import 'work_details_page.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // ── State ──────────────────────────────────────────────────
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _slideshowDetails = [];
  // Active-subcategory IDs grouped by category id. Pre-loaded so
  // that a category tap can decide instantly whether to open the
  // subcategory list or jump straight to the single subcategory's
  // details page — no second HTTP round trip on tap.
  Map<int, List<String>> _activeSubsByCat = {};
  bool _isLoading = true;
  bool _didFetchData = false;
  int _currentSlide = 1;
  int _selectedIndex = 0;
  // Tracks the user's selected language code so we can re-translate
  // category names when they switch via the drawer. We watch
  // LocaleProvider.langCode (not Localizations.localeOf) because the
  // Material locale is pinned to 'ar' for Flutter delegate support.
  String? _currentLang;

  final PageController _pageController =
      PageController(initialPage: 1, viewportFraction: 0.92);
  Timer? _slideshowTimer;

  List<Map<String, dynamic>> get _infiniteSlideshowData {
    if (_slideshowDetails.isEmpty) return [];
    return [
      _slideshowDetails.last,
      ..._slideshowDetails,
      _slideshowDetails.first,
    ];
  }

  // ── Lifecycle ──────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    AppLogger.info('DashboardScreen init', tag: 'DASHBOARD');
    _startSlideshowTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_didFetchData) _loadData();
    });
  }

  @override
  void dispose() {
    _slideshowTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newLang = context.langCode;
    if (_currentLang == null || _currentLang != newLang) {
      _currentLang = newLang;
      if (_categories.isNotEmpty) _applyTranslation();
    }
  }

  // ── Data loading ───────────────────────────────────────────

  Future<void> _loadData() async {
    _didFetchData = true;
    AppLogger.info('Loading dashboard data — cache first', tag: 'DASHBOARD');
    await _loadFromCache();
    _fetchAllData(); // background refresh
  }

  Future<void> _loadFromCache() async {
    final cachedCats =
        await CacheService.instance.getList(AppConstants.cacheCategories);
    final cachedSubs =
        await CacheService.instance.getList(AppConstants.cacheSubcategories);
    final cachedSlide =
        await CacheService.instance.getList(AppConstants.cacheSlideshow);

    if (cachedCats != null && mounted) {
      AppLogger.info(
          'Categories loaded from cache (${cachedCats.length} items)',
          tag: 'DASHBOARD');
      setState(() {
        _categories = _parseCategories(cachedCats);
        _isLoading = false;
      });
      _applyTranslation();
    }

    if (cachedSubs != null && mounted) {
      AppLogger.info(
          'Subcategories loaded from cache (${cachedSubs.length} items)',
          tag: 'DASHBOARD');
      setState(() => _activeSubsByCat = _parseSubcategories(cachedSubs));
    }

    if (cachedSlide != null && mounted) {
      AppLogger.info(
          'Slideshow loaded from cache (${cachedSlide.length} items)',
          tag: 'DASHBOARD');
      setState(() {
        _slideshowDetails = _parseSlideshow(cachedSlide);
      });
    }
  }

  Future<void> _fetchAllData() async {
    AppLogger.info('Fetching fresh data from Hostinger...', tag: 'DASHBOARD');
    try {
      await Future.wait([
        _fetchCategories(),
        _fetchSubcategories(),
        _fetchSlideshow(),
      ]);
    } catch (e) {
      AppLogger.error('_fetchAllData failed', exception: e, tag: 'DASHBOARD');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchSubcategories() async {
    final response = await ApiService.instance.fetchSubcategories();
    if (!mounted) return;

    if (response.success && response.data != null) {
      final data = response.data!['data'] as List? ?? [];
      AppLogger.info(
          'Subcategories fetched: ${data.length} items in ${response.durationMs}ms',
          tag: 'DASHBOARD');
      await CacheService.instance
          .saveList(AppConstants.cacheSubcategories, data);
      setState(() => _activeSubsByCat = _parseSubcategories(data));
    } else {
      AppLogger.error('Subcategories fetch failed: ${response.error}',
          tag: 'DASHBOARD');
    }
  }

  Future<void> _fetchCategories() async {
    final isArabic = context.isArabic;
    AppLogger.info('Fetching categories...', tag: 'DASHBOARD');

    final response = await ApiService.instance.fetchCategories();

    if (!mounted) return;

    if (response.success && response.data != null) {
      final data = response.data!['data'] as List? ?? [];
      AppLogger.info(
          'Categories fetched: ${data.length} items in ${response.durationMs}ms',
          tag: 'DASHBOARD');

      await CacheService.instance.saveList(AppConstants.cacheCategories, data);

      setState(() => _categories = _parseCategories(data));
      _applyTranslation();
    } else {
      AppLogger.error('Categories fetch failed: ${response.error}',
          tag: 'DASHBOARD');
      if (_categories.isEmpty) {
        _showErrorSnackBar(isArabic);
      }
    }
  }

  Future<void> _fetchSlideshow() async {
    AppLogger.info('Fetching slideshow...', tag: 'DASHBOARD');

    final response = await ApiService.instance.fetchSlideshow();

    if (!mounted) return;

    if (response.success && response.data != null) {
      final data = response.data!['data'] as List? ?? [];
      AppLogger.info(
          'Slideshow fetched: ${data.length} items in ${response.durationMs}ms',
          tag: 'DASHBOARD');

      await CacheService.instance.saveList(AppConstants.cacheSlideshow, data);
      setState(() => _slideshowDetails = _parseSlideshow(data));
    } else {
      AppLogger.error('Slideshow fetch failed: ${response.error}',
          tag: 'DASHBOARD');
    }
  }

  // ── Data parsing ───────────────────────────────────────────

  List<Map<String, dynamic>> _parseCategories(List<dynamic> data) {
    const order = {
      "ئەندازیار": 0,
      "مەساح": 1,
      "ئامیرە": 2,
      "هوستا": 3,
      "کرێکار": 4,
      "مەواد": 5,
    };
    final cats = data
        .map<Map<String, dynamic>>((c) => {
              'id': int.tryParse(c['id'].toString()) ?? 0,
              'name': c['name'],
              'original_name': c['name'],
              'image_url': c['image_url'],
              'isActive': c['is_active'].toString() == '1',
            })
        .toList();

    cats.sort((a, b) => (order[a['original_name']] ?? 99)
        .compareTo(order[b['original_name']] ?? 99));
    return cats;
  }

  Map<int, List<String>> _parseSubcategories(List<dynamic> data) {
    final map = <int, List<String>>{};
    for (final s in data) {
      if (s['is_active'].toString() != '1') continue;
      final catId = int.tryParse(s['category_id'].toString()) ?? 0;
      map.putIfAbsent(catId, () => []).add(s['id'].toString());
    }
    return map;
  }

  List<Map<String, dynamic>> _parseSlideshow(List<dynamic> data) {
    return data.map<Map<String, dynamic>>((item) {
      final desc = item['description']?.toString() ?? '';
      return {
        'id': item['id'],
        'photo_url': item['photo_url'],
        'name': item['name'],
        'contact_number': item['phone_number'],
        'subcategory_name': item['subcategory_name'],
        'description': desc.length > 80 ? '${desc.substring(0, 80)}...' : desc,
      };
    }).toList();
  }

  void _applyTranslation() {
    if (!mounted) return;
    final isArabic = context.isArabic;
    const translations = {
      "ئەندازیار": "مهندس",
      "مەساح": "مساح",
      "ئامیرە": "معدات",
      "هوستا": "اسطة",
      "کرێکار": "عمال",
      "مەواد": "مواد",
    };
    setState(() {
      _categories = _categories.map((cat) {
        final orig = cat['original_name']?.toString() ?? '';
        cat['name'] = (isArabic && translations.containsKey(orig))
            ? translations[orig]!
            : orig;
        return cat;
      }).toList();
    });
  }

  // ── Slideshow timer ────────────────────────────────────────

  void _startSlideshowTimer() {
    _slideshowTimer?.cancel();
    _slideshowTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || _infiniteSlideshowData.isEmpty) return;
      if (_pageController.hasClients) {
        _pageController.nextPage(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut);
      }
    });
  }

  // ── Contact bottom sheet ───────────────────────────────────

  Future<void> _showContactOptions() async {
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(AppTheme.radiusLg))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2)),
            ),
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm)),
                child: const Icon(Icons.call, color: Colors.blue),
              ),
              title: const Text(AppConstants.contactPhone,
                  style: TextStyle(
                      fontFamily: 'NotoKufi', fontWeight: FontWeight.bold)),
              subtitle: const Text('تماس مستقيم',
                  style: TextStyle(fontFamily: 'NotoKufi', fontSize: 12)),
              onTap: () {
                Navigator.pop(context);
                launchUrl(Uri(scheme: 'tel', path: AppConstants.contactPhone));
              },
            ),
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm)),
                child: FaIcon(FontAwesomeIcons.whatsapp, color: Colors.green),
              ),
              title: const Text(AppConstants.contactPhone,
                  style: TextStyle(
                      fontFamily: 'NotoKufi', fontWeight: FontWeight.bold)),
              subtitle: const Text('WhatsApp',
                  style: TextStyle(fontFamily: 'NotoKufi', fontSize: 12)),
              onTap: () {
                Navigator.pop(context);
                launchUrl(
                    Uri.parse('https://wa.me/${AppConstants.whatsAppNumber}'));
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showErrorSnackBar(bool isArabic) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
        S.dashboardLoadCategoriesError.of(context),
        style: const TextStyle(fontFamily: 'NotoKufi'),
      ),
      backgroundColor: AppTheme.error,
      action: SnackBarAction(
        label: S.retry.of(context),
        textColor: Colors.white,
        onPressed: _fetchAllData,
      ),
    ));
  }

  // ── BUILD ──────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isArabic = context.isArabic;

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    return AppScaffold(
      title: S.dashboardTitle.of(context),
      isHomePage: true,
      extendBodyBehindAppBar: true,
      bottomNavigationBar: _buildBottomNav(isArabic),
      body: UpgradeAlert(
        upgrader: Upgrader(
          messages: _UpgraderMessages(context),
          durationUntilAlertAgain: const Duration(hours: 24),
          minAppVersion: null,
          debugLogging: false,
        ),
        dialogStyle: UpgradeDialogStyle.material,
        showIgnore: false,
        showLater: true,
        showReleaseNotes: false,
        child: _isLoading && _categories.isEmpty
          ? _buildLoadingState(isArabic)
          : RefreshIndicator(
              onRefresh: _fetchAllData,
              color: AppTheme.accent,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: SizedBox(
                        height: MediaQuery.of(context).padding.top +
                            kToolbarHeight +
                            8),
                  ),
                  SliverToBoxAdapter(child: _buildAdSection(isArabic)),
                  SliverToBoxAdapter(
                      child: _buildSectionHeader(
                    S.dashboardFeaturedAds.of(context),
                    S.dashboardAdBadge.of(context),
                    Colors.pinkAccent,
                  )),
                  SliverToBoxAdapter(child: _buildSlideshowSection(isArabic)),
                  SliverToBoxAdapter(
                      child: _buildSectionHeader(
                    S.dashboardCategories.of(context),
                    S.dashboardCategoryBadge.of(context),
                    AppTheme.primary,
                  )),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 24),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 0.78,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (ctx, i) => _buildCategoryCard(_categories[i]),
                        childCount: _categories.length,
                      ),
                    ),
                  ),
                ],
              ),
            ),
      ),
    );
  }

  // ── Section header ─────────────────────────────────────────

  Widget _buildSectionHeader(String title, String badge, Color badgeColor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: AppTheme.headingMedium),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
                color: badgeColor,
                borderRadius: BorderRadius.circular(AppTheme.radiusFull)),
            child: Text(badge, style: AppTheme.labelWhite),
          ),
        ],
      ),
    );
  }

  // ── Ad section ─────────────────────────────────────────────

  Widget _buildAdSection(bool isArabic) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 8, 14, 0),
      height: 110,
      decoration: BoxDecoration(
        gradient: AppTheme.adGradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFFE91E63).withOpacity(0.30),
              blurRadius: 16,
              offset: const Offset(0, 6)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          onTap: _showContactOptions,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  child: CachedNetworkImage(
                    imageUrl: AppConstants.logoUrl,
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                        width: 64,
                        height: 64,
                        color: Colors.white24,
                        child: const Icon(Icons.image, color: Colors.white54)),
                    errorWidget: (_, __, ___) => Container(
                        width: 64,
                        height: 64,
                        color: Colors.white24,
                        child: const Icon(Icons.storefront,
                            color: Colors.white, size: 30)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        S.dashboardAdCardText.of(context),
                        style: AppTheme.labelWhite
                            .copyWith(fontSize: 12, height: 1.4),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6)),
                          child: const Icon(Icons.phone,
                              size: 13, color: Colors.white),
                        ),
                        const SizedBox(width: 6),
                        const Text(AppConstants.contactPhone,
                            style: TextStyle(
                                fontFamily: 'NotoKufi',
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                      ]),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.arrow_forward_ios_rounded,
                      size: 14, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Slideshow ──────────────────────────────────────────────

  Widget _buildSlideshowSection(bool isArabic) {
    if (_infiniteSlideshowData.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: Text(
            S.dashboardNoAds.of(context),
            style: AppTheme.bodySmall,
          ),
        ),
      );
    }
    return Column(
      children: [
        GestureDetector(
          onPanDown: (_) => _slideshowTimer?.cancel(),
          onPanCancel: _startSlideshowTimer,
          onPanEnd: (_) => _startSlideshowTimer(),
          child: SizedBox(
            height: 150,
            child: PageView.builder(
              controller: _pageController,
              itemCount: _infiniteSlideshowData.length,
              onPageChanged: (idx) {
                setState(() => _currentSlide = idx);
                if (idx == 0) {
                  Future.delayed(const Duration(milliseconds: 300), () {
                    if (mounted && _pageController.hasClients) {
                      _pageController
                          .jumpToPage(_infiniteSlideshowData.length - 2);
                    }
                  });
                } else if (idx == _infiniteSlideshowData.length - 1) {
                  Future.delayed(const Duration(milliseconds: 300), () {
                    if (mounted && _pageController.hasClients) {
                      _pageController.jumpToPage(1);
                    }
                  });
                }
              },
              itemBuilder: (_, idx) =>
                  _buildSlideshowCard(_infiniteSlideshowData[idx]),
            ),
          ),
        ),
        const SizedBox(height: 10),
        _buildPageIndicator(),
      ],
    );
  }

  Widget _buildSlideshowCard(Map<String, dynamic> slide) {
    return GestureDetector(
      onTap: () {
        final id = slide['id']?.toString();
        if (id != null && id.isNotEmpty) {
          AppLogger.info('Opening slide detail: $id', tag: 'DASHBOARD');
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) =>
                      WorkDetailsScreen(detailId: id, user: slide)));
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          gradient: AppTheme.cardGradient,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          boxShadow: AppTheme.cardShadow,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          child: Row(
            children: [
              SizedBox(
                width: 115,
                child: CachedNetworkImage(
                  imageUrl: slide['photo_url'] ?? '',
                  fit: BoxFit.cover,
                  height: double.infinity,
                  placeholder: (_, __) => Container(
                      color: Colors.white12,
                      child: const Center(
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white54))),
                  errorWidget: (_, __, ___) => Container(
                      color: Colors.white12,
                      child: const Icon(Icons.image_not_supported,
                          size: 36, color: Colors.white54)),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(slide['name'] ?? '',
                          style: AppTheme.headingLarge.copyWith(fontSize: 15),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                            color: AppTheme.error,
                            borderRadius: BorderRadius.circular(6)),
                        child: Text(slide['subcategory_name'] ?? '',
                            style: AppTheme.labelWhite.copyWith(fontSize: 10),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                      const SizedBox(height: 8),
                      Row(children: [
                        const Icon(Icons.phone,
                            size: 13, color: Colors.white70),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(slide['contact_number'] ?? '',
                              style:
                                  AppTheme.captionWhite.copyWith(fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                      ]),
                      const SizedBox(height: 6),
                      Text(slide['description'] ?? '',
                          style: AppTheme.captionWhite,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: _slideshowDetails.asMap().entries.map((e) {
        final isActive = _currentSlide == e.key + 1;
        return GestureDetector(
          onTap: () => _pageController.animateToPage(e.key + 1,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: isActive ? 18 : 6,
            height: 6,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
                color: isActive ? AppTheme.accent : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4)),
          ),
        );
      }).toList(),
    );
  }

  // ── Category card ──────────────────────────────────────────

  Widget _buildCategoryCard(Map<String, dynamic> category) {
    final imageUrl = category['image_url']?.isNotEmpty == true
        ? '${AppConstants.uploadsUrl}${category['image_url']}'
        : '${AppConstants.uploadsUrl}work.png';
    final bool isActive = category['isActive'] as bool;

    return Opacity(
      opacity: isActive ? 1.0 : 0.45,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isActive
              ? () {
                  AppLogger.info(
                      'Category tapped: ${category['original_name']}',
                      tag: 'DASHBOARD');
                  final catId = category['id'] as int;
                  final subs = _activeSubsByCat[catId] ?? const <String>[];
                  if (subs.length == 1) {
                    AppLogger.info(
                        'Single subcategory shortcut → ${subs.first}',
                        tag: 'DASHBOARD');
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                WorkDetailsPage(subcategoryId: subs.first)));
                  } else {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                FormSearchWork(initialCategoryId: catId)));
                  }
                }
              : null,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          child: Ink(
            decoration: BoxDecoration(
              gradient: AppTheme.cardGradient,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 12, 10, 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.contain,
                        width: double.infinity,
                        placeholder: (_, __) =>
                            Container(color: Colors.white12),
                        errorWidget: (_, __, ___) => Container(
                          color: Colors.white12,
                          child: const Icon(Icons.category_rounded,
                              size: 36, color: Colors.white70),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    category['name'] ?? '',
                    style: const TextStyle(
                      fontFamily: 'NotoKufi',
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Loading state ──────────────────────────────────────────

  Widget _buildLoadingState(bool isArabic) {
    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.loadingGradient),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppTheme.accent),
            const SizedBox(height: 20),
            Text(
              S.dashboardLoadingCategories.of(context),
              style: AppTheme.bodySmall.copyWith(fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }

  // ── Bottom Nav ─────────────────────────────────────────────

  Widget _buildBottomNav(bool isArabic) {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppTheme.radiusLg)),
          boxShadow: AppTheme.bottomNavShadow),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(children: [
            _navItem(0, Icons.home_rounded,
                S.footerHome.of(context), isArabic),
            _navItem(1, Icons.person_add_rounded,
                S.footerRegister.of(context), isArabic),
            _navItem(
                2, Icons.info_rounded, S.footerAbout.of(context), isArabic),
          ]),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label, bool isArabic) {
    final bool active = _selectedIndex == index;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          setState(() => _selectedIndex = index);
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, '/dashboard');
              break;
            case 1:
              Navigator.pushReplacementNamed(context, '/register');
              break;
            case 2:
              Navigator.push(
                  context, MaterialPageRoute(builder: (_) => AboutUsPage()));
              break;
          }
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: active
                    ? AppTheme.accent.withOpacity(0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
              ),
              child: Icon(icon,
                  size: 24,
                  color: active ? AppTheme.accent : Colors.grey.shade400),
            ),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    fontFamily: 'NotoKufi',
                    fontSize: 10,
                    fontWeight: active ? FontWeight.bold : FontWeight.normal,
                    color: active ? AppTheme.accent : Colors.grey.shade400)),
            const SizedBox(height: 2),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: active ? 4 : 0,
              height: active ? 4 : 0,
              decoration: const BoxDecoration(
                  color: AppTheme.accent, shape: BoxShape.circle),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Bilingual messages for the upgrader update dialog.
// Maps the upgrader package's message keys to our S strings,
// honoring the user's current language (Arabic / Kurdish).
// ─────────────────────────────────────────────────────────────

class _UpgraderMessages extends UpgraderMessages {
  final BuildContext _ctx;
  _UpgraderMessages(this._ctx);

  @override
  String? message(UpgraderMessage messageKey) {
    switch (messageKey) {
      case UpgraderMessage.title:
        return S.updateAvailableTitle.of(_ctx);
      case UpgraderMessage.body:
        return S.updateAvailableMessage.of(_ctx);
      case UpgraderMessage.prompt:
        return S.updatePrompt.of(_ctx);
      case UpgraderMessage.buttonTitleUpdate:
        return S.updateButtonNow.of(_ctx);
      case UpgraderMessage.buttonTitleLater:
        return S.updateButtonLater.of(_ctx);
      case UpgraderMessage.buttonTitleIgnore:
        return S.updateButtonIgnore.of(_ctx);
      case UpgraderMessage.releaseNotes:
        return S.updateReleaseNotes.of(_ctx);
    }
  }
}
