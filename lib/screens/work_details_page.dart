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
import 'WorkDetailsScreen.dart';

class WorkDetailsPage extends StatefulWidget {
  final String? subcategoryId;
  const WorkDetailsPage({this.subcategoryId, Key? key}) : super(key: key);

  @override
  _WorkDetailsPageState createState() => _WorkDetailsPageState();
}

class _WorkDetailsPageState extends State<WorkDetailsPage> {
  List<Map<String, dynamic>> _subcategories = [];
  List<Map<String, dynamic>> _allWorkUsers = [];
  List<Map<String, dynamic>> _filteredWorkUsers = [];
  Map<String, String> _subcategoryMap = {};

  int _currentPage = 1;
  int _rowsPerPage = 10;
  int _totalPages = 1;

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

  // ── Fetch work users ─────────────────────────────────────

  Future<void> _fetchWorkUsers({String? subcategoryId, String? city}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    AppLogger.info('Fetching work users — subcat: $subcategoryId city: $city',
        tag: 'WORK_PAGE');

    final r = await ApiService.instance.fetchWorkDetails(
      subcategoryId: subcategoryId,
      city: city,
      lang: context.langCode,
    );
    if (!mounted) return;

    if (r.success && r.data != null) {
      final list =
          (r.data!['data'] as List? ?? []).cast<Map<String, dynamic>>();
      AppLogger.info('Work users loaded: ${list.length}', tag: 'WORK_PAGE');
      setState(() {
        _allWorkUsers = list;
        _applyFilters();
      });
      // Prefetch images in background
      for (final u in list) {
        final img = u['photo_url'] as String?;
        if (img != null && img.isNotEmpty) {
          CachedNetworkImageProvider(img).resolve(const ImageConfiguration());
        }
      }
    } else {
      AppLogger.error('Work users failed: ${r.error}', tag: 'WORK_PAGE');
      setState(() {
        _allWorkUsers = [];
        _filteredWorkUsers = [];
        _totalPages = 1;
        _currentPage = 1;
        _errorMessage = r.error;
      });
    }
    setState(() => _isLoading = false);
  }

  // ── Filter + paginate ────────────────────────────────────

  void _applyFilters() {
    _filteredWorkUsers = _allWorkUsers.where((u) {
      bool ok = true;
      if (_selectedSubcategoryId?.isNotEmpty == true) {
        ok = ok && u['sub_category_id']?.toString() == _selectedSubcategoryId;
      }
      if (_selectedCity?.isNotEmpty == true &&
          _selectedCity != 'هەموو شەهرەکان') {
        ok = ok && u['location']?.toString() == _selectedCity;
      }
      return ok;
    }).toList();

    _totalPages =
        ((_filteredWorkUsers.length / _rowsPerPage).ceil()).clamp(1, 999999);
    if (_currentPage > _totalPages) _currentPage = _totalPages;
    setState(() {});
  }

  List<Map<String, dynamic>> get _currentPage_ {
    final start = (_currentPage - 1) * _rowsPerPage;
    if (start >= _filteredWorkUsers.length) return [];
    final end = (start + _rowsPerPage).clamp(0, _filteredWorkUsers.length);
    return _filteredWorkUsers.sublist(start, end);
  }

  // ── Actions ──────────────────────────────────────────────

  Future<void> _openDetails(Map<String, dynamic> user) async {
    final id = user['id']?.toString();
    if (id?.isNotEmpty == true) {
      await Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => WorkDetailsScreen(detailId: id!, user: user)));
      _refreshPage();
    }
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

  void _refreshPage() {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    _fetchWorkUsers(subcategoryId: _selectedSubcategoryId, city: _selectedCity)
        .then((_) => setState(() => _isLoading = false));
  }

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
          child: Row(children: [
            Expanded(child: _subcategoryDropdown(isArabic)),
            const SizedBox(width: 10),
            Expanded(child: _cityDropdown(isArabic)),
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
                  : _currentPage_.isEmpty
                      ? Center(
                          child: Text(
                          S.workListEmpty.of(context),
                          style: TextStyle(
                              fontFamily: 'NotoKufi',
                              fontSize: 15,
                              color: Colors.grey.shade400),
                        ))
                      : RefreshIndicator(
                          onRefresh: () async => _refreshPage(),
                          color: AppTheme.accent,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: _currentPage_.length,
                            itemBuilder: (_, i) =>
                                _buildCard(_currentPage_[i], isArabic),
                          ),
                        ),
        ),
        // ── Pagination footer ──
        _buildFooter(isArabic),
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
        setState(() {
          _selectedSubcategoryId = v;
          _currentPage = 1;
        });
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
        setState(() {
          _selectedCity = v;
          _currentPage = 1;
        });
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

  // ── Pagination footer ────────────────────────────────────

  // ── Pagination footer (modern design) ────────────────────
  // Layout (RTL):
  //   ┌──────────────────────────────────────────────┐
  //   │  [10 ▼]               ◄  1 / 5  ►   50 ⋅ کۆ │
  //   └──────────────────────────────────────────────┘
  // Rows-per-page on one side, page navigator + total count on
  // the other. Bottom safe area is respected so the bar sits
  // above the system gesture/nav bar on mobile.
  Widget _buildFooter(bool isArabic) {
    final canPrev = _currentPage > 1;
    final canNext = _currentPage < _totalPages;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        boxShadow: AppTheme.bottomNavShadow,
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildRowsPerPagePill(isArabic),
              _buildPageNavigator(canPrev, canNext, isArabic),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRowsPerPagePill(bool isArabic) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        border: Border.all(color: AppTheme.divider, width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              S.workListShowLabel.of(context),
              style: const TextStyle(
                fontFamily: 'NotoKufi',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.circular(AppTheme.radiusFull),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: _rowsPerPage,
                isDense: true,
                iconSize: 16,
                icon: const Padding(
                  padding: EdgeInsets.only(right: 2),
                  child: Icon(Icons.keyboard_arrow_down_rounded,
                      color: Colors.white),
                ),
                dropdownColor: AppTheme.surface,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                style: const TextStyle(
                  fontFamily: 'NotoKufi',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
                selectedItemBuilder: (_) => [10, 20, 50]
                    .map((r) => Center(
                          child: Text(
                            '$r',
                            style: const TextStyle(
                              fontFamily: 'NotoKufi',
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ))
                    .toList(),
                items: [10, 20, 50]
                    .map((r) => DropdownMenuItem(
                          value: r,
                          child: Text(
                            '$r',
                            style: const TextStyle(
                              fontFamily: 'NotoKufi',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) {
                    setState(() {
                      _rowsPerPage = v;
                      _currentPage = 1;
                    });
                    _applyFilters();
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageNavigator(bool canPrev, bool canNext, bool isArabic) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        border: Border.all(color: AppTheme.divider, width: 1),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // chevron_right visually points → which is "back/previous"
          // in RTL (toward the start of the reading flow).
          _navIconButton(
            icon: Icons.chevron_right_rounded,
            enabled: canPrev,
            onTap: () => setState(() => _currentPage--),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$_currentPage / $_totalPages',
                  style: const TextStyle(
                    fontFamily: 'NotoKufi',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                    height: 1.1,
                  ),
                ),
                Text(
                  '${_filteredWorkUsers.length} ${S.workListResultsSuffix.of(context)}',
                  style: const TextStyle(
                    fontFamily: 'NotoKufi',
                    fontSize: 9,
                    color: AppTheme.textMuted,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          _navIconButton(
            icon: Icons.chevron_left_rounded,
            enabled: canNext,
            onTap: () => setState(() => _currentPage++),
          ),
        ],
      ),
    );
  }

  Widget _navIconButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return Material(
      color: enabled ? AppTheme.primary : AppTheme.divider.withOpacity(0.5),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: enabled ? onTap : null,
        child: SizedBox(
          width: 34,
          height: 34,
          child: Icon(
            icon,
            size: 20,
            color: enabled ? Colors.white : AppTheme.textMuted,
          ),
        ),
      ),
    );
  }
}
