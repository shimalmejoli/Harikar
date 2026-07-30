// lib/screens/work_details_page.dart

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../core/app_constants.dart';
import '../core/app_logger.dart';
import '../core/app_strings.dart';
import '../core/app_theme.dart';
import '../main.dart';
import '../services/api_service.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/load_more_footer.dart';
import 'WorkDetailsScreen.dart';

class WorkDetailsPage extends StatefulWidget {
  final String? subcategoryId;
  const WorkDetailsPage({this.subcategoryId, Key? key}) : super(key: key);

  @override
  _WorkDetailsPageState createState() => _WorkDetailsPageState();
}

class _WorkDetailsPageState extends State<WorkDetailsPage> {
  /// Rows requested per network page. 50 is the hard cap enforced by
  /// `fetch_full_details.php` — asking for more still returns 50, so
  /// this is the largest useful chunk per round-trip.
  static const int _pageSize = 50;

  /// Distance (px) from the bottom of the list at which the next page
  /// starts loading, so rows are ready before the user gets there.
  static const double _loadMoreThreshold = 600;

  List<Map<String, dynamic>> _subcategories = [];
  List<Map<String, dynamic>> _workUsers = [];
  Map<String, String> _subcategoryMap = {};

  /// Guards against the same record appearing twice if the backend
  /// re-orders rows between two page requests.
  final Set<String> _loadedIds = {};

  final ScrollController _scrollController = ScrollController();

  int _nextPage = 1;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  String? _selectedSubcategoryId;
  String? _selectedCity;

  bool _isLoading = false;
  String? _errorMessage;
  bool _didLoadData = false;
  String _prevLang = '';

  final List<String> _cities = AppConstants.cities;

  // Subcategory translations ku→ar
  static const Map<String, String> _translations = {
    "شەڤەر": "شفل",
    "کرێکار": "عمال",
    "نەجار": "نجار",
    "حاديله": "ضاغطة التربة",
    "تانکەرێ ئاڤێ": "تنكر ماء",
    "سلنگ": "كرين",
    "قەلابە": "قلاب",
    "گرێدەر": "آلات تسوية الطرق",
    "حەفارە": "حفارة",
    "بەنا": "بناء",
    "سەباخ": "صباغ",
    "لەباخ": "لباخ",
    "سیرامیك و کاشی": "سيراميك و أرضيات",
    "مەرمەر": "مرمر",
    "فلین": "فلين خارجي",
    "سەقف مەخربی": "صقف مغربي",
    "حداد": "حداد",
    "ئەندازیاری": "مهندس",
    "مەساح": "مساح",
    "کەهرەبای": "كهربائي",
    "مەجاری": "مجاري",
  };

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final lang = context.langCode;
    if (!_didLoadData || _prevLang != lang) {
      _prevLang = lang;
      _didLoadData = true;
      _fetchSubcategories().then((_) {
        if (widget.subcategoryId?.isNotEmpty == true) {
          setState(() => _selectedSubcategoryId = widget.subcategoryId);
        }
        _fetchWorkUsers(
            subcategoryId: widget.subcategoryId, city: _selectedCity);
      });
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - _loadMoreThreshold) {
      _loadMore();
    }
  }

  // ── Fetch subcategories ──────────────────────────────────

  Future<void> _fetchSubcategories() async {
    AppLogger.info('Fetching subcategories', tag: 'WORK_PAGE');
    final r = await ApiService.instance.fetchSubcategories();
    if (!mounted) return;

    if (r.success && r.data != null) {
      final list =
          (r.data!['data'] as List? ?? []).cast<Map<String, dynamic>>();
      setState(() {
        _subcategories = list
            .map((s) => {...s, 'original_name': s['name'], 'name': s['name']})
            .toList();
        _applyTranslation();
      });
    } else {
      AppLogger.error('Subcategories failed: ${r.error}', tag: 'WORK_PAGE');
    }
  }

  void _applyTranslation() {
    final isArabic = context.isArabic;
    setState(() {
      _subcategories = _subcategories.map((s) {
        final orig = s['original_name'].toString().trim();
        s['name'] = isArabic && _translations.containsKey(orig)
            ? _translations[orig]!
            : orig;
        return s;
      }).toList();
      _subcategoryMap = {
        for (var s in _subcategories) s['id'].toString(): s['name']
      };
    });
  }

  // ── Fetch work users (infinite scroll) ───────────────────
  //
  // The section/city filters are applied by the backend (both are
  // query params of fetch_full_details.php), so every page request
  // already returns only matching rows — no client-side re-filtering
  // is needed and paging stays correct while a filter is active.

  /// (Re)loads the list from page 1. Called on first build, on filter
  /// change and on pull-to-refresh.
  Future<void> _fetchWorkUsers({String? subcategoryId, String? city}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _workUsers = [];
      _loadedIds.clear();
      _nextPage = 1;
      _hasMore = true;
      _isLoadingMore = false;
    });

    await _loadPage(subcategoryId: subcategoryId, city: city);

    if (!mounted) return;
    setState(() => _isLoading = false);

    // Jump back to the top so a filter change doesn't leave the user
    // scrolled into the middle of a brand-new, shorter list.
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
  }

  /// Appends the next page when the user scrolls near the bottom.
  Future<void> _loadMore() async {
    if (_isLoading || _isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);

    await _loadPage(
        subcategoryId: _selectedSubcategoryId, city: _selectedCity);

    if (!mounted) return;
    setState(() => _isLoadingMore = false);
  }

  /// Single network page → appended to [_workUsers].
  Future<void> _loadPage({String? subcategoryId, String? city}) async {
    final page = _nextPage;
    AppLogger.info(
        'Fetching work users — page: $page subcat: $subcategoryId city: $city',
        tag: 'WORK_PAGE');

    final r = await ApiService.instance.fetchWorkDetails(
      subcategoryId: subcategoryId,
      city: city,
      lang: context.langCode,
      page: page,
      limit: _pageSize,
    );
    if (!mounted) return;

    if (r.success && r.data != null) {
      final list =
          (r.data!['data'] as List? ?? []).cast<Map<String, dynamic>>();
      final fresh = list
          .where((u) => _loadedIds.add(u['id']?.toString() ?? ''))
          .toList();
      AppLogger.info(
          'Work users page $page: ${list.length} rows (${fresh.length} new)',
          tag: 'WORK_PAGE');

      setState(() {
        _workUsers.addAll(fresh);
        _nextPage = page + 1;
        // A short page means the server has nothing left; an all-duplicate
        // page means it is looping, so stop either way.
        _hasMore = list.length >= _pageSize && fresh.isNotEmpty;
        _errorMessage = null;
      });

      // Warm the image cache for the rows just added, so they are
      // already decoded by the time they scroll into view.
      for (final u in fresh) {
        final img = u['photo_url'] as String?;
        if (img != null && img.isNotEmpty) {
          CachedNetworkImageProvider(img).resolve(const ImageConfiguration());
        }
      }
    } else {
      AppLogger.error('Work users page $page failed: ${r.error}',
          tag: 'WORK_PAGE');
      setState(() {
        _hasMore = false;
        // Only surface a full-screen error when nothing is on screen yet —
        // a failed "load more" must not wipe the rows already shown.
        if (_workUsers.isEmpty) _errorMessage = r.error;
      });
    }
  }

  // ── Actions ──────────────────────────────────────────────

  Future<void> _openDetails(Map<String, dynamic> user) async {
    final id = user['id']?.toString();
    if (id?.isNotEmpty == true) {
      await Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => WorkDetailsScreen(detailId: id!, user: user)));
      // Refresh only THIS record's view count. Reloading the whole list
      // here would throw away every page the user has scrolled through.
      await _syncViewCount(user, id!);
    }
  }

  /// Pulls the fresh view count for a single record (it may have been
  /// incremented on the details screen) and patches the card in place.
  Future<void> _syncViewCount(Map<String, dynamic> user, String id) async {
    final r = await ApiService.instance.fetchDetailById(id);
    if (!mounted || !r.success || r.data == null) return;
    final list = (r.data!['data'] as List? ?? []);
    if (list.isEmpty) return;
    final views = (list.first as Map)['view_count'];
    if (views == null) return;
    setState(() => user['view_count'] = views);
  }

  Future<void> _onWhatsApp(Map<String, dynamic> user) async {
    final phone = user['phone_number'] as String? ?? '';
    if (phone.isEmpty) return;
    // Increment view
    ApiService.instance.incrementViewCount(user['id'].toString());
    // Update local count
    setState(() {
      final cnt = int.tryParse(user['view_count']?.toString() ?? '0') ?? 0;
      user['view_count'] = cnt + 1;
    });
    final isArabic = context.isArabic;
    final msg = isArabic
        ? 'مرحبا، لقد وجدتك في تطبيق هاريكار. أود التواصل معك.'
        : 'سلاڤ، من دڤێت پەیوەندی تە بکەم. من پێزانین تە دیتینە رێکا پرۆگرامێ هاریکار.';
    String num =
        phone.replaceAll(RegExp(r'\D'), '').replaceAll(RegExp(r'^0+'), '');
    if (!num.startsWith('964')) num = '964$num';
    final url = 'https://wa.me/$num?text=${Uri.encodeComponent(msg)}';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _callPhone(String phone) async {
    final sanitized =
        phone.replaceAll(RegExp(r'\D'), '').replaceAll(RegExp(r'^0+'), '');
    final uri = Uri(scheme: 'tel', path: sanitized);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _refreshPage() =>
      _fetchWorkUsers(subcategoryId: _selectedSubcategoryId, city: _selectedCity);

  // ── BUILD ────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isArabic = context.isArabic;
    return AppScaffold(
      title: S.workListTitle.of(context),
      body: Column(children: [
        // ── Filter row ──
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(children: [
            Row(children: [
              Expanded(child: _subcategoryDropdown(isArabic)),
              const SizedBox(width: 10),
              Expanded(child: _cityDropdown(isArabic)),
            ]),
            // Loaded-rows counter — replaces the old "page X / Y" footer.
            if (!_isLoading && _errorMessage == null && _workUsers.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(children: [
                  Text(
                    '${_workUsers.length}${_hasMore ? '+' : ''} '
                    '${S.workListResultsSuffix.of(context)}',
                    style: const TextStyle(
                      fontFamily: 'NotoKufi',
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ]),
              ),
          ]),
        ),
        // ── List ──
        Expanded(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppTheme.accent))
              : _errorMessage != null
                  ? Center(
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                          const Icon(Icons.error_outline,
                              size: 48, color: Colors.red),
                          const SizedBox(height: 12),
                          Text(_errorMessage!,
                              style: const TextStyle(
                                  fontFamily: 'NotoKufi', color: Colors.red),
                              textAlign: TextAlign.center),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _refreshPage,
                            style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primary),
                            child: Text(
                                S.retry.of(context),
                                style: const TextStyle(
                                    fontFamily: 'NotoKufi',
                                    color: Colors.white)),
                          ),
                        ]))
                  : _workUsers.isEmpty
                      ? Center(
                          child: Text(
                          S.workListEmpty.of(context),
                          style: TextStyle(
                              fontFamily: 'NotoKufi',
                              fontSize: 15,
                              color: Colors.grey.shade400),
                        ))
                      : RefreshIndicator(
                          onRefresh: _refreshPage,
                          color: AppTheme.accent,
                          child: ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            // +1 for the trailing loader / end-of-list line.
                            itemCount: _workUsers.length + 1,
                            itemBuilder: (_, i) => i == _workUsers.length
                                ? LoadMoreFooter(
                                    isLoading: _isLoadingMore,
                                    hasMore: _hasMore,
                                    showEndMessage:
                                        _workUsers.length > _pageSize,
                                  )
                                : _buildCard(_workUsers[i], isArabic),
                          ),
                        ),
        ),
      ]),
    );
  }

  // ── Dropdowns ────────────────────────────────────────────

  Widget _subcategoryDropdown(bool isArabic) {
    return DropdownButtonFormField<String>(
      value: (_selectedSubcategoryId?.isEmpty ?? true)
          ? null
          : _selectedSubcategoryId,
      hint: Text(S.workListChooseSection.of(context),
          style: const TextStyle(fontFamily: 'NotoKufi', fontSize: 12)),
      isExpanded: true,
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusSm)),
        isDense: true,
      ),
      items: [
        DropdownMenuItem<String>(
          value: '',
          child: Text(S.workListAllSections.of(context),
              style: const TextStyle(fontFamily: 'NotoKufi', fontSize: 12)),
        ),
        ..._subcategories.map((s) => DropdownMenuItem<String>(
              value: s['id'].toString(),
              child: Text(s['name'] ?? '',
                  style: const TextStyle(fontFamily: 'NotoKufi', fontSize: 12),
                  overflow: TextOverflow.ellipsis),
            )),
      ],
      onChanged: (v) {
        setState(() => _selectedSubcategoryId = v);
        _fetchWorkUsers(subcategoryId: v, city: _selectedCity);
      },
    );
  }

  Widget _cityDropdown(bool isArabic) {
    return DropdownButtonFormField<String>(
      value: (_selectedCity?.isEmpty ?? true) ? null : _selectedCity,
      hint: Text(S.cityLabel.of(context),
          style: const TextStyle(fontFamily: 'NotoKufi', fontSize: 12)),
      isExpanded: true,
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusSm)),
        isDense: true,
      ),
      items: [
        DropdownMenuItem<String>(
          value: 'هەموو شەهرەکان',
          child: Text(S.workListAllCities.of(context),
              style: const TextStyle(fontFamily: 'NotoKufi', fontSize: 12)),
        ),
        ..._cities.map((c) => DropdownMenuItem<String>(
              value: c,
              child: Text(c,
                  style: const TextStyle(fontFamily: 'NotoKufi', fontSize: 12)),
            )),
      ],
      onChanged: (v) {
        setState(() => _selectedCity = v);
        _fetchWorkUsers(subcategoryId: _selectedSubcategoryId, city: v);
      },
    );
  }

  // ── Work user card ───────────────────────────────────────

  Widget _buildCard(Map<String, dynamic> user, bool isArabic) {
    final name = user['name'] ?? '';
    final phone = user['phone_number'] ?? '';
    final location = user['location'] ?? '';
    final subcat = user['subcategory'] ??
        _subcategoryMap[user['sub_category_id']?.toString()] ??
        '';
    final photoUrl = user['photo_url'] as String?;
    final views = user['view_count']?.toString() ?? '0';

    return GestureDetector(
      onTap: () => _openDetails(user),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          boxShadow: AppTheme.elevatedShadow,
        ),
        child: Row(children: [
          // ── Photo ──
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(AppTheme.radiusMd),
              bottomRight: Radius.circular(AppTheme.radiusMd),
            ),
            child: CachedNetworkImage(
              imageUrl: photoUrl ?? '',
              width: 90,
              height: 90,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(
                  width: 90,
                  height: 90,
                  color: Colors.grey.shade100,
                  child: const Icon(Icons.person_rounded,
                      size: 36, color: Colors.grey)),
              errorWidget: (_, __, ___) => Container(
                  width: 90,
                  height: 90,
                  color: Colors.grey.shade100,
                  child: const Icon(Icons.person_rounded,
                      size: 36, color: Colors.grey)),
            ),
          ),
          // ── Info ──
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name + subcat badge
                  Row(children: [
                    Expanded(
                      child: Text(name,
                          style: const TextStyle(
                              fontFamily: 'NotoKufi',
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.black87),
                          overflow: TextOverflow.ellipsis),
                    ),
                    if (subcat.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(subcat,
                            style: const TextStyle(
                                fontFamily: 'NotoKufi',
                                fontSize: 10,
                                color: AppTheme.primary)),
                      ),
                  ]),
                  const SizedBox(height: 5),
                  // Location
                  Row(children: [
                    const Icon(Icons.location_on_rounded,
                        size: 13, color: Colors.grey),
                    const SizedBox(width: 3),
                    Text(location,
                        style: const TextStyle(
                            fontFamily: 'NotoKufi',
                            fontSize: 12,
                            color: Colors.black54)),
                  ]),
                  const SizedBox(height: 8),
                  // Actions row
                  Row(children: [
                    // WhatsApp
                    GestureDetector(
                      onTap: () => _onWhatsApp(user),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: const Row(children: [
                          FaIcon(FontAwesomeIcons.whatsapp,
                              size: 13, color: Colors.green),
                          SizedBox(width: 4),
                          Text('WhatsApp',
                              style: TextStyle(
                                  fontFamily: 'NotoKufi',
                                  fontSize: 11,
                                  color: Colors.green)),
                        ]),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Phone call
                    GestureDetector(
                      onTap: () => _callPhone(phone),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppTheme.accent.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: AppTheme.accent.withOpacity(0.3)),
                        ),
                        child: const Row(children: [
                          Icon(Icons.phone_rounded,
                              size: 13, color: AppTheme.accent),
                          SizedBox(width: 4),
                          Text('تەلەفون',
                              style: TextStyle(
                                  fontFamily: 'NotoKufi',
                                  fontSize: 11,
                                  color: AppTheme.accent)),
                        ]),
                      ),
                    ),
                    const Spacer(),
                    // View count
                    Row(children: [
                      const Icon(Icons.remove_red_eye_rounded,
                          size: 12, color: Colors.grey),
                      const SizedBox(width: 3),
                      Text(views,
                          style: const TextStyle(
                              fontFamily: 'NotoKufi',
                              fontSize: 11,
                              color: Colors.grey)),
                    ]),
                  ]),
                ],
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
