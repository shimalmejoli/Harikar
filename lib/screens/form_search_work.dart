// lib/screens/form_search_work.dart

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../core/app_constants.dart';
import '../core/app_logger.dart';
import '../core/app_strings.dart';
import '../core/app_theme.dart';
import '../main.dart' show LocaleContext;
import '../services/api_service.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/footer_menu.dart';
import 'work_details_page.dart';

class FormSearchWork extends StatefulWidget {
  final int? initialCategoryId;
  const FormSearchWork({this.initialCategoryId, Key? key}) : super(key: key);

  @override
  _FormSearchWorkState createState() => _FormSearchWorkState();
}

class _FormSearchWorkState extends State<FormSearchWork> {
  List<Map<String, dynamic>> _categories = [];
  Map<int, List<Map<String, dynamic>>> _subcategories = {};
  String? _selectedCategoryName;
  bool _isLoading = true;
  bool _showDropdown = true;
  bool _didFetchData = false;
  Locale? _currentLocale;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newLocale = Localizations.localeOf(context);
    if (_currentLocale == null || _currentLocale != newLocale) {
      _currentLocale = newLocale;
      _didFetchData = false;
    }
    if (!_didFetchData) {
      _didFetchData = true;
      _fetchData().then((_) {
        if (!mounted || widget.initialCategoryId == null) return;

        // Shortcut: if the chosen category has exactly one active
        // subcategory, skip this list screen and jump straight to
        // its work-details page. pushReplacement so Back returns
        // to the dashboard, not to a single-item list.
        final activeSubs = (_subcategories[widget.initialCategoryId] ?? [])
            .where((s) => s['is_active'] == true)
            .toList();

        if (activeSubs.length == 1) {
          final only = activeSubs.first;
          AppLogger.info(
              'Single subcategory — auto-opening: ${only['name']}',
              tag: 'SEARCH');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  WorkDetailsPage(subcategoryId: only['id'].toString()),
            ),
          );
          return;
        }

        _setInitialCategory(widget.initialCategoryId!);
        setState(() => _showDropdown = false);
      });
    }
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    AppLogger.info('Fetching categories + subcategories', tag: 'SEARCH');

    final results = await Future.wait([
      ApiService.instance.fetchCategories(),
      ApiService.instance.fetchSubcategories(),
    ]);

    if (!mounted) return;

    final catResp = results[0];
    final subResp = results[1];

    if (catResp.success && subResp.success) {
      final cats = catResp.data!['data'] as List? ?? [];
      final subs = subResp.data!['data'] as List? ?? [];
      AppLogger.info('Loaded ${cats.length} cats, ${subs.length} subs',
          tag: 'SEARCH');

      _categories = cats
          .where((c) => c['is_active'].toString() == '1')
          .map<Map<String, dynamic>>((c) => {
                'id': int.tryParse(c['id'].toString()) ?? 0,
                'name': c['name'],
                'original_name': c['name'],
              })
          .toList();
      _applyCategoryTranslation();

      _subcategories = {};
      for (var s in subs) {
        final catId = int.tryParse(s['category_id'].toString()) ?? 0;
        _subcategories.putIfAbsent(catId, () => []);
        _subcategories[catId]!.add({
          'id': s['id'],
          'name': s['name'],
          'original_name': s['name'],
          'image_url': '${AppConstants.uploadsUrl}${s['image_url']}',
          'is_active': s['is_active'].toString() == '1',
        });
      }
      _applySubcategoryTranslation();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _subcategories.values.expand((l) => l).forEach((sub) {
          precacheImage(NetworkImage(sub['image_url']), context);
        });
      });
    } else {
      AppLogger.error('Fetch failed: ${catResp.error}', tag: 'SEARCH');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(S.searchWorkLoadError.of(context)),
          backgroundColor: AppTheme.error,
        ));
      }
    }

    if (mounted) setState(() => _isLoading = false);
  }

  void _applyCategoryTranslation() {
    final isArabic = context.isArabic;
    const t = {
      "ئەندازیار": "مهندس",
      "مەساح": "مساح",
      "ئامیرە": "مكائن",
      "هوستا": "اسطة",
      "کرێکار": "عامل"
    };
    setState(() {
      _categories = _categories.map((cat) {
        final orig = cat['original_name'].toString().trim();
        cat['name'] = (isArabic && t.containsKey(orig)) ? t[orig]! : orig;
        return cat;
      }).toList();
    });
  }

  void _applySubcategoryTranslation() {
    final isArabic = context.isArabic;
    const t = {
      "شەڤەر": "شفل",
      "کرێکار": "عمال",
      "نەجار": "نجار",
      "مساح": "مساح",
      "کەهرەبای": "كهربائي",
      "حاديله": "ضاغطة التربة",
      "تانکەرا ئاڤا پاقژ": "تنكر ماء",
      "سلنگ": "كرين",
      "قەلابه": "قلاب",
      "گرێدەر": "آلات تسوية الطرق",
      "بەنا": "بناء",
      "سەباخ": "صباغ",
      "لەباخ": "لباخ",
      "سيراميك و كاشي": "سيراميك و أرضيات",
      "مەرمەر": "مرمر",
      "سەقف مەخربی": "صقف مغربي",
      "فلين": "فلين خارجي",
      "حداد": "حداد",
      "مجاري": "مجاري",
    };
    setState(() {
      _subcategories.forEach((_, list) {
        for (var sub in list) {
          final orig = sub['original_name'].toString().trim();
          sub['name'] = (isArabic && t.containsKey(orig)) ? t[orig]! : orig;
        }
      });
    });
  }

  void _setInitialCategory(int id) {
    final cat = _categories.firstWhere((c) => c['id'] == id, orElse: () => {});
    if (cat.isNotEmpty) setState(() => _selectedCategoryName = cat['name']);
  }

  // ── BUILD ────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: S.searchWorkAppBarTitle.of(context),
      bottomNavigationBar: const FooterMenu(),
      body: _isLoading ? _buildLoading(context) : _buildContent(context),
    );
  }

  Widget _buildLoading(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.loadingGradient),
      child: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const CircularProgressIndicator(color: AppTheme.accent),
          const SizedBox(height: 16),
          Text(
            S.searchWorkLoadingData.of(context),
            style: AppTheme.bodySmall.copyWith(fontSize: 14),
          ),
        ]),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final filtered = _selectedCategoryName == null
        ? _categories
        : _categories
            .where((c) => c['name'] == _selectedCategoryName)
            .toList();

    return Column(children: [
      if (_showDropdown) _buildCategoryFilter(context),
      Expanded(
        child: filtered.isEmpty
            ? _buildEmptyState(
                context, S.searchWorkNoSections.of(context))
            : RefreshIndicator(
                onRefresh: _fetchData,
                color: AppTheme.accent,
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 16),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) => _buildCategoryCard(filtered[i]),
                ),
              ),
      ),
    ]);
  }

  // ── Category filter dropdown (sits above the list) ─────────

  Widget _buildCategoryFilter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          boxShadow: AppTheme.softShadow,
        ),
        child: DropdownButtonFormField<String>(
          value: _selectedCategoryName,
          isExpanded: true,
          icon: const Padding(
            padding: EdgeInsets.only(left: 6),
            child: Icon(Icons.keyboard_arrow_down_rounded,
                color: AppTheme.textMuted),
          ),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.filter_list_rounded,
                color: AppTheme.primary, size: 20),
            hintText: S.searchWorkAllSections.of(context),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: false,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          ),
          items: [
            DropdownMenuItem<String>(
              value: null,
              child: Text(S.searchWorkAllSections.of(context),
                  style: const TextStyle(fontFamily: 'NotoKufi', fontSize: 14)),
            ),
            ..._categories.map((cat) => DropdownMenuItem<String>(
                  value: cat['name'],
                  child: Text(cat['name'],
                      style: const TextStyle(
                          fontFamily: 'NotoKufi', fontSize: 14)),
                )),
          ],
          onChanged: (v) => setState(() => _selectedCategoryName = v),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, String text) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.divider.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.search_off_rounded,
                  size: 40, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 16),
            Text(text,
                style: AppTheme.bodyMedium.copyWith(color: AppTheme.textMuted)),
          ],
        ),
      ),
    );
  }

  // ── Category card (gradient header + sub-grid body) ────────

  Widget _buildCategoryCard(Map<String, dynamic> category) {
    final subs = _subcategories[category['id']] ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header — gradient bar with icon + name + count badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              gradient: AppTheme.appBarGradient,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppTheme.radiusLg),
                topRight: Radius.circular(AppTheme.radiusLg),
              ),
            ),
            child: Row(children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.22),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.category_rounded,
                    color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  category['name'],
                  style: AppTheme.headingLarge.copyWith(fontSize: 15),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.22),
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                ),
                child: Text(
                  subs.length.toString(),
                  style: const TextStyle(
                    fontFamily: 'NotoKufi',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ]),
          ),
          // Body — grid of subcategories
          Padding(
            padding: const EdgeInsets.all(12),
            child: subs.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: Text(
                        S.searchWorkNoData.of(context),
                        style: AppTheme.bodySmall,
                      ),
                    ),
                  )
                : GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: subs.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 0.74,
                    ),
                    itemBuilder: (_, idx) => _buildSubcategoryCard(subs[idx]),
                  ),
          ),
        ],
      ),
    );
  }

  // ── Subcategory tile ──────────────────────────────────────

  Widget _buildSubcategoryCard(Map<String, dynamic> sub) {
    final bool isActive = sub['is_active'] as bool? ?? true;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        onTap: isActive
            ? () {
                AppLogger.info('Subcategory: ${sub['name']}', tag: 'SEARCH');
                Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          WorkDetailsPage(subcategoryId: sub['id'].toString()),
                    ));
              }
            : null,
        child: Opacity(
          opacity: isActive ? 1.0 : 0.45,
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              border: Border.all(
                color: isActive
                    ? AppTheme.cardBlue.withOpacity(0.30)
                    : AppTheme.divider,
                width: 1,
              ),
            ),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: sub['image_url'],
                            fit: BoxFit.contain,
                            width: double.infinity,
                            placeholder: (_, __) => const Center(
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: AppTheme.accent),
                              ),
                            ),
                            errorWidget: (_, __, ___) => Icon(
                                Icons.category_rounded,
                                size: 36,
                                color: Colors.grey.shade400),
                            fadeInDuration: const Duration(milliseconds: 200),
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        sub['name'] ?? '',
                        style: const TextStyle(
                          fontFamily: 'NotoKufi',
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                          height: 1.2,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (!isActive)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: AppTheme.softShadow,
                      ),
                      child: const Icon(Icons.lock_rounded,
                          color: AppTheme.error, size: 12),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
