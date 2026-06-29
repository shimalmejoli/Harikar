// lib/screens/add_subcategory_screen.dart

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../core/app_constants.dart';
import '../core/app_logger.dart';
import '../core/app_strings.dart';
import '../core/app_theme.dart';
import '../main.dart' show LocaleContext;
import '../services/api_service.dart';
import '../widgets/app_scaffold.dart';

class AddSubCategoryScreen extends StatefulWidget {
  const AddSubCategoryScreen({Key? key}) : super(key: key);
  @override
  _AddSubCategoryScreenState createState() => _AddSubCategoryScreenState();
}

class _AddSubCategoryScreenState extends State<AddSubCategoryScreen> {
  final _subCategoryController = TextEditingController();
  List<dynamic> _categories = [];
  List<dynamic> _subCategories = [];
  String? _selectedCategoryId;
  XFile? _selectedImage;
  Uint8List? _webImageBytes;
  bool _isLoading = false;
  bool _didFetch = false;
  Map<String, List<dynamic>> _grouped = {};

  @override
  void dispose() {
    _subCategoryController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didFetch) {
      _didFetch = true;
      _fetchCategories();
      _fetchSubCategories();
    }
  }

  Future<void> _fetchCategories() async {
    final r = await ApiService.instance.fetchCategories();
    if (!mounted) return;
    if (r.success) setState(() => _categories = r.data!['data'] as List? ?? []);
  }

  Future<void> _fetchSubCategories() async {
    // `fetchSubcategories()` already cache-busts the GET — see the
    // `_cacheBust()` helper in ApiService.
    final r = await ApiService.instance.fetchSubcategories();
    if (!mounted) return;
    if (r.success) {
      setState(() {
        _subCategories = r.data!['data'] as List? ?? [];
        _groupByCategory();
      });
    }
  }

  void _groupByCategory() {
    final Map<String, List<dynamic>> g = {};
    for (var s in _subCategories) {
      final id = s['category_id'].toString();
      g.putIfAbsent(id, () => []).add(s);
    }
    setState(() => _grouped = g);
  }

  Future<void> _pickImage() async {
    final f = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (f != null) {
      setState(() => _selectedImage = f);
      if (kIsWeb) {
        final b = await f.readAsBytes();
        setState(() => _webImageBytes = b);
      }
    }
  }

  Future<void> _addSubCategory() async {
    final isArabic = context.isArabic;
    final name = _subCategoryController.text.trim();
    if (name.isEmpty || _selectedCategoryId == null) {
      _snack(S.addSubcategoryFieldsRequired.of(context));
      return;
    }
    setState(() => _isLoading = true);
    AppLogger.info('Adding subcategory: $name', tag: 'ADD_SUB');

    try {
      final request = http.MultipartRequest(
          'POST', Uri.parse(AppConstants.addSubcategoryEndpoint));
      request.fields['category_id'] = _selectedCategoryId!;
      request.fields['name'] = name;

      if (kIsWeb && _webImageBytes != null) {
        request.files.add(http.MultipartFile.fromBytes('image', _webImageBytes!,
            filename: 'upload.png'));
      } else if (!kIsWeb && _selectedImage != null) {
        request.files.add(
            await http.MultipartFile.fromPath('image', _selectedImage!.path));
      }

      final resp = await request.send();
      final body = await resp.stream.bytesToString();
      final decoded = jsonDecode(body);

      if (!mounted) return;
      if (decoded['status'] == 'success') {
        AppLogger.info('Subcategory added', tag: 'ADD_SUB');
        _snack(decoded['message'], success: true);
        _subCategoryController.clear();
        setState(() {
          _selectedImage = null;
          _webImageBytes = null;
        });
        _fetchSubCategories();
      } else {
        _snack(decoded['message']);
      }
    } catch (e) {
      AppLogger.error('Add subcategory error: $e', tag: 'ADD_SUB');
      _snack(isArabic ? 'حدث خطأ: $e' : 'خەلەتیك ڕوودا: $e');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _deleteSubCategory(String id) async {
    final r = await ApiService.instance
        .post(AppConstants.deleteSubcategoryEndpoint, jsonBody: {'id': id});
    if (!mounted) return;
    if (r.success) {
      _snack(r.data?['message'] ?? 'Deleted', success: true);
      _fetchSubCategories();
    } else {
      _snack(r.error ?? 'Error');
    }
  }

  Future<void> _toggleStatus(String id) async {
    AppLogger.info('Toggling subcategory status: $id', tag: 'ADD_SUB');
    final r = await ApiService.instance
        .post(AppConstants.toggleSubcategoryEndpoint, fields: {'id': id});
    if (!mounted) return;

    AppLogger.info(
      'Toggle response — success: ${r.success}, '
      'data: ${r.data}, error: ${r.error}',
      tag: 'ADD_SUB',
    );

    // Always refetch so the UI reflects whatever the server actually
    // has now — same reasoning as add_category_screen._toggleCategoryStatus.
    await _fetchSubCategories();

    if (!r.success) {
      _snack(r.error ?? 'Toggle failed');
    }
  }

  Future<void> _confirmDelete(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text(S.addSubcategoryConfirmTitle.of(ctx)),
          content: Text(S.addSubcategoryConfirmContent.of(ctx)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(S.no.of(ctx)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.error,
                  minimumSize: const Size(80, 40)),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(S.yes.of(ctx)),
            ),
          ],
        ),
      ),
    );
    if (ok == true) _deleteSubCategory(id);
  }

  void _showEditDialog(Map<String, dynamic> sub) {
    final ctrl = TextEditingController(text: sub['name']);
    XFile? newImg;
    Uint8List? newBytes;

    Future<void> update() async {
      AppLogger.info('Updating subcategory: ${sub['id']}', tag: 'ADD_SUB');
      try {
        final request = http.MultipartRequest(
            'POST', Uri.parse(AppConstants.updateSubcategoryEndpoint));
        request.fields['id'] = sub['id'].toString();
        request.fields['name'] = ctrl.text.trim();
        if (newImg != null) {
          if (kIsWeb && newBytes != null) {
            request.files.add(http.MultipartFile.fromBytes('image', newBytes!,
                filename: newImg!.name));
          } else if (!kIsWeb) {
            request.files
                .add(await http.MultipartFile.fromPath('image', newImg!.path));
          }
        }
        final resp = await request.send();
        final body = await resp.stream.bytesToString();
        final decoded = jsonDecode(body);
        if (!mounted) return;
        if (decoded['status'] == 'success') {
          _snack(decoded['message'], success: true);
          _fetchSubCategories();
          Navigator.pop(context);
        } else {
          _snack(decoded['message']);
        }
      } catch (e) {
        _snack('$e');
      }
    }

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: Text(S.addSubcategoryEditTitle.of(ctx)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: ctrl,
                    decoration: InputDecoration(
                      labelText: S.addSubcategoryEditNameLabel.of(ctx),
                      prefixIcon: const Icon(Icons.label_rounded,
                          color: AppTheme.primary),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Center(
                    child: GestureDetector(
                      onTap: () async {
                        final f = await ImagePicker()
                            .pickImage(source: ImageSource.gallery);
                        if (f != null) {
                          newImg = f;
                          if (kIsWeb) newBytes = await f.readAsBytes();
                          setS(() {});
                        }
                      },
                      child: Container(
                        height: 96,
                        width: 96,
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: AppTheme.primary.withOpacity(0.4)),
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusMd),
                          color: AppTheme.background,
                          image: newImg != null
                              ? DecorationImage(
                                  image: kIsWeb
                                      ? MemoryImage(newBytes!)
                                      : FileImage(File(newImg!.path))
                                          as ImageProvider,
                                  fit: BoxFit.cover)
                              : (sub['image_url'] != null
                                  ? DecorationImage(
                                      image: NetworkImage(
                                          '${AppConstants.uploadsUrl}${sub['image_url']}'),
                                      fit: BoxFit.cover)
                                  : null),
                        ),
                        child: newImg == null && sub['image_url'] == null
                            ? const Center(
                                child: Icon(Icons.add_a_photo_rounded,
                                    size: 28, color: AppTheme.primary))
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(S.addSubcategoryEditCancel.of(ctx)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    minimumSize: const Size(100, 40)),
                onPressed: update,
                child: Text(S.addSubcategoryEditUpdate.of(ctx)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _snack(String msg, {bool success = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, textAlign: TextAlign.center),
      backgroundColor: success ? AppTheme.success : AppTheme.error,
    ));
  }

  // ── BUILD ────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isArabic = context.isArabic;

    return AppScaffold(
      title: S.addSubcategoryAddTitle.of(context),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHero(context),
            const SizedBox(height: 18),
            _buildFormCard(context),
            const SizedBox(height: 20),
            _buildList(context, isArabic),
          ],
        ),
      ),
    );
  }

  // ── Hero card ────────────────────────────────────────────

  Widget _buildHero(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.appBarGradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: AppTheme.appBarShadow,
      ),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.22),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white54, width: 1.5),
            ),
            child: const Icon(Icons.subdirectory_arrow_left_rounded,
                size: 30, color: Colors.white),
          ),
          const SizedBox(height: 12),
          Text(
            S.addSubcategoryAddTitle.of(context),
            style: AppTheme.headingLarge.copyWith(fontSize: 18),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            S.addSubcategoryHeroSubtitle.of(context),
            style: AppTheme.captionWhite.copyWith(fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ── Form card ────────────────────────────────────────────

  Widget _buildFormCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionHeader(
            icon: Icons.add_box_rounded,
            title: S.addSubcategoryFormSection.of(context),
          ),
          const SizedBox(height: 14),
          _fieldLabel(S.addSubcategoryChooseCategoryHint.of(context)),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: _selectedCategoryId,
            isExpanded: true,
            icon: const Icon(Icons.keyboard_arrow_down_rounded,
                color: AppTheme.textMuted),
            decoration: InputDecoration(
              hintText: S.addSubcategoryChooseCategoryHint.of(context),
              prefixIcon: const Icon(Icons.category_rounded,
                  color: AppTheme.primary),
            ),
            items: _categories
                .map((c) => DropdownMenuItem<String>(
                      value: c['id'].toString(),
                      child: Text(c['name'] ?? '',
                          overflow: TextOverflow.ellipsis),
                    ))
                .toList(),
            onChanged: (v) => setState(() => _selectedCategoryId = v),
          ),
          const SizedBox(height: 16),
          _fieldLabel(S.addSubcategoryNameHint.of(context)),
          const SizedBox(height: 6),
          TextField(
            controller: _subCategoryController,
            decoration: InputDecoration(
              hintText: S.addSubcategoryNameHint.of(context),
              prefixIcon:
                  const Icon(Icons.label_rounded, color: AppTheme.primary),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: AppTheme.primary.withOpacity(0.4)),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    color: AppTheme.background,
                    image: _selectedImage != null
                        ? DecorationImage(
                            image: kIsWeb && _webImageBytes != null
                                ? MemoryImage(_webImageBytes!)
                                : FileImage(File(_selectedImage!.path))
                                    as ImageProvider,
                            fit: BoxFit.cover)
                        : null,
                  ),
                  child: _selectedImage == null
                      ? const Center(
                          child: Icon(Icons.add_a_photo_rounded,
                              size: 26, color: AppTheme.primary))
                      : null,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: SizedBox(
                  height: AppTheme.buttonHeight,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _addSubCategory,
                    icon: _isLoading
                        ? const SizedBox.shrink()
                        : const Icon(Icons.add_rounded, size: 18),
                    label: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : Text(S.addSubcategoryAddButton.of(context)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── List ─────────────────────────────────────────────────

  Widget _buildList(BuildContext context, bool isArabic) {
    if (_categories.isEmpty) {
      return _buildEmptyState(context);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.10),
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: const Icon(Icons.list_alt_rounded,
                  size: 18, color: AppTheme.primary),
            ),
            const SizedBox(width: 10),
            Text(S.addSubcategoryListSection.of(context),
                style: AppTheme.headingSmall),
          ]),
        ),
        const SizedBox(height: 12),
        ..._categories.map((cat) {
          final catId = cat['id'].toString();
          final subs = _grouped[catId] ?? [];
          if (subs.isEmpty) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildCategoryGroup(context, cat, subs),
          );
        }),
      ],
    );
  }

  Widget _buildCategoryGroup(
      BuildContext context, dynamic cat, List<dynamic> subs) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.10),
                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
              ),
              child: Text(
                '${S.addSubcategoryCategoryPrefix.of(context)} ${cat['name']}',
                style: const TextStyle(
                    fontFamily: 'NotoKufi',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primary),
              ),
            ),
            const SizedBox(width: 8),
            Text('(${subs.length})',
                style: AppTheme.bodySmall.copyWith(color: AppTheme.textMuted)),
          ]),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount:
                  MediaQuery.of(context).size.width < 400 ? 2 : 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.78,
            ),
            itemCount: subs.length,
            itemBuilder: (_, j) => _buildSubCard(subs[j]),
          ),
        ],
      ),
    );
  }

  Widget _buildSubCard(Map<String, dynamic> sub) {
    final isActive = int.tryParse(sub['is_active'].toString()) == 1;
    final imgUrl = sub['image_url'] != null
        ? '${AppConstants.uploadsUrl}${sub['image_url']}'
        : '';

    return Container(
      decoration: BoxDecoration(
        color: isActive ? AppTheme.surface : AppTheme.background,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: isActive
              ? AppTheme.primary.withOpacity(0.10)
              : AppTheme.divider,
          width: 1,
        ),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    child: imgUrl.isNotEmpty
                        ? Image.network(imgUrl,
                            height: 60,
                            width: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                                  width: 60,
                                  height: 60,
                                  color: AppTheme.background,
                                  child: const Icon(Icons.category_rounded,
                                      size: 32, color: AppTheme.textMuted),
                                ))
                        : Container(
                            width: 60,
                            height: 60,
                            color: AppTheme.background,
                            child: const Icon(Icons.category_rounded,
                                size: 32, color: AppTheme.textMuted),
                          ),
                  ),
                  const SizedBox(height: 8),
                  Text(sub['name'] ?? '',
                      style: TextStyle(
                          fontFamily: 'NotoKufi',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isActive
                              ? AppTheme.textPrimary
                              : AppTheme.textMuted),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ]),
          ),
        ),
        const Divider(height: 1),
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          _miniIcon(
            icon: Icons.edit_rounded,
            color: AppTheme.accent,
            onTap: () => _showEditDialog(Map<String, dynamic>.from(sub)),
          ),
          _miniIcon(
            icon: isActive
                ? Icons.check_circle_rounded
                : Icons.cancel_rounded,
            color: isActive ? AppTheme.success : AppTheme.error,
            onTap: () => _toggleStatus(sub['id'].toString()),
          ),
          _miniIcon(
            icon: Icons.delete_outline_rounded,
            color: AppTheme.error,
            onTap: () => _confirmDelete(sub['id'].toString()),
          ),
        ]),
      ]),
    );
  }

  Widget _miniIcon({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      onTap: onTap,
      child: SizedBox(
        width: 36,
        height: 36,
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36),
      child: Column(children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppTheme.divider.withOpacity(0.5),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.inbox_outlined,
              size: 36, color: AppTheme.textMuted),
        ),
        const SizedBox(height: 12),
        Text(S.addSubcategoryEmpty.of(context),
            style: AppTheme.bodyMedium.copyWith(color: AppTheme.textMuted)),
      ]),
    );
  }

  // ── Helpers ──────────────────────────────────────────────

  Widget _sectionHeader({required IconData icon, required String title}) {
    return Row(children: [
      Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppTheme.primary.withOpacity(0.10),
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        ),
        child: Icon(icon, color: AppTheme.primary, size: 18),
      ),
      const SizedBox(width: 12),
      Expanded(child: Text(title, style: AppTheme.headingSmall)),
    ]);
  }

  Widget _fieldLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'NotoKufi',
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppTheme.textPrimary,
      ),
    );
  }
}
