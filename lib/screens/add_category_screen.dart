// lib/screens/add_category_screen.dart

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../core/app_constants.dart';
import '../core/app_logger.dart';
import '../core/app_strings.dart';
import '../core/app_theme.dart';
import '../main.dart' show LocaleContext;
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../widgets/app_scaffold.dart';

class AddCategoryScreen extends StatefulWidget {
  const AddCategoryScreen({Key? key}) : super(key: key);
  @override
  _AddCategoryScreenState createState() => _AddCategoryScreenState();
}

class _AddCategoryScreenState extends State<AddCategoryScreen> {
  final _categoryController = TextEditingController();
  bool _isLoading = false;
  List<dynamic> _categories = [];
  XFile? _selectedImage;
  bool _didFetchCategories = false;

  // For edit dialog
  XFile? _newImage;
  Uint8List? _imageBytes;
  final _editNameController = TextEditingController();

  @override
  void dispose() {
    _categoryController.dispose();
    _editNameController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didFetchCategories) {
      _didFetchCategories = true;
      _fetchCategories();
    }
  }

  Future<void> _fetchCategories() async {
    AppLogger.info('Fetching categories', tag: 'ADD_CAT');
    // `fetchCategories()` already cache-busts the GET — see the
    // `_cacheBust()` helper in ApiService.
    final response = await ApiService.instance.fetchCategories();
    if (!mounted) return;
    if (response.success && response.data != null) {
      final list = response.data!['data'] as List? ?? [];
      // Diagnostic: print each row's is_active so we can see whether
      // the server is actually toggling between fetches.
      final summary = list
          .map((c) => '${c['id']}=${c['is_active']}')
          .join(', ');
      AppLogger.info(
          'Categories loaded: ${list.length} — [$summary]',
          tag: 'ADD_CAT');
      setState(() => _categories = list);
    } else {
      AppLogger.error('Fetch categories failed: ${response.error}',
          tag: 'ADD_CAT');
    }
  }

  Future<void> _pickImage() async {
    final f = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (f != null) setState(() => _selectedImage = f);
  }

  Future<void> _pickNewImage() async {
    final f = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (f != null) {
      _newImage = f;
      if (kIsWeb) _imageBytes = await f.readAsBytes();
    }
  }

  Future<void> _addCategory() async {
    final isArabic = context.isArabic;
    final name = _categoryController.text.trim();
    if (name.isEmpty) {
      _snack(S.addCategoryNameRequired.of(context));
      return;
    }
    setState(() => _isLoading = true);
    AppLogger.info('Adding category: $name', tag: 'ADD_CAT');

    try {
      final request = http.MultipartRequest(
          'POST', Uri.parse(AppConstants.addCategoryEndpoint));
      request.fields['category_name'] = name;
      if (_selectedImage != null) {
        if (kIsWeb) {
          final bytes = await _selectedImage!.readAsBytes();
          request.files.add(http.MultipartFile.fromBytes('image', bytes,
              filename: _selectedImage!.name));
        } else {
          request.files.add(
              await http.MultipartFile.fromPath('image', _selectedImage!.path));
        }
      }
      final resp = await request.send();
      final body = await resp.stream.bytesToString();
      final decoded = jsonDecode(body);
      if (!mounted) return;
      if (decoded['status'] == 'success') {
        AppLogger.info('Category added successfully', tag: 'ADD_CAT');
        _snack(decoded['message'], success: true);
        _categoryController.clear();
        setState(() => _selectedImage = null);
        _fetchCategories();
      } else {
        _snack(decoded['message']);
      }
    } catch (e) {
      AppLogger.error('Add category error: $e', tag: 'ADD_CAT');
      _snack(isArabic ? 'حدث خطأ: $e' : 'هەڵە ڕویدا: $e');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _deleteCategory(String id) async {
    AppLogger.info('Deleting category id: $id', tag: 'ADD_CAT');
    final response = await ApiService.instance.post(
      AppConstants.deleteCategoryEndpoint,
      jsonBody: {'id': id},
    );
    if (!mounted) return;
    if (response.success) {
      _snack(response.data?['message'] ?? 'Deleted', success: true);
      _fetchCategories();
    } else {
      _snack(response.error ?? 'Error');
    }
  }

  Future<void> _toggleCategoryStatus(String id) async {
    AppLogger.info('Toggling category status: $id', tag: 'ADD_CAT');
    final response = await ApiService.instance.post(
      AppConstants.toggleCategoryEndpoint,
      fields: {'id': id},
    );
    if (!mounted) return;

    AppLogger.info(
      'Toggle response — success: ${response.success}, '
      'data: ${response.data}, error: ${response.error}',
      tag: 'ADD_CAT',
    );

    // Always refetch so the UI reflects whatever the server actually
    // has now. The toggle endpoint may return a non-standard body
    // (no `status: success` or `success: true` flag) which would
    // make `response.success` false even when the row was toggled.
    await _fetchCategories();

    if (!response.success) {
      _snack(response.error ?? 'Toggle failed');
    }
  }

  Future<void> _confirmDelete(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
          title: Text(S.addCategoryConfirmTitle.of(ctx),
              style: const TextStyle(fontFamily: 'NotoKufi')),
          content: Text(S.addCategoryConfirmContent.of(ctx),
              style: const TextStyle(fontFamily: 'NotoKufi')),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(S.no.of(ctx),
                    style: const TextStyle(
                        fontFamily: 'NotoKufi', color: AppTheme.primary))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(S.yes.of(ctx),
                  style: const TextStyle(
                      fontFamily: 'NotoKufi', color: Colors.white)),
            ),
          ],
        ),
      ),
    );
    if (confirmed == true) _deleteCategory(id);
  }

  void _showEditDialog(Map<String, dynamic> category) {
    _editNameController.text = category['name'] ?? '';
    _newImage = null;
    _imageBytes = null;

    Future<void> updateCategory() async {
      AppLogger.info('Updating category: ${category['id']}', tag: 'ADD_CAT');
      try {
        final request = http.MultipartRequest(
            'POST', Uri.parse(AppConstants.updateCategoryEndpoint));
        request.fields['id'] = category['id'].toString();
        request.fields['category_name'] = _editNameController.text.trim();
        if (_newImage != null) {
          if (kIsWeb) {
            request.files.add(http.MultipartFile.fromBytes(
                'image', _imageBytes!,
                filename: _newImage!.name));
          } else {
            request.files.add(
                await http.MultipartFile.fromPath('image', _newImage!.path));
          }
        }
        final resp = await request.send();
        final body = await resp.stream.bytesToString();
        final decoded = jsonDecode(body);
        if (!mounted) return;
        if (decoded['status'] == 'success') {
          _snack(decoded['message'], success: true);
          _fetchCategories();
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
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
            title: Text(S.addCategoryEditTitle.of(ctx),
                style: const TextStyle(fontFamily: 'NotoKufi')),
            content: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                TextField(
                  controller: _editNameController,
                  style: const TextStyle(fontFamily: 'NotoKufi'),
                  decoration: InputDecoration(
                    labelText: S.addCategoryEditNameLabel.of(ctx),
                    labelStyle: const TextStyle(fontFamily: 'NotoKufi'),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm)),
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () async {
                    await _pickNewImage();
                    setS(() {});
                  },
                  child: Container(
                    height: 90,
                    width: 90,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      image: _newImage != null
                          ? DecorationImage(
                              image: kIsWeb
                                  ? MemoryImage(_imageBytes!)
                                  : FileImage(File(_newImage!.path))
                                      as ImageProvider,
                              fit: BoxFit.cover)
                          : DecorationImage(
                              image: NetworkImage(
                                  '${AppConstants.uploadsUrl}${category['image_url']}'),
                              fit: BoxFit.cover),
                    ),
                    child: _newImage == null
                        ? const Center(
                            child: Icon(Icons.add_a_photo,
                                size: 28, color: Colors.grey))
                        : null,
                  ),
                ),
              ]),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(S.addCategoryEditCancel.of(ctx),
                      style: const TextStyle(
                          fontFamily: 'NotoKufi', color: AppTheme.primary))),
              ElevatedButton(
                style:
                    ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                onPressed: updateCategory,
                child: Text(S.addCategoryEditUpdate.of(ctx),
                    style: const TextStyle(
                        fontFamily: 'NotoKufi', color: Colors.white)),
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
      content: Text(msg,
          style: const TextStyle(
              fontFamily: 'NotoKufi',
              fontWeight: FontWeight.bold,
              color: Colors.white),
          textAlign: TextAlign.center),
      backgroundColor: success ? Colors.green : AppTheme.error,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      duration: const Duration(seconds: 3),
    ));
  }

  @override
  Widget build(BuildContext context) {
    Provider.of<UserModel>(context);

    return AppScaffold(
      title: S.addCategoryTitle.of(context),
      body: Column(
          children: [
            // ── Add form ──
            Container(
              margin: const EdgeInsets.all(14),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                boxShadow: AppTheme.elevatedShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _categoryController,
                    textDirection: TextDirection.rtl,
                    style: const TextStyle(fontFamily: 'NotoKufi'),
                    decoration: InputDecoration(
                      labelText: S.addCategoryNameHint.of(context),
                      labelStyle: const TextStyle(fontFamily: 'NotoKufi'),
                      prefixIcon: const Icon(Icons.category_rounded,
                          color: AppTheme.primary),
                      border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusSm)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: AppTheme.primary.withOpacity(0.4)),
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusSm),
                          color: AppTheme.background,
                          image: _selectedImage != null
                              ? DecorationImage(
                                  image: kIsWeb
                                      ? NetworkImage(_selectedImage!.path)
                                      : FileImage(File(_selectedImage!.path))
                                          as ImageProvider,
                                  fit: BoxFit.cover)
                              : null,
                        ),
                        child: _selectedImage == null
                            ? const Center(
                                child: Icon(Icons.add_a_photo,
                                    size: 28, color: AppTheme.primary))
                            : null,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusSm)),
                        ),
                        onPressed: _isLoading ? null : _addCategory,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.add_rounded,
                                color: Colors.white),
                        label: Text(
                          S.addCategoryAddButton.of(context),
                          style: const TextStyle(
                              fontFamily: 'NotoKufi',
                              color: Colors.white,
                              fontSize: 15),
                        ),
                      ),
                    ),
                  ]),
                ],
              ),
            ),
            const Divider(height: 1),
            // ── Category grid ──
            Expanded(
              child: _categories.isEmpty
                  ? Center(
                      child: Text(
                          S.addCategoryEmpty.of(context),
                          style: const TextStyle(
                              fontFamily: 'NotoKufi',
                              fontSize: 15,
                              color: Colors.grey)))
                  : GridView.builder(
                      padding: const EdgeInsets.all(12),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount:
                            MediaQuery.of(context).size.width > 600 ? 4 : 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 0.75,
                      ),
                      itemCount: _categories.length,
                      itemBuilder: (_, i) => _buildCategoryCard(_categories[i]),
                    ),
            ),
          ],
        ),
      );
  }

  Widget _buildCategoryCard(Map<String, dynamic> cat) {
    final bool isActive = int.tryParse(cat['is_active'].toString()) == 1;
    final String imageUrl = cat['image_url']?.isNotEmpty == true
        ? '${AppConstants.uploadsUrl}${cat['image_url']}'
        : '';

    return Container(
      decoration: BoxDecoration(
        color: isActive ? Colors.white : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: imageUrl.isNotEmpty
                        ? Image.network(imageUrl,
                            height: 72,
                            width: 72,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Icon(
                                Icons.category_rounded,
                                size: 48,
                                color: Colors.grey))
                        : const Icon(Icons.category_rounded,
                            size: 48, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(cat['name'],
                      style: TextStyle(
                          fontFamily: 'NotoKufi',
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isActive ? AppTheme.primary : Colors.grey),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: const Icon(Icons.edit_rounded,
                    size: 18, color: AppTheme.accent),
                onPressed: () => _showEditDialog(cat),
                padding: EdgeInsets.zero,
              ),
              IconButton(
                icon: Icon(
                    isActive
                        ? Icons.check_circle_rounded
                        : Icons.cancel_rounded,
                    size: 18,
                    color: isActive ? Colors.green : Colors.red),
                onPressed: () => _toggleCategoryStatus(cat['id'].toString()),
                padding: EdgeInsets.zero,
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded,
                    size: 18, color: Colors.redAccent),
                onPressed: () => _confirmDelete(cat['id'].toString()),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}
