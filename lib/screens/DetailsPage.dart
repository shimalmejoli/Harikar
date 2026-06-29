// lib/screens/DetailsPage.dart

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../core/app_constants.dart';
import '../core/app_logger.dart';
import '../core/app_strings.dart';
import '../core/app_theme.dart';
import '../main.dart' show LocaleContext;
import '../services/api_service.dart';
import '../widgets/app_scaffold.dart';
import 'UpdateDetailsPage.dart';

class DetailsPage extends StatefulWidget {
  const DetailsPage({Key? key}) : super(key: key);
  @override
  _DetailsPageState createState() => _DetailsPageState();
}

class _DetailsPageState extends State<DetailsPage> {
  List<dynamic> _details = [];
  List<dynamic> _filteredDetails = [];
  List<String> _userNames = [];
  List<String> _subCatNames = [];

  String? _selectedUser;
  String? _selectedSubCat;
  final _searchCtrl = TextEditingController();

  bool _isLoading = true;
  bool _didFetch = false;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_applyFilters);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didFetch) {
      _didFetch = true;
      _fetchDetails();
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchDetails() async {
    setState(() => _isLoading = true);
    AppLogger.info('Fetching all details', tag: 'DETAILS_PAGE');

    final response =
        await ApiService.instance.get(AppConstants.getDetailsEndpoint);
    if (!mounted) return;

    if (response.success && response.data != null) {
      final data = response.data!;
      if (data['status'] == 'success') {
        AppLogger.info('Details loaded: ${(data['data'] as List).length}',
            tag: 'DETAILS_PAGE');
        setState(() {
          _details = data['data'] as List;
          _filteredDetails = _details;
          _extractDropdowns();
          _isLoading = false;
        });
      } else {
        AppLogger.error('Details API error: ${data['message']}',
            tag: 'DETAILS_PAGE');
        setState(() => _isLoading = false);
      }
    } else {
      AppLogger.error('Details fetch failed: ${response.error}',
          tag: 'DETAILS_PAGE');
      setState(() => _isLoading = false);
    }
  }

  void _extractDropdowns() {
    _userNames = _details
        .map((i) => i['user_name']?.toString() ?? '')
        .toSet()
        .where((s) => s.isNotEmpty)
        .toList();
    _subCatNames = _details
        .map((i) => i['sub_category_name']?.toString() ?? '')
        .toSet()
        .where((s) => s.isNotEmpty)
        .toList();
  }

  void _applyFilters() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filteredDetails = _details.where((item) {
        final matchUser =
            _selectedUser == null || item['user_name'] == _selectedUser;
        final matchSubCat = _selectedSubCat == null ||
            item['sub_category_name'] == _selectedSubCat;
        final matchSearch = q.isEmpty ||
            (item['name']?.toString().toLowerCase().contains(q) ?? false) ||
            (item['user_name']?.toString().toLowerCase().contains(q) ?? false);
        return matchUser && matchSubCat && matchSearch;
      }).toList();
    });
  }

  Future<void> _deleteDetail(String id, bool isArabic) async {
    AppLogger.info('Deleting detail id: $id', tag: 'DETAILS_PAGE');
    final response = await ApiService.instance.post(
      AppConstants.deleteDetailsEndpoint,
      fields: {'id': id},
    );
    if (!mounted) return;
    if (response.success) {
      _snack(
          S.detailsDeleteSuccess.of(context),
          success: true);
      _fetchDetails();
    } else {
      _snack(response.error ?? 'Error');
    }
  }

  void _confirmDelete(String id, bool isArabic) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
        title: Text(S.detailsDeleteTitle.of(ctx),
            style: const TextStyle(fontFamily: 'NotoKufi')),
        content: Text(
          S.detailsDeleteContent.of(ctx),
          style: const TextStyle(fontFamily: 'NotoKufi'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(S.no.of(ctx),
                  style: const TextStyle(
                      fontFamily: 'NotoKufi', color: AppTheme.primary))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              _deleteDetail(id, isArabic);
            },
            child: Text(S.yes.of(ctx),
                style: const TextStyle(
                    fontFamily: 'NotoKufi', color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _snack(String msg, {bool success = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontFamily: 'NotoKufi')),
      backgroundColor: success ? Colors.green : AppTheme.error,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = context.isArabic;
    return AppScaffold(
      titleWidget: _buildSearchField(isArabic),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.accent))
          : Column(children: [
              _buildFilters(isArabic),
              Expanded(
                child: _filteredDetails.isEmpty
                    ? Center(
                        child: Text(
                            S.detailsEmpty.of(context),
                            style: const TextStyle(
                                fontFamily: 'NotoKufi',
                                fontSize: 16,
                                color: Colors.grey)))
                    : RefreshIndicator(
                        onRefresh: _fetchDetails,
                        color: AppTheme.accent,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _filteredDetails.length,
                          itemBuilder: (_, i) =>
                              _buildDetailCard(_filteredDetails[i], isArabic),
                        ),
                      ),
              ),
            ]),
    );
  }

  Widget _buildSearchField(bool isArabic) {
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
          hintText: S.detailsSearchHint.of(context),
          hintStyle: const TextStyle(
              color: Colors.white60, fontFamily: 'NotoKufi', fontSize: 13),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          filled: false,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
          prefixIcon:
              const Icon(Icons.search_rounded, color: Colors.white70, size: 18),
        ),
      ),
    );
  }

  Widget _buildFilters(bool isArabic) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Row(children: [
        Expanded(
            child: _dropdown(
          S.detailsFilterByUser.of(context),
          [null, ..._userNames],
          _selectedUser,
          (v) => setState(() {
            _selectedUser = v;
            _applyFilters();
          }),
          allLabel: S.detailsAllUsers.of(context),
        )),
        const SizedBox(width: 10),
        Expanded(
            child: _dropdown(
          S.detailsFilterByCategory.of(context),
          [null, ..._subCatNames],
          _selectedSubCat,
          (v) => setState(() {
            _selectedSubCat = v;
            _applyFilters();
          }),
          allLabel: S.detailsAllCategories.of(context),
        )),
      ]),
    );
  }

  Widget _dropdown(String label, List<String?> items, String? value,
      ValueChanged<String?> onChange,
      {String allLabel = 'All'}) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontFamily: 'NotoKufi', fontSize: 12),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusSm)),
      ),
      items: items
          .map((s) => DropdownMenuItem<String>(
                value: s,
                child: Text(s ?? allLabel,
                    style:
                        const TextStyle(fontFamily: 'NotoKufi', fontSize: 12),
                    overflow: TextOverflow.ellipsis),
              ))
          .toList(),
      onChanged: onChange,
    );
  }

  Widget _buildDetailCard(Map<String, dynamic> item, bool isArabic) {
    final isActive = item['is_active'] == '1' || item['is_active'] == 1;
    final images = item['images'] as List? ?? [];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
      elevation: 3,
      child: Column(children: [
        // ── Header ──
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            gradient: AppTheme.appBarGradient,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(AppTheme.radiusMd),
              topRight: Radius.circular(AppTheme.radiusMd),
            ),
          ),
          child: Row(children: [
            const Icon(Icons.person_rounded, color: Colors.white70, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                  item['user_name'] ?? S.detailsNoName.of(context),
                  style: const TextStyle(
                      fontFamily: 'NotoKufi',
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                  overflow: TextOverflow.ellipsis),
            ),
            Icon(isActive ? Icons.check_circle_rounded : Icons.cancel_rounded,
                color: isActive ? Colors.greenAccent : Colors.redAccent,
                size: 20),
            IconButton(
              icon:
                  const Icon(Icons.edit_rounded, color: Colors.white, size: 18),
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(),
              onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => UpdateDetailsPage(
                              detailId: item['id'].toString())))
                  .then((_) => _fetchDetails()),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded,
                  color: Colors.white70, size: 18),
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(),
              onPressed: () => _confirmDelete(item['id'].toString(), isArabic),
            ),
          ]),
        ),
        // ── Body ──
        Padding(
          padding: const EdgeInsets.all(14),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _row(
                Icons.category_rounded,
                S.detailsSubcategoryType.of(context),
                item['sub_category_name']),
            _row(Icons.label_rounded, S.detailsName.of(context), item['name']),
            _row(
                Icons.phone_rounded,
                S.detailsContact.of(context),
                item['contact_number']),
            _row(Icons.location_on_rounded, S.detailsLocation.of(context),
                item['location']),
            _row(Icons.description_rounded, S.detailsDescription.of(context),
                item['description']),
            if (images.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(S.detailsImagesLabel.of(context),
                  style: const TextStyle(
                      fontFamily: 'NotoKufi',
                      fontWeight: FontWeight.bold,
                      fontSize: 13)),
              const SizedBox(height: 8),
              SizedBox(
                height: 90,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: images.length,
                  itemBuilder: (_, i) => Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: '${AppConstants.uploadsUrl}${images[i]}',
                        width: 90,
                        height: 90,
                        fit: BoxFit.cover,
                        placeholder: (_, __) =>
                            Container(color: Colors.grey.shade100),
                        errorWidget: (_, __, ___) => Container(
                            color: Colors.grey.shade100,
                            child: const Icon(Icons.broken_image_rounded,
                                color: Colors.grey)),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ]),
        ),
      ]),
    );
  }

  Widget _row(IconData icon, String label, dynamic value) {
    final v = value?.toString() ?? '—';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: AppTheme.primary, size: 16),
        const SizedBox(width: 8),
        Text('$label: ',
            style: const TextStyle(
                fontFamily: 'NotoKufi',
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.black54)),
        Expanded(
            child: Text(v,
                style: const TextStyle(fontFamily: 'NotoKufi', fontSize: 13))),
      ]),
    );
  }
}
