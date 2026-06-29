// lib/screens/WorkDetailsScreen.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../core/app_constants.dart';
import '../core/app_logger.dart';
import '../core/app_strings.dart';
import '../core/app_theme.dart';
import '../main.dart' show LocaleContext;
import '../services/api_service.dart';
import '../widgets/app_scaffold.dart';

class WorkDetailsScreen extends StatefulWidget {
  final String detailId;
  final Map<String, dynamic> user;

  const WorkDetailsScreen({
    required this.detailId,
    required this.user,
    Key? key,
  }) : super(key: key);

  @override
  _WorkDetailsScreenState createState() => _WorkDetailsScreenState();
}

class _WorkDetailsScreenState extends State<WorkDetailsScreen> {
  Map<String, dynamic>? _details;
  List<String> _images = [];
  List<Map<String, dynamic>> _relatedDetails = [];
  bool _isLoading = true;
  bool _isRelatedLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    AppLogger.info('WorkDetailsScreen — id: ${widget.detailId}', tag: 'DETAIL');
    _fetchDetails();
  }

  // ── Fetch main detail ────────────────────────────────────────

  Future<void> _fetchDetails() async {
    AppLogger.info('Fetching detail id: ${widget.detailId}', tag: 'DETAIL');

    final response = await ApiService.instance.fetchDetailById(widget.detailId);
    if (!mounted) return;

    if (response.success && response.data != null) {
      final data = response.data!;
      if (data['status'] == 'success') {
        final list = data['data'];
        if (list is List && list.isNotEmpty) {
          final detail = list[0] as Map<String, dynamic>;
          final imgs = detail['images'];
          AppLogger.info(
              'Detail loaded: ${detail['name']} in ${response.durationMs}ms',
              tag: 'DETAIL');
          setState(() {
            _details = detail;
            _images = imgs is List ? List<String>.from(imgs) : <String>[];
            _isLoading = false;
          });
          final subId = detail['subcategory_id']?.toString();
          if (subId != null && subId.isNotEmpty) {
            _fetchRelatedDetails(subId);
          }
        } else {
          _setError(
              isArabic: _isArabic,
              ar: S.workDetailsNoData.ar,
              ku: S.workDetailsNoData.ku);
        }
      } else {
        AppLogger.warning('Detail API error: ${data['message']}',
            tag: 'DETAIL');
        _setError(
            isArabic: _isArabic,
            ar: data['message'] ?? S.workDetailsLoadFailedAr.ar,
            ku: data['message'] ?? S.workDetailsLoadFailedAr.ku);
      }
    } else {
      AppLogger.error('Detail fetch failed: ${response.error}', tag: 'DETAIL');
      _setError(
          isArabic: _isArabic,
          ar: S.workDetailsLoadException.ar,
          ku: S.workDetailsLoadException.ku);
    }
  }

  void _setError(
      {required bool isArabic, required String ar, required String ku}) {
    if (!mounted) return;
    setState(() {
      _errorMessage = isArabic ? ar : ku;
      _isLoading = false;
    });
  }

  // ── Fetch related details ────────────────────────────────────

  Future<void> _fetchRelatedDetails(String subCategoryId) async {
    setState(() => _isRelatedLoading = true);
    AppLogger.info('Fetching related — subcat: $subCategoryId', tag: 'DETAIL');

    final response = await ApiService.instance.get(
      AppConstants.relatedDetailsEndpoint,
      queryParams: {
        'sub_category_id': subCategoryId,
        'current_detail_id': widget.detailId,
      },
    );
    if (!mounted) return;

    if (response.success && response.data != null) {
      final data = response.data!;
      if (data['status'] == 'success') {
        final list = data['data'];
        AppLogger.info('Related loaded: ${(list as List).length} items',
            tag: 'DETAIL');
        setState(() {
          _relatedDetails = List<Map<String, dynamic>>.from(list);
          _isRelatedLoading = false;
        });
      } else {
        setState(() => _isRelatedLoading = false);
      }
    } else {
      AppLogger.error('Related fetch failed: ${response.error}', tag: 'DETAIL');
      setState(() => _isRelatedLoading = false);
    }
  }

  // ── Helpers ──────────────────────────────────────────────────

  bool get _isArabic => mounted && context.isArabic;

  String _sanitizePhone(String phone) {
    String s = phone.replaceAll(RegExp(r'\D'), '');
    return s.replaceAll(RegExp(r'^0+'), '');
  }

  Future<void> _incrementViewCount() async {
    AppLogger.info('Incrementing view count for ${widget.detailId}',
        tag: 'DETAIL');
    final response =
        await ApiService.instance.incrementViewCount(widget.detailId);
    if (response.success) {
      AppLogger.info('View count incremented', tag: 'DETAIL');
    } else {
      AppLogger.warning('View count failed: ${response.error}', tag: 'DETAIL');
    }
  }

  Future<void> _onCallTapped(String phone) async {
    if (phone.isEmpty) return;
    await _incrementViewCount();
    final uri = Uri(scheme: 'tel', path: _sanitizePhone(phone));
    AppLogger.info('Launching dialer: ${uri.path}', tag: 'DETAIL');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          S.workDetailsCannotOpenDialer.of(context),
          style: const TextStyle(fontFamily: 'NotoKufi'),
        ),
      ));
    }
  }

  Future<void> _onWhatsAppTapped(String phone) async {
    if (phone.isEmpty) return;
    await _incrementViewCount();
    String num = _sanitizePhone(phone);
    if (!num.startsWith('964')) num = '964$num';
    final isArabic = _isArabic;
    final msg = isArabic
        ? 'مرحبا، لقد وجدتك في تطبيق هاريكار. أود التواصل معك.'
        : 'سلاڤ، من دڤێت پەیوەندی تە بکەم . من پێزانین تە دیتینە رێکا پرۆگرامێ هاریکار.';
    final url = 'https://wa.me/$num?text=${Uri.encodeComponent(msg)}';
    AppLogger.info('Launching WhatsApp: $url', tag: 'DETAIL');
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          S.workDetailsCannotOpenWhatsApp.of(context),
          style: const TextStyle(fontFamily: 'NotoKufi'),
        ),
      ));
    }
  }

  void _openImageLightbox(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ImageLightbox(images: _images, initialIndex: index),
      ),
    );
  }

  // ── BUILD ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bool isArabic = _isArabic;

    return AppScaffold(
      title: S.workDetailsTitle.of(context),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.accent))
          : _errorMessage != null
              ? _buildErrorState(isArabic)
              : RefreshIndicator(
                  onRefresh: _fetchDetails,
                  color: AppTheme.accent,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeroSection(isArabic),
                        const SizedBox(height: 14),
                        _buildContactButtons(isArabic),
                        const SizedBox(height: 22),
                        _buildInfoCard(
                          icon: Icons.description_rounded,
                          title: S.workDetailsDescriptionTitle.of(context),
                          content: (_details?['description']?.toString() ?? '')
                                  .trim()
                                  .isEmpty
                              ? S.workDetailsNoDescription.of(context)
                              : _details!['description'].toString(),
                        ),
                        const SizedBox(height: 12),
                        _buildInfoCard(
                          icon: Icons.info_outline_rounded,
                          title: S.workDetailsExtraInfoTitle.of(context),
                          content:
                              (_details?['additional_info']?.toString() ?? '')
                                      .trim()
                                      .isEmpty
                                  ? S.workDetailsNoExtraInfo.of(context)
                                  : _details!['additional_info'].toString(),
                        ),
                        if (_images.isNotEmpty) ...[
                          const SizedBox(height: 26),
                          _buildSectionHeader(
                            S.workDetailsImages.of(context),
                            _images.length,
                          ),
                          const SizedBox(height: 12),
                          _buildImageGallery(),
                        ],
                        const SizedBox(height: 26),
                        _buildSectionHeader(
                          S.workDetailsRelated.of(context),
                          _relatedDetails.length,
                        ),
                        const SizedBox(height: 12),
                        _buildRelatedSection(isArabic),
                      ],
                    ),
                  ),
                ),
    );
  }

  // ── Error state ──────────────────────────────────────────────

  Widget _buildErrorState(bool isArabic) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 64, color: AppTheme.error),
            const SizedBox(height: 16),
            Text(_errorMessage!,
                textAlign: TextAlign.center,
                style: AppTheme.bodyMedium.copyWith(color: AppTheme.error)),
            const SizedBox(height: 20),
            SizedBox(
              width: 200,
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _errorMessage = null;
                  });
                  _fetchDetails();
                },
                icon: const Icon(Icons.refresh_rounded),
                label: Text(S.retry.of(context)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Hero section ─────────────────────────────────────────────

  Widget _buildHeroSection(bool isArabic) {
    final name = _details?['name']?.toString() ??
        S.nameNotAvailable.of(context);
    final subcategory = _details?['subcategory']?.toString() ?? '';
    final location = _details?['location']?.toString() ?? '';
    final phone = _details?['phone_number']?.toString() ?? '';
    final avatarUrl = _images.isNotEmpty ? _images.first : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.appBarGradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: AppTheme.appBarShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAvatar(avatarUrl),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: AppTheme.headingLarge.copyWith(fontSize: 18),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subcategory.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _buildPillBadge(subcategory),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (location.isNotEmpty || phone.isNotEmpty) ...[
            const SizedBox(height: 18),
            Container(height: 1, color: Colors.white.withOpacity(0.18)),
            const SizedBox(height: 14),
            if (location.isNotEmpty)
              _heroInfoRow(Icons.location_on_rounded, location),
            if (location.isNotEmpty && phone.isNotEmpty)
              const SizedBox(height: 10),
            if (phone.isNotEmpty)
              _heroInfoRow(Icons.phone_rounded, phone, monospace: true),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatar(String? url) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.20),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white54, width: 1.5),
      ),
      child: ClipOval(
        child: url == null || url.isEmpty
            ? const Icon(Icons.person_rounded, color: Colors.white, size: 34)
            : CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                width: 64,
                height: 64,
                placeholder: (_, __) => Container(color: Colors.white12),
                errorWidget: (_, __, ___) => const Icon(
                    Icons.person_rounded,
                    color: Colors.white,
                    size: 34),
              ),
      ),
    );
  }

  Widget _buildPillBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.22),
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        border: Border.all(color: Colors.white38, width: 0.8),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'NotoKufi',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _heroInfoRow(IconData icon, String text, {bool monospace = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.white70),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontFamily: monospace ? null : 'NotoKufi',
              fontSize: 13,
              color: Colors.white,
              height: 1.4,
              letterSpacing: monospace ? 0.5 : 0,
            ),
          ),
        ),
      ],
    );
  }

  // ── Contact CTAs ─────────────────────────────────────────────

  Widget _buildContactButtons(bool isArabic) {
    final phone = _details?['phone_number']?.toString() ?? '';
    if (phone.isEmpty) return const SizedBox.shrink();

    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: AppTheme.buttonHeight,
            child: ElevatedButton.icon(
              onPressed: () => _onCallTapped(phone),
              icon: const Icon(Icons.phone_rounded, size: 20),
              label: Text(S.callLabel.of(context)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                elevation: 2,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: SizedBox(
            height: AppTheme.buttonHeight,
            child: ElevatedButton.icon(
              onPressed: () => _onWhatsAppTapped(phone),
              icon: const FaIcon(FontAwesomeIcons.whatsapp, size: 18),
              label: const Text('WhatsApp'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF25D366),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                elevation: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Info card ────────────────────────────────────────────────

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppTheme.primary, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: AppTheme.headingSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  // ── Section header ───────────────────────────────────────────

  Widget _buildSectionHeader(String title, int count) {
    return Row(
      children: [
        Text(title, style: AppTheme.headingMedium),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppTheme.primary.withOpacity(0.10),
            borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          ),
          child: Text(
            count.toString(),
            style: const TextStyle(
              fontFamily: 'NotoKufi',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppTheme.primary,
            ),
          ),
        ),
      ],
    );
  }

  // ── Image gallery ────────────────────────────────────────────

  Widget _buildImageGallery() {
    return SizedBox(
      height: 130,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _images.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final url = _images[i];
          return GestureDetector(
            onTap: () => _openImageLightbox(i),
            child: Hero(
              tag: url,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                child: CachedNetworkImage(
                  imageUrl: url,
                  width: 130,
                  height: 130,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    color: Colors.grey.shade100,
                    child: const Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppTheme.accent),
                      ),
                    ),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    color: Colors.grey.shade100,
                    child: const Icon(Icons.broken_image_rounded,
                        size: 32, color: Colors.grey),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Related section ──────────────────────────────────────────

  Widget _buildRelatedSection(bool isArabic) {
    if (_isRelatedLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
            child: CircularProgressIndicator(color: AppTheme.accent)),
      );
    }
    if (_relatedDetails.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Center(
          child: Text(
            S.workDetailsNoRelated.of(context),
            style: AppTheme.bodySmall,
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: min(3, _relatedDetails.length),
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _buildRelatedCard(_relatedDetails[i], isArabic),
    );
  }

  Widget _buildRelatedCard(Map<String, dynamic> detail, bool isArabic) {
    final imgs = detail['images'];
    final imgUrl = (imgs is List && imgs.isNotEmpty)
        ? imgs[0].toString()
        : null;
    final name =
        detail['name']?.toString() ?? S.nameNotAvailable.of(context);
    final phone = detail['phone_number']?.toString() ?? '';
    final loc = detail['location']?.toString() ??
        S.workDetailsUnspecified.of(context);
    final subcat = detail['subcategory']?.toString() ?? '';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        onTap: () {
          final id = detail['id']?.toString();
          if (id != null && id.isNotEmpty) {
            AppLogger.info('Opening related detail: $id', tag: 'DETAIL');
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => WorkDetailsScreen(detailId: id, user: detail),
              ),
            );
          }
        },
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
                child: SizedBox(
                  width: 60,
                  height: 60,
                  child: imgUrl == null
                      ? Container(
                          color: AppTheme.primary.withOpacity(0.10),
                          child: const Icon(Icons.person_rounded,
                              color: AppTheme.primary, size: 28),
                        )
                      : CachedNetworkImage(
                          imageUrl: imgUrl,
                          fit: BoxFit.cover,
                          placeholder: (_, __) =>
                              Container(color: Colors.grey.shade100),
                          errorWidget: (_, __, ___) => Container(
                            color: AppTheme.primary.withOpacity(0.10),
                            child: const Icon(Icons.person_rounded,
                                color: AppTheme.primary, size: 28),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: AppTheme.headingSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded,
                            size: 13, color: AppTheme.textMuted),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(loc,
                              style: AppTheme.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                    if (subcat.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.10),
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusFull),
                        ),
                        child: Text(
                          subcat,
                          style: const TextStyle(
                            fontFamily: 'NotoKufi',
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (phone.isNotEmpty) ...[
                const SizedBox(width: 8),
                _miniIconButton(
                  icon: FontAwesomeIcons.whatsapp,
                  color: const Color(0xFF25D366),
                  onTap: () => _onWhatsAppTapped(phone),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniIconButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        onTap: onTap,
        child: SizedBox(
          width: 38,
          height: 38,
          child: FaIcon(icon, size: 18, color: color),
        ),
      ),
    );
  }
}

// ── ImageLightbox ─────────────────────────────────────────────

class ImageLightbox extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const ImageLightbox({
    required this.images,
    required this.initialIndex,
    Key? key,
  }) : super(key: key);

  @override
  _ImageLightboxState createState() => _ImageLightboxState();
}

class _ImageLightboxState extends State<ImageLightbox> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _go(int index) {
    if (index < 0 || index >= widget.images.length) return;
    setState(() => _currentIndex = index);
    _pageController.animateToPage(index,
        duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PhotoViewGallery.builder(
            itemCount: widget.images.length,
            pageController: _pageController,
            onPageChanged: (i) => setState(() => _currentIndex = i),
            builder: (_, i) => PhotoViewGalleryPageOptions(
              imageProvider: NetworkImage(widget.images[i]),
              initialScale: PhotoViewComputedScale.contained,
              heroAttributes: PhotoViewHeroAttributes(tag: widget.images[i]),
            ),
            loadingBuilder: (_, __) =>
                const Center(child: CircularProgressIndicator()),
          ),
          // Close button
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            child: _lightboxIconButton(
              icon: Icons.close_rounded,
              onTap: () => Navigator.of(context).pop(),
            ),
          ),
          // Prev
          if (_currentIndex > 0)
            Positioned(
              left: 12,
              top: MediaQuery.of(context).size.height * 0.5 - 24,
              child: _lightboxIconButton(
                icon: Icons.arrow_back_ios_new_rounded,
                onTap: () => _go(_currentIndex - 1),
              ),
            ),
          // Next
          if (_currentIndex < widget.images.length - 1)
            Positioned(
              right: 12,
              top: MediaQuery.of(context).size.height * 0.5 - 24,
              child: _lightboxIconButton(
                icon: Icons.arrow_forward_ios_rounded,
                onTap: () => _go(_currentIndex + 1),
              ),
            ),
          // Counter
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 18,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                ),
                child: Text(
                  '${_currentIndex + 1} / ${widget.images.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'NotoKufi',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _lightboxIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.black.withOpacity(0.55),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}
