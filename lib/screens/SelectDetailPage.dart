// lib/screens/SelectDetailPage.dart

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../core/app_constants.dart';
import '../core/app_logger.dart';
import '../core/app_strings.dart';
import '../core/app_theme.dart';
import '../services/api_service.dart';
import '../widgets/app_scaffold.dart';

class SelectDetailPage extends StatefulWidget {
  const SelectDetailPage({Key? key}) : super(key: key);
  @override
  _SelectDetailPageState createState() => _SelectDetailPageState();
}

class _SelectDetailPageState extends State<SelectDetailPage> {
  List<Map<String, dynamic>> _all = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _isLoading = true;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchDetails();
    _searchCtrl.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_onSearch);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearch() {
    final q = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? List.from(_all)
          : _all.where((d) {
              return (d['name'] as String).toLowerCase().contains(q) ||
                  (d['contact_number'] as String).toLowerCase().contains(q);
            }).toList();
    });
  }

  Future<void> _fetchDetails() async {
    setState(() => _isLoading = true);
    AppLogger.info('Fetching available details for ads', tag: 'SELECT_DETAIL');

    final response =
        await ApiService.instance.get(AppConstants.availableDetailsEndpoint);
    if (!mounted) return;

    if (response.success && response.data != null) {
      final list =
          (response.data!['data'] as List? ?? []).cast<Map<String, dynamic>>();
      AppLogger.info('Available details: ${list.length}', tag: 'SELECT_DETAIL');
      final mapped = list
          .map((item) => {
                'id': item['id'].toString(),
                'name': item['name'] ?? '',
                'contact_number': item['phone_number'] ?? '',
                'photo_url': item['photo_url'] ?? '',
                'description': item['description'] ?? '',
              })
          .toList();
      setState(() {
        _all = mapped;
        _filtered = List.from(_all);
      });
    } else {
      AppLogger.error('Available details failed: ${response.error}',
          tag: 'SELECT_DETAIL');
      setState(() {
        _all = [];
        _filtered = [];
      });
    }
    setState(() => _isLoading = false);
  }

  // ── BUILD ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      titleWidget: _buildSearchField(context),
      // No drawer — this is a picker pushed onto the stack from
      // AdsManagementPage; back arrow handles dismissal.
      showDrawer: false,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.accent))
          : _filtered.isEmpty
              ? _buildEmptyState(context)
              : RefreshIndicator(
                  onRefresh: _fetchDetails,
                  color: AppTheme.accent,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
                    itemCount: _filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _buildCard(_filtered[i]),
                  ),
                ),
    );
  }

  Widget _buildSearchField(BuildContext context) {
    return Container(
      height: 38,
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: TextField(
        controller: _searchCtrl,
        style: const TextStyle(
            color: Colors.white, fontFamily: 'NotoKufi', fontSize: 14),
        cursorColor: Colors.white,
        decoration: InputDecoration(
          hintText: S.selectDetailSearchHint.of(context),
          hintStyle: const TextStyle(
              color: Colors.white60, fontFamily: 'NotoKufi', fontSize: 13),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          filled: false,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
          prefixIcon: const Icon(Icons.search_rounded,
              color: Colors.white70, size: 18),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
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
            Text(
              S.selectDetailEmpty.of(context),
              style: AppTheme.bodyMedium.copyWith(color: AppTheme.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> d) {
    final desc = (d['description'] as String).trim();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        onTap: () => Navigator.pop(context, d),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            boxShadow: AppTheme.softShadow,
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                child: CachedNetworkImage(
                  imageUrl: d['photo_url'],
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                      width: 60, height: 60, color: Colors.grey.shade100),
                  errorWidget: (_, __, ___) => Container(
                    width: 60,
                    height: 60,
                    color: AppTheme.primary.withOpacity(0.10),
                    child: const Icon(Icons.person_rounded,
                        color: AppTheme.primary, size: 28),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      d['name'],
                      style: AppTheme.headingSmall.copyWith(fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(children: [
                      const Icon(Icons.phone_rounded,
                          size: 12, color: AppTheme.textMuted),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          d['contact_number'],
                          style: AppTheme.bodySmall.copyWith(fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ]),
                    if (desc.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        desc,
                        style: AppTheme.bodySmall.copyWith(
                          fontSize: 11,
                          color: AppTheme.textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(right: 4, left: 4),
                child: Icon(Icons.add_circle_rounded,
                    color: AppTheme.primary, size: 26),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
