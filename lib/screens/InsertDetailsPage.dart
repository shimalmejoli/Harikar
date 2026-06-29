// lib/screens/InsertDetailsPage.dart

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:harikar/main.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../core/app_constants.dart';
import '../core/app_logger.dart';
import '../core/app_strings.dart';
import '../core/app_theme.dart';
import '../services/api_service.dart';
import '../widgets/app_scaffold.dart';

class InsertDetailsPage extends StatefulWidget {
  const InsertDetailsPage({Key? key}) : super(key: key);

  @override
  _InsertDetailsPageState createState() => _InsertDetailsPageState();
}

class _InsertDetailsPageState extends State<InsertDetailsPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();
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

  // Images — File on mobile, Uint8List on web
  final List<dynamic> _selectedImages = [];

  @override
  void initState() {
    super.initState();
    AppLogger.info('InsertDetailsPage init', tag: 'INSERT');
    _fetchSubCategories();
    _fetchUsers();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _contactCtrl.dispose();
    _descCtrl.dispose();
    _additionalCtrl.dispose();
    super.dispose();
  }

  // ── Fetch ────────────────────────────────────────────────

  Future<void> _fetchSubCategories() async {
    final r = await ApiService.instance.fetchSubcategories();
    if (!mounted) return;
    if (r.success && r.data != null) {
      setState(() => _subCategories = r.data!['data'] as List? ?? []);
      AppLogger.info('Subcategories loaded: ${_subCategories.length}',
          tag: 'INSERT');
    } else {
      AppLogger.error('Subcategories failed: ${r.error}', tag: 'INSERT');
    }
  }

  Future<void> _fetchUsers() async {
    final r = await ApiService.instance.get(AppConstants.getUsersEndpoint);
    if (!mounted) return;
    if (r.success && r.data != null) {
      setState(() => _users = r.data!['data'] as List? ?? []);
      AppLogger.info('Users loaded: ${_users.length}', tag: 'INSERT');
    } else {
      AppLogger.error('Users failed: ${r.error}', tag: 'INSERT');
    }
  }

  // ── Pick images ──────────────────────────────────────────

  Future<void> _pickImages() async {
    if (_selectedImages.length >= 3) {
      _snack(S.insertDetailsMaxImages.of(context));
      return;
    }
    final List<XFile> picked = await ImagePicker().pickMultiImage();
    for (final f in picked) {
      if (_selectedImages.length >= 3) break;
      if (kIsWeb) {
        final bytes = await f.readAsBytes();
        setState(() => _selectedImages.add(bytes));
      } else {
        setState(() => _selectedImages.add(File(f.path)));
      }
    }
  }

  // ── Submit ───────────────────────────────────────────────

  Future<void> _insertData() async {
    final isArabic = context.isArabic;
    if (!_formKey.currentState!.validate()) return;

    if (_selectedImages.isEmpty) {
      _snack(S.insertDetailsImageRequired.of(context));
      return;
    }

    setState(() => _isSubmitting = true);
    AppLogger.info('Inserting detail: ${_nameCtrl.text}', tag: 'INSERT');

    try {
      final request = http.MultipartRequest(
          'POST', Uri.parse(AppConstants.insertDetailsEndpoint));

      request.fields['sub_category_id'] = _selectedSubCategory ?? '';
      request.fields['user_id'] = _selectedUser ?? '';
      request.fields['name'] = _nameCtrl.text.trim();
      request.fields['contact_number'] = _contactCtrl.text.trim();
      request.fields['location'] = _selectedCity ?? '';
      request.fields['description'] = _descCtrl.text.trim();
      request.fields['is_active'] = _isActive ? '1' : '0';
      request.fields['additional_info'] = _additionalCtrl.text.trim();

      for (final img in _selectedImages) {
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
        AppLogger.info('Detail inserted successfully', tag: 'INSERT');
        _snack(S.insertDetailsSuccess.of(context), success: true);
        _resetForm();
      } else {
        String msg = decoded['message']?.toString() ?? 'Error';
        if (decoded['image_errors'] != null) {
          msg += '\n${(decoded['image_errors'] as List).join(', ')}';
        }
        AppLogger.error('Insert failed: $msg', tag: 'INSERT');
        _snack(isArabic ? 'خطأ: $msg' : 'هەڵە: $msg');
      }
    } catch (e) {
      AppLogger.error('Insert exception: $e', tag: 'INSERT');
      _snack(isArabic ? 'حدث خطأ: $e' : 'هەڵەیەک ڕوویدا: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _nameCtrl.clear();
    _contactCtrl.clear();
    _descCtrl.clear();
    _additionalCtrl.clear();
    setState(() {
      _selectedImages.clear();
      _selectedSubCategory = null;
      _selectedUser = null;
      _selectedCity = null;
      _isActive = true;
    });
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
      title: S.insertDetailsTitle.of(context),
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
              _buildImageCard(context),
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
            child: const Icon(Icons.add_box_rounded,
                size: 28, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  S.insertDetailsHeader.of(context),
                  style: AppTheme.headingLarge.copyWith(fontSize: 17),
                ),
                const SizedBox(height: 4),
                Text(
                  S.insertDetailsTitle.of(context),
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
            (v) => setState(() => _selectedSubCategory = v),
          ),
          const SizedBox(height: 16),
          _fieldLabel(S.insertDetailsUserLabel.of(context)),
          const SizedBox(height: 6),
          _dropdown(
            S.insertDetailsUserLabel.of(context),
            Icons.person_rounded,
            _users,
            _selectedUser,
            (v) => setState(() => _selectedUser = v),
          ),
          const SizedBox(height: 16),
          _fieldLabel(S.insertDetailsNameLabel.of(context)),
          const SizedBox(height: 6),
          _field(_nameCtrl, S.insertDetailsNameLabel.of(context),
              Icons.label_rounded),
          const SizedBox(height: 16),
          _fieldLabel(S.insertDetailsContactLabel.of(context)),
          const SizedBox(height: 6),
          _field(
              _contactCtrl,
              S.insertDetailsContactLabel.of(context),
              Icons.phone_rounded,
              type: TextInputType.phone,
              formatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (v) {
            if (v == null || v.isEmpty) {
              return S.insertDetailsContactRequired.of(context);
            }
            if (v.length < 10 || v.length > 15) {
              return S.insertDetailsContactRange.of(context);
            }
            return null;
          }),
          const SizedBox(height: 16),
          _fieldLabel(S.insertDetailsLocationLabel.of(context)),
          const SizedBox(height: 6),
          _dropdown(
            S.insertDetailsLocationLabel.of(context),
            Icons.location_city_rounded,
            _cities.map((c) => {'id': c, 'name': c}).toList(),
            _selectedCity,
            (v) => setState(() => _selectedCity = v),
          ),
          const SizedBox(height: 16),
          _activeCard(context),
          const SizedBox(height: 16),
          _fieldLabel(S.insertDetailsDescLabel.of(context)),
          const SizedBox(height: 6),
          _field(_descCtrl, S.insertDetailsDescLabel.of(context),
              Icons.description_rounded, maxLines: 3, validator: (v) {
            if (v == null || v.isEmpty) {
              return S.insertDetailsDescRequired.of(context);
            }
            if (v.length < 10) {
              return S.insertDetailsDescMin.of(context);
            }
            return null;
          }),
          const SizedBox(height: 16),
          _fieldLabel(S.insertDetailsAdditional.of(context)),
          const SizedBox(height: 6),
          _field(
              _additionalCtrl,
              S.insertDetailsAdditional.of(context),
              Icons.info_outline_rounded,
              maxLines: 2,
              required: false),
        ],
      ),
    );
  }

  // ── Image upload card ────────────────────────────────────

  Widget _buildImageCard(BuildContext context) {
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
            title: S.insertDetailsAddImagesLabel.of(context),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: _pickImages,
            icon: const Icon(Icons.add_a_photo_rounded, size: 18),
            label: Text(S.insertDetailsAddImagesLabel.of(context)),
          ),
          if (_selectedImages.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _selectedImages.asMap().entries.map((e) {
                final img = e.value;
                return Stack(alignment: Alignment.topRight, children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    child: kIsWeb && img is Uint8List
                        ? Image.memory(img,
                            width: 92, height: 92, fit: BoxFit.cover)
                        : Image.file(img as File,
                            width: 92, height: 92, fit: BoxFit.cover),
                  ),
                  GestureDetector(
                    onTap: () =>
                        setState(() => _selectedImages.removeAt(e.key)),
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                          color: AppTheme.error, shape: BoxShape.circle),
                      child: const Icon(Icons.close_rounded,
                          size: 14, color: Colors.white),
                    ),
                  ),
                ]);
              }).toList(),
            ),
          ],
          if (_selectedImages.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                S.insertDetailsImageRequiredAsterisk.of(context),
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.error,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Submit button ────────────────────────────────────────

  Widget _buildSubmitButton(BuildContext context) {
    return SizedBox(
      height: AppTheme.buttonHeight,
      child: ElevatedButton.icon(
        onPressed: _isSubmitting ? null : _insertData,
        icon: _isSubmitting
            ? const SizedBox.shrink()
            : const Icon(Icons.add_circle_outline_rounded, size: 18),
        label: _isSubmitting
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : Text(S.insertDetailsAddButton.of(context)),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────

  Widget _field(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    TextInputType type = TextInputType.text,
    List<TextInputFormatter>? formatters,
    int maxLines = 1,
    bool required = true,
    FormFieldValidator<String>? validator,
  }) {
    final isArabic = context.isArabic;
    return TextFormField(
      controller: ctrl,
      keyboardType: type,
      inputFormatters: formatters,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: label,
        prefixIcon: Icon(icon, color: AppTheme.primary),
      ),
      validator: validator ??
          (required
              ? (v) => (v == null || v.isEmpty)
                  ? (isArabic ? S.fieldRequiredFill.ar : S.fieldRequiredFill.ku)
                  : null
              : null),
    );
  }

  Widget _dropdown(
    String label,
    IconData icon,
    List<dynamic> items,
    String? value,
    ValueChanged<String?> onChange,
  ) {
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
                child: Text(
                    item['name']?.toString() ??
                        item['full_name']?.toString() ??
                        '',
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
            S.insertDetailsActiveLabel.of(context),
            style: const TextStyle(
                fontFamily: 'NotoKufi',
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
                fontSize: 13),
          ),
        ),
        Row(children: [
          Radio<bool>(
            value: true,
            groupValue: _isActive,
            onChanged: (v) => setState(() => _isActive = v!),
            activeColor: AppTheme.primary,
          ),
          Text(S.yes.of(context),
              style: const TextStyle(fontFamily: 'NotoKufi')),
          const SizedBox(width: 16),
          Radio<bool>(
            value: false,
            groupValue: _isActive,
            onChanged: (v) => setState(() => _isActive = v!),
            activeColor: AppTheme.primary,
          ),
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
