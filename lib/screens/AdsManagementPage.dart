// lib/screens/AdsManagementPage.dart

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../core/app_constants.dart';
import '../core/app_logger.dart';
import '../core/app_strings.dart';
import '../core/app_theme.dart';
import '../services/api_service.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/branded_app_bar.dart';
import 'SelectDetailPage.dart';

class AdsManagementPage extends StatefulWidget {
  const AdsManagementPage({Key? key}) : super(key: key);

  @override
  _AdsManagementPageState createState() => _AdsManagementPageState();
}

class _AdsManagementPageState extends State<AdsManagementPage> {
  List<Map<String, dynamic>> _ads = [];
  List<Map<String, dynamic>> _filteredAds = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    AppLogger.info('AdsManagementPage init', tag: 'ADS');
    _fetchAds();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final q = _searchController.text.trim().toLowerCase();
    setState(() {
      _filteredAds = q.isEmpty
          ? List.from(_ads)
          : _ads.where((item) {
              final name = (item['name'] as String).toLowerCase();
              final phone = (item['contact_number'] as String).toLowerCase();
              return name.contains(q) || phone.contains(q);
            }).toList();
    });
  }

  Future<void> _fetchAds() async {
    setState(() => _isLoading = true);
    AppLogger.info('Fetching ads...', tag: 'ADS');

    final response = await ApiService.instance.fetchSlideshow();
    if (!mounted) return;

    if (response.success && response.data != null) {
      final list =
          (response.data!['data'] as List? ?? []).cast<Map<String, dynamic>>();
      var adsList = list
          .map((item) => {
                'id': item['id'].toString(),
                'name': item['name'] ?? '',
                'contact_number': item['phone_number'] ?? '',
                'photo_url': item['photo_url'] ?? '',
              })
          .toList();
      if (adsList.length > 5) adsList = adsList.sublist(0, 5);
      AppLogger.info('Ads loaded: ${adsList.length}', tag: 'ADS');
      setState(() {
        _ads = adsList;
        _filteredAds = List.from(_ads);
      });
    } else {
      AppLogger.error('Ads fetch failed: ${response.error}', tag: 'ADS');
      setState(() {
        _ads = [];
        _filteredAds = [];
      });
    }
    setState(() => _isLoading = false);
  }

  Future<void> _deleteAd(String id) async {
    AppLogger.info('Deleting ad id: $id', tag: 'ADS');

    final response = await ApiService.instance.post(
      AppConstants.updateAdsStatusEndpoint,
      fields: {'id': id, 'ads': '0'},
    );
    if (!mounted) return;

    if (response.success) {
      AppLogger.info('Ad deleted: $id', tag: 'ADS');
      _fetchAds();
    } else {
      AppLogger.error('Delete ad failed: ${response.error}', tag: 'ADS');
      _snack(S.adsDeleteFailed.of(context));
    }
  }

  void _confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text(S.adsConfirmDeleteTitle.of(ctx)),
          content: Text(S.adsConfirmDeleteContent.of(ctx)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(S.adsCancelButton.of(ctx)),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                _deleteAd(id);
              },
              icon: const Icon(Icons.delete_rounded, size: 16),
              label: Text(S.adsDeleteButton.of(ctx)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.error,
                minimumSize: const Size(0, 40),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addAd() async {
    if (_ads.length >= 5) {
      _snack(S.adsLimitReached.of(context), color: Colors.orange);
      return;
    }

    final result = await Navigator.push<Map<String, dynamic>>(
        context, MaterialPageRoute(builder: (_) => SelectDetailPage()));

    if (result != null && result.containsKey('id') && mounted) {
      final detailId = result['id'].toString();
      AppLogger.info('Adding ad for detail: $detailId', tag: 'ADS');

      final response = await ApiService.instance.post(
        AppConstants.updateAdsStatusEndpoint,
        fields: {'id': detailId, 'ads': '1'},
      );
      if (!mounted) return;

      if (response.success) {
        AppLogger.info('Ad added successfully', tag: 'ADS');
        _fetchAds();
      } else {
        _snack(S.adsAddFailed.of(context));
      }
    }
  }

  void _snack(String msg, {Color? color}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color ?? AppTheme.error,
    ));
  }

  // ── BUILD ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      titleWidget: _buildSearchField(context),
      actions: [
        BrandedAppBarAction(
          icon: Icons.add_rounded,
          tooltip: S.adsAddTooltip.of(context),
          onPressed: _addAd,
        ),
      ],
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.accent))
          : _filteredAds.isEmpty
              ? _buildEmptyState(context)
              : RefreshIndicator(
                  onRefresh: _fetchAds,
                  color: AppTheme.accent,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
                    itemCount: _filteredAds.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _buildAdCard(_filteredAds[i]),
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
        controller: _searchController,
        style: const TextStyle(
            color: Colors.white, fontFamily: 'NotoKufi', fontSize: 14),
        cursorColor: Colors.white,
        decoration: InputDecoration(
          hintText: S.adsSearchHint.of(context),
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
              child: Icon(Icons.campaign_outlined,
                  size: 40, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 16),
            Text(
              S.adsEmpty.of(context),
              style: AppTheme.bodyMedium.copyWith(color: AppTheme.textMuted),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: 200,
              child: ElevatedButton.icon(
                onPressed: _addAd,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(S.adsAddTooltip.of(context)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdCard(Map<String, dynamic> ad) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: AppTheme.softShadow,
      ),
      child: Row(
        children: [
          // Photo on the start side (right in RTL).
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(AppTheme.radiusMd),
              bottomRight: Radius.circular(AppTheme.radiusMd),
            ),
            child: CachedNetworkImage(
              imageUrl: ad['photo_url'],
              width: 84,
              height: 84,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(
                width: 84,
                height: 84,
                color: Colors.grey.shade100,
              ),
              errorWidget: (_, __, ___) => Container(
                width: 84,
                height: 84,
                color: Colors.grey.shade100,
                child: Icon(Icons.image_rounded,
                    color: Colors.grey.shade400),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ad['name'],
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
                        ad['contact_number'],
                        style: AppTheme.bodySmall.copyWith(fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ]),
                  const SizedBox(height: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.success.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.campaign_rounded,
                            size: 11, color: AppTheme.success),
                        const SizedBox(width: 4),
                        Text(
                          S.adsActiveBadge.of(context),
                          style: const TextStyle(
                            fontFamily: 'NotoKufi',
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.success,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Delete pill button
          Padding(
            padding: const EdgeInsets.only(right: 8, left: 8),
            child: Material(
              color: AppTheme.error.withOpacity(0.10),
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => _confirmDelete(ad['id']),
                child: const SizedBox(
                  width: 38,
                  height: 38,
                  child: Icon(Icons.delete_outline_rounded,
                      color: AppTheme.error, size: 20),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
