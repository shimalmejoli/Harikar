// lib/screens/UpdateDetailsPage.dart

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

class UpdateDetailsPage extends StatefulWidget {
  final String detailId;
  const UpdateDetailsPage({required this.detailId, Key? key}) : super(key: key);

  @override
  _UpdateDetailsPageState createState() => _UpdateDetailsPageState();
}

class _UpdateDetailsPageState extends State<UpdateDetailsPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _additionalCtrl = TextEditingController();

  List<dynamic> _subCategories = [];
  List<dynamic> _users = [];
  final List<String> _cities = AppConstants.cities;

  String? _selectedSubCategory;
  String? _selectedUser;
  String? _selectedCity;
  bool _isActive = true;
  bool _isSubmitting = false;

  List<String> _existingImages = [];
  final List<dynamic> _newImages = []; // File or Uint8List

  @override
  void initState() {
    super.initState();
    AppLogger.info('UpdateDetailsPage — id: ${widget.detailId}',
        tag: 'UPDATE_DETAIL');
    _fetchSubCategories();
    _fetchUsers();
    _fetchDetailData();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _contactCtrl.dispose();
    _locationCtrl.dispose();
    _descCtrl.dispose();
    _additionalCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchSubCategories() async {
    final r = await ApiService.instance.fetchSubcategories();
    if (!mounted) return;
    if (r.success) {
      setState(() => _subCategories = r.data!['data'] as List? ?? []);
    }
  }

  Future<void> _fetchUsers() async {
    final r = await ApiService.instance.get(AppConstants.getUsersEndpoint);
    if (!mounted) return;
    if (r.success) setState(() => _users = r.data!['data'] as List? ?? []);
  }

  Future<void> _fetchDetailData() async {
    AppLogger.info('Fetching detail data: ${widget.detailId}',
        tag: 'UPDATE_DETAIL');
    final r = await ApiService.instance.post(
      AppConstants.getDetailByIdEndpoint,
      fields: {'id': widget.detailId},
    );
    if (!mounted) return;

    if (r.success && r.data != null) {
      final data = r.data!['data'] as Map<String, dynamic>? ?? {};
      AppLogger.info('Detail loaded: ${data['name']}', tag: 'UPDATE_DETAIL');
      setState(() {
        _nameCtrl.text = data['name'] ?? '';
        _contactCtrl.text = data['contact_number'] ?? '';
        _locationCtrl.text = data['location'] ?? '';
        _descCtrl.text = data['description'] ?? '';
        _additionalCtrl.text = data['additional_info'] ?? '';
        _isActive = data['is_active']?.toString() == '1';
        _selectedSubCategory = data['sub_category_id']?.toString();
        _selectedUser = data['user_id']?.toString();
        _selectedCity =
            _cities.contains(data['location']) ? data['location'] : null;
        _existingImages = List<String>.from(data['images'] ?? []);
      });
    } else {
      AppLogger.error('Fetch detail failed: ${r.error}', tag: 'UPDATE_DETAIL');
    }
  }

  Future<void> _pickImages() async {
    final files = await ImagePicker().pickMultiImage();
    for (var f in files) {
      if (kIsWeb) {
        final bytes = await f.readAsBytes();
        setState(() => _newImages.add(bytes));
      } else {
        setState(() => _newImages.add(File(f.path)));
      }
    }
  }

  void _removeNewImage(int i) => setState(() => _newImages.removeAt(i));
  void _removeExistingImage(String url) => _deleteExistingImage(url);

  Future<void> _deleteExistingImage(String url) async {
    AppLogger.info('Deleting existing image: $url', tag: 'UPDATE_DETAIL');
    final r = await ApiService.instance
        .post(AppConstants.deleteImageEndpoint, fields: {'image_url': url});
    if (!mounted) return;
    if (r.success) {
      setState(() => _existingImages.remove(url));
      _snack(S.updateDetailsImageDeleted.of(context), success: true);
    } else {
      _snack(r.error ?? 'Error');
    }
  }

  Future<void> _updateData() async {
    if (!_formKey.currentState!.validate()) return;
    final isArabic = context.isArabic;
    setState(() => _isSubmitting = true);
    AppLogger.info('Updating detail: ${widget.detailId}', tag: 'UPDATE_DETAIL');

    try {
      final request = http.MultipartRequest(
          'POST', Uri.parse(AppConstants.updateDetailsEndpoint));

      request.fields['id'] = widget.detailId;
      request.fields['sub_category_id'] = _selectedSubCategory ?? '';
      request.fields['user_id'] = _selectedUser ?? '';
      request.fields['name'] = _nameCtrl.text.trim();
      request.fields['contact_number'] = _contactCtrl.text.trim();
      request.fields['location'] = _selectedCity ?? '';
      request.fields['description'] = _descCtrl.text.trim();
      request.fields['is_active'] = _isActive ? '1' : '0';
      request.fields['additional_info'] = _additionalCtrl.text.trim();
      request.fields['existing_images'] = jsonEncode(_existingImages);

      for (var img in _newImages) {
        if (kIsWeb && img is Uint8List) {
          request.files.add(http.MultipartFile.fromBytes('images[]', img,
              filename: '${DateTime.now().millisecondsSinceEpoch}.jpg'));
        } else if (img is File) {
          request.files
              .add(await http.MultipartFile.fromPath('images[]', img.path));
        }
      }

      final resp = await request.send();
      final body = await resp.stream.bytesToString();
      final decoded = jsonDecode(body);

      if (!mounted) return;

      if (resp.statusCode == 200 && decoded['status'] == 'success') {
        AppLogger.info('Detail updated successfully', tag: 'UPDATE_DETAIL');
        _snack(S.updateDetailsSuccess.of(context), success: true);
        Navigator.pop(context);
      } else {
        AppLogger.error('Update failed: ${decoded['message']}',
            tag: 'UPDATE_DETAIL');
        _snack(isArabic
            ? 'خطأ: ${decoded['message']}'
            : 'هەڵە: ${decoded['message']}');
      }
    } catch (e) {
      AppLogger.error('Update error: $e', tag: 'UPDATE_DETAIL');
      _snack(isArabic ? 'حدث خطأ: $e' : 'هەڵەیەک ڕوویدا: $e');
    }
    setState(() => _isSubmitting = false);
  }

  void _snack(String msg, {bool success = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: success ? AppTheme.success : AppTheme.error,
    ));
  }

  // ── BUILD ────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: S.updateDetailsTitle.of(context),
      showDrawer: false,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHero(context),
              const SizedBox(height: 18),
              _buildFormCard(context),
              const SizedBox(height: 18),
              _buildImagesCard(context),
              const SizedBox(height: 22),
              _buildSubmitButton(context),
            ],
          ),
        ),
      ),
    );
  }

  // ── Hero card ────────────────────────────────────────────

  Widget _buildHero(BuildContext context) {
    final name = _nameCtrl.text.isEmpty
        ? S.updateDetailsTitle.of(context)
        : _nameCtrl.text;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.appBarGradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: AppTheme.appBarShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.22),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white54, width: 1.5),
            ),
            child: const Icon(Icons.edit_note_rounded,
                size: 30, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTheme.headingLarge.copyWith(fontSize: 17),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  S.updateDetailsHeroSubtitle.of(context),
                  style: AppTheme.captionWhite.copyWith(fontSize: 12),
                ),
              ],
            ),
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
          _fieldLabel(S.insertDetailsSubcategoryLabel.of(context)),
          const SizedBox(height: 6),
          _dropdown(
              S.insertDetailsSubcategoryLabel.of(context),
              Icons.category_rounded,
              _subCategories,
              _selectedSubCategory,
              (v) => setState(() => _selectedSubCategory = v)),
          const SizedBox(height: 16),
          _fieldLabel(S.insertDetailsUserLabel.of(context)),
          const SizedBox(height: 6),
          _dropdown(
              S.insertDetailsUserLabel.of(context),
              Icons.person_rounded,
              _users,
              _selectedUser,
              (v) => setState(() => _selectedUser = v)),
          const SizedBox(height: 16),
          _fieldLabel(S.insertDetailsNameLabel.of(context)),
          const SizedBox(height: 6),
          _field(_nameCtrl, S.insertDetailsNameLabel.of(context),
              Icons.label_rounded),
          const SizedBox(height: 16),
          _fieldLabel(S.insertDetailsContactLabel.of(context)),
          const SizedBox(height: 6),
          _field(_contactCtrl, S.insertDetailsContactLabel.of(context),
              Icons.phone_rounded,
              type: TextInputType.phone),
          const SizedBox(height: 16),
          _fieldLabel(S.insertDetailsLocationLabel.of(context)),
          const SizedBox(height: 6),
          _dropdown(
              S.insertDetailsLocationLabel.of(context),
              Icons.location_city_rounded,
              _cities.map((c) => {'id': c, 'name': c}).toList(),
              _selectedCity,
              (v) => setState(() => _selectedCity = v)),
          const SizedBox(height: 16),
          _activeCard(context),
          const SizedBox(height: 16),
          _fieldLabel(S.insertDetailsDescLabel.of(context)),
          const SizedBox(height: 6),
          _field(_descCtrl, S.insertDetailsDescLabel.of(context),
              Icons.description_rounded,
              maxLines: 3),
          const SizedBox(height: 16),
          _fieldLabel(S.insertDetailsAdditional.of(context)),
          const SizedBox(height: 6),
          _field(_additionalCtrl, S.insertDetailsAdditional.of(context),
              Icons.info_outline_rounded,
              maxLines: 2, required: false),
        ],
      ),
    );
  }

  // ── Images card ──────────────────────────────────────────

  Widget _buildImagesCard(BuildContext context) {
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
            icon: Icons.collections_rounded,
            title: S.updateDetailsImagesSection.of(context),
          ),
          const SizedBox(height: 14),
          if (_existingImages.isNotEmpty || _newImages.isNotEmpty) ...[
            _buildImagesGrid(),
            const SizedBox(height: 14),
          ],
          OutlinedButton.icon(
            onPressed: _pickImages,
            icon: const Icon(Icons.add_a_photo_rounded, size: 18),
            label: Text(S.updateDetailsAddPhotos.of(context)),
          ),
        ],
      ),
    );
  }

  Widget _buildImagesGrid() {
    return Wrap(spacing: 10, runSpacing: 10, children: [
      ..._existingImages.map((url) => _imgItem(
          image: Image.network('${AppConstants.uploadsUrl}$url',
              width: 92, height: 92, fit: BoxFit.cover),
          onRemove: () => _removeExistingImage(url))),
      ..._newImages.asMap().entries.map((e) {
        final img = e.value;
        return _imgItem(
          image: kIsWeb && img is Uint8List
              ? Image.memory(img, width: 92, height: 92, fit: BoxFit.cover)
              : Image.file(img as File,
                  width: 92, height: 92, fit: BoxFit.cover),
          onRemove: () => _removeNewImage(e.key),
        );
      }),
    ]);
  }

  Widget _imgItem({required Widget image, required VoidCallback onRemove}) {
    return Stack(alignment: Alignment.topRight, children: [
      ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusSm), child: image),
      GestureDetector(
        onTap: onRemove,
        child: Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
              color: AppTheme.error, shape: BoxShape.circle),
          child: const Icon(Icons.close_rounded, size: 14, color: Colors.white),
        ),
      ),
    ]);
  }

  // ── Submit ───────────────────────────────────────────────

  Widget _buildSubmitButton(BuildContext context) {
    return SizedBox(
      height: AppTheme.buttonHeight,
      child: ElevatedButton.icon(
        onPressed: _isSubmitting ? null : _updateData,
        icon: _isSubmitting
            ? const SizedBox.shrink()
            : const Icon(Icons.check_circle_outline_rounded, size: 18),
        label: _isSubmitting
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : Text(S.updateButton.of(context)),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────

  Widget _field(TextEditingController ctrl, String label, IconData icon,
      {TextInputType type = TextInputType.text,
      int maxLines = 1,
      bool required = true}) {
    final isArabic = context.isArabic;
    return TextFormField(
      controller: ctrl,
      keyboardType: type,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: label,
        prefixIcon: Icon(icon, color: AppTheme.primary),
      ),
      validator: required
          ? (v) => (v == null || v.isEmpty)
              ? (isArabic ? S.fieldRequiredFill.ar : S.fieldRequiredFill.ku)
              : null
          : null,
    );
  }

  Widget _dropdown(String label, IconData icon, List<dynamic> items,
      String? value, ValueChanged<String?> onChange) {
    final isArabic = context.isArabic;
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      icon: const Icon(Icons.keyboard_arrow_down_rounded,
          color: AppTheme.textMuted),
      decoration: InputDecoration(
        hintText: label,
        prefixIcon: Icon(icon, color: AppTheme.primary),
      ),
      items: items
          .map((item) => DropdownMenuItem<String>(
                value: item['id'].toString(),
                child: Text(item['name'] ?? item['full_name'] ?? '',
                    overflow: TextOverflow.ellipsis),
              ))
          .toList(),
      onChanged: onChange,
      validator: (v) => v == null
          ? (isArabic ? S.fieldRequiredFill.ar : S.fieldRequiredFill.ku)
          : null,
    );
  }

  Widget _activeCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            S.updateDetailsActiveLabel.of(context),
            style: const TextStyle(
                fontFamily: 'NotoKufi',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary),
          ),
        ),
        Row(children: [
          Radio<bool>(
              value: true,
              groupValue: _isActive,
              onChanged: (v) => setState(() => _isActive = v!),
              activeColor: AppTheme.primary),
          Text(S.yes.of(context),
              style: const TextStyle(fontFamily: 'NotoKufi')),
          const SizedBox(width: 16),
          Radio<bool>(
              value: false,
              groupValue: _isActive,
              onChanged: (v) => setState(() => _isActive = v!),
              activeColor: AppTheme.primary),
          Text(S.no.of(context),
              style: const TextStyle(fontFamily: 'NotoKufi')),
        ]),
      ]),
    );
  }

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
