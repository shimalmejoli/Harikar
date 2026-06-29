// lib/screens/InsertDetailsPageNo.dart
// User-facing insert page (no admin controls).
// Phone + city pre-filled from UserInfoPage.
// User field auto-matched from UserModel.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:harikar/main.dart' show LocaleContext, navigatorKey, scaffoldMessengerKey;
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../core/app_constants.dart';
import '../core/app_logger.dart';
import '../core/app_strings.dart';
import '../core/app_theme.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../widgets/app_scaffold.dart';
import 'save_success_page.dart';

class InsertDetailsPageNo extends StatefulWidget {
  final String? phoneNumber;
  final String? city;

  /// Set when this page is reached straight from a fresh registration.
  /// Used by [requireDetailsOrRollback] to delete the user record if
  /// they abandon the form before submitting it.
  final int? pendingUserId;

  /// When true, the user is forced to either complete the work-details
  /// form or have their registration rolled back (delete_user.php).
  /// Hitting back shows a confirmation dialog instead of a silent pop.
  final bool requireDetailsOrRollback;

  const InsertDetailsPageNo({
    this.phoneNumber,
    this.city,
    this.pendingUserId,
    this.requireDetailsOrRollback = false,
    Key? key,
  }) : super(key: key);

  @override
  _InsertDetailsPageNoState createState() => _InsertDetailsPageNoState();
}

class _InsertDetailsPageNoState extends State<InsertDetailsPageNo> {
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
  bool _isSubmitting = false;

  final List<dynamic> _selectedImages = [];

  /// Flips to true the moment the work-details POST returns success.
  /// Once true, the rollback path is disabled — the user is now fully
  /// registered and free to leave normally.
  bool _detailsSavedSuccessfully = false;

  /// Prevents two simultaneous rollback attempts (e.g. user mashes back).
  bool _rollbackInFlight = false;

  @override
  void initState() {
    super.initState();
    AppLogger.info('InsertDetailsPageNo init', tag: 'INSERT_NO');
    // Pre-fill from params
    _contactCtrl.text = widget.phoneNumber ?? '';
    _selectedCity = widget.city;
    // If we arrived here straight from registration the new user's id
    // is already known — use it directly. This bypasses the brittle
    // name-based auto-select against get_users.php (which can return
    // stale rows from previous rollbacks and lead to FK failures).
    //
    // We also seed `_users` with a synthetic entry for the new user
    // so the disabled DropdownButtonFormField has a matching item
    // even before — or in case — get_users.php returns a list that
    // excludes the freshly-registered (unapproved) user.
    if (widget.pendingUserId != null) {
      _selectedUser = widget.pendingUserId.toString();
      final userModel = Provider.of<UserModel>(context, listen: false);
      _users = [
        {
          'id': widget.pendingUserId,
          'full_name': userModel.name,
        }
      ];
      AppLogger.info('Using pendingUserId: $_selectedUser', tag: 'INSERT_NO');
    }
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

  Future<void> _fetchSubCategories() async {
    final r = await ApiService.instance.fetchSubcategories();
    if (!mounted) return;
    if (r.success && r.data != null) {
      setState(() => _subCategories = r.data!['data'] as List? ?? []);
    }
  }

  Future<void> _fetchUsers() async {
    final r = await ApiService.instance.get(AppConstants.getUsersEndpoint);
    if (!mounted) return;
    if (r.success && r.data != null) {
      final list = List<dynamic>.from(r.data!['data'] as List? ?? []);

      // If we have a known pending user (post-registration flow) and the
      // API response doesn't include them — common when get_users.php
      // returns only approved users — keep our synthetic entry so the
      // dropdown's value still has a matching item.
      if (widget.pendingUserId != null) {
        final pidStr = widget.pendingUserId.toString();
        final present =
            list.any((u) => u['id']?.toString() == pidStr);
        if (!present) {
          final userModel = Provider.of<UserModel>(context, listen: false);
          list.add({
            'id': widget.pendingUserId,
            'full_name': userModel.name,
          });
        }
      }

      setState(() => _users = list);
      // If we already know the user id (post-registration shortcut),
      // don't run the name-matcher — names aren't unique and the
      // get_users response can include stale rows.
      if (_selectedUser == null) _autoSelectUser();
    }
  }

  void _autoSelectUser() {
    if (_selectedUser != null) return; // already set by pendingUserId
    final userModel = Provider.of<UserModel>(context, listen: false);
    final myName = userModel.name.trim().toLowerCase();
    AppLogger.info('Auto-selecting user: $myName', tag: 'INSERT_NO');

    final matched = _users.firstWhere(
      (u) =>
          (u['full_name']?.toString().trim().toLowerCase() == myName) ||
          (u['name']?.toString().trim().toLowerCase() == myName),
      orElse: () => null,
    );

    if (matched != null) {
      setState(() => _selectedUser = matched['id'].toString());
      AppLogger.info('User matched: $_selectedUser', tag: 'INSERT_NO');
    } else {
      AppLogger.warning('No user match found for: $myName', tag: 'INSERT_NO');
    }
  }

  Future<void> _pickImages() async {
    if (_selectedImages.length >= 3) {
      _snack(S.insertDetailsMaxImages.of(context));
      return;
    }
    final picked = await ImagePicker().pickMultiImage();
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

  Future<void> _insertData() async {
    final isArabic = context.isArabic;
    if (!_formKey.currentState!.validate()) return;

    if (_selectedImages.isEmpty) {
      _snack(S.insertDetailsImageRequired.of(context));
      return;
    }

    setState(() => _isSubmitting = true);
    AppLogger.info('InsertDetailsPageNo submitting: ${_nameCtrl.text}',
        tag: 'INSERT_NO');

    try {
      final request = http.MultipartRequest(
          'POST', Uri.parse(AppConstants.insertDetailsEndpoint));

      request.fields['sub_category_id'] = _selectedSubCategory ?? '';
      request.fields['user_id'] = _selectedUser ?? '';
      request.fields['name'] = _nameCtrl.text.trim();
      request.fields['contact_number'] = _contactCtrl.text.trim();
      request.fields['location'] = _selectedCity ?? '';
      request.fields['description'] = _descCtrl.text.trim();
      request.fields['is_active'] = '1'; // always active for user insert
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
        AppLogger.info('InsertDetailsPageNo success', tag: 'INSERT_NO');
        // Mark success BEFORE the navigator call so PopScope sees the
        // updated flag while the route is being popped/replaced.
        _detailsSavedSuccessfully = true;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SaveSuccessPage()),
        );
      } else {
        String msg = decoded['message']?.toString() ?? 'Error';
        if (decoded['image_errors'] != null) {
          msg += '\n${(decoded['image_errors'] as List).join(', ')}';
        }
        AppLogger.error('Insert failed: $msg', tag: 'INSERT_NO');
        _snack(isArabic ? 'خطأ: $msg' : 'هەڵە: $msg');
      }
    } catch (e) {
      AppLogger.error('Insert exception: $e', tag: 'INSERT_NO');
      _snack(isArabic ? 'حدث خطأ: $e' : 'هەڵەیەک ڕوویدا: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // ── Rollback path ────────────────────────────────────────
  // Triggered when the user tries to leave this page after registering
  // but before submitting the work-details form. Confirms with the
  // user, deletes their freshly-created user record on the server, and
  // clears local UserModel state so they can register again.

  Future<bool> _onWillPop() async {
    if (_detailsSavedSuccessfully) return true;
    if (!widget.requireDetailsOrRollback) return true;
    if (_isSubmitting) return false; // never abandon mid-submit
    if (_rollbackInFlight) return false;

    final confirm = await _showAbortDialog();
    if (confirm != true || !mounted) return false;

    setState(() => _rollbackInFlight = true);

    // Step 1: log out locally FIRST. This clears the UserModel and
    // SharedPreferences before we hit the network — so even if the
    // delete request fails, the user isn't left in a logged-in state
    // for an account that's about to be removed (or already gone).
    Provider.of<UserModel>(context, listen: false).clearUser();

    // Step 2: ask the server to remove the user. We treat "User not
    // found" as success because the desired end state — no such user
    // — is already achieved.
    final ok = await _rollbackRegistration();
    if (!mounted) return false;
    setState(() => _rollbackInFlight = false);

    if (!ok) {
      _snack(S.registerAbortFailedSnack.of(context));
      return false;
    }

    // Step 3: navigate to the register page so the user can sign up
    // again, with a snackbar explaining why they were sent back.
    // We use the global navigator/messenger keys because the
    // pushNamedAndRemoveUntil call below unmounts this widget — any
    // context-based lookup done after would be invalid.
    final message = S.registerRolledBackSnack.of(context);
    navigatorKey.currentState
        ?.pushNamedAndRemoveUntil('/register', (_) => false);
    scaffoldMessengerKey.currentState?.showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: AppTheme.error,
      duration: const Duration(seconds: 4),
    ));

    // We've already navigated ourselves — tell PopScope to skip its
    // own pop so we don't try to pop a route that no longer exists.
    return false;
  }

  Future<bool?> _showAbortDialog() {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(
          S.registerAbortTitle.of(context),
          style: const TextStyle(
            fontFamily: 'NotoKufi',
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          S.registerAbortMessage.of(context),
          style: const TextStyle(fontFamily: 'NotoKufi', height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(S.registerAbortCancel.of(context)),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(S.registerAbortConfirm.of(context)),
          ),
        ],
      ),
    );
  }

  Future<bool> _rollbackRegistration() async {
    final id = widget.pendingUserId;
    if (id == null) {
      AppLogger.warning(
          'No pendingUserId — skipping server delete (client-only rollback)',
          tag: 'INSERT_NO');
      return true;
    }
    AppLogger.info('Rolling back registration: id=$id', tag: 'INSERT_NO');
    final r = await ApiService.instance.post(
      AppConstants.deleteUserEndpoint,
      fields: {'id': id.toString()},
    );
    if (r.success) {
      AppLogger.info('Rollback OK', tag: 'INSERT_NO');
      return true;
    }

    // "User not found" means the row is already gone — the desired
    // end state. Count it as a successful rollback so we don't trap
    // the user on this page with no way to leave.
    final err = (r.error ?? '').toLowerCase();
    if (err.contains('user not found') || err.contains('not found')) {
      AppLogger.info('Rollback: user already gone — treating as success',
          tag: 'INSERT_NO');
      return true;
    }

    AppLogger.error('Rollback failed: ${r.error}', tag: 'INSERT_NO');
    return false;
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
    return PopScope(
      // Block automatic pop so we can run the rollback flow first.
      // canPop = true once the form has been submitted successfully —
      // at that point the user is fully registered and free to leave.
      canPop: _detailsSavedSuccessfully || !widget.requireDetailsOrRollback,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldLeave = await _onWillPop();
        if (shouldLeave && mounted) {
          Navigator.of(context).pop();
        }
      },
      child: AppScaffold(
      title: S.insertNoTitle.of(context),
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
      ),
    );
  }

  // ── Hero card (welcoming for users) ───────────────────────

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
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.22),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white54, width: 1.5),
            ),
            child: const Icon(Icons.assignment_add,
                size: 32, color: Colors.white),
          ),
          const SizedBox(height: 14),
          Text(
            S.insertNoTitle.of(context),
            style: AppTheme.headingLarge.copyWith(fontSize: 18),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            S.insertNoBanner.of(context),
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
          _fieldLabel(S.insertNoWorkType.of(context)),
          const SizedBox(height: 6),
          _dropdown(
            S.insertNoWorkType.of(context),
            Icons.work_rounded,
            _subCategories,
            _selectedSubCategory,
            (v) => setState(() => _selectedSubCategory = v),
          ),
          const SizedBox(height: 16),
          _fieldLabel(S.insertNoUserLabel.of(context)),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: _selectedUser,
            isExpanded: true,
            icon: const Icon(Icons.lock_outline_rounded,
                color: AppTheme.textMuted, size: 18),
            decoration: InputDecoration(
              hintText: S.insertNoUserLabel.of(context),
              prefixIcon:
                  const Icon(Icons.person_rounded, color: AppTheme.primary),
              fillColor: AppTheme.background,
            ),
            items: _users
                .map((u) => DropdownMenuItem<String>(
                      value: u['id'].toString(),
                      child: Text(u['full_name']?.toString() ?? '',
                          overflow: TextOverflow.ellipsis),
                    ))
                .toList(),
            onChanged: null, // disabled — auto-selected
            validator: (v) =>
                v == null ? S.insertNoUserRequired.of(context) : null,
          ),
          const SizedBox(height: 16),
          _fieldLabel(S.insertNoNameLabel.of(context)),
          const SizedBox(height: 6),
          _field(_nameCtrl, S.insertNoNameLabel.of(context),
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
              return S.insertNoContactRequired.of(context);
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
          _fieldLabel(S.insertNoDescLabel.of(context)),
          const SizedBox(height: 6),
          _field(_descCtrl, S.insertNoDescLabel.of(context),
              Icons.description_rounded, maxLines: 3, validator: (v) {
            if (v == null || v.isEmpty) {
              return S.insertNoDescRequired.of(context);
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
            title: S.insertNoAddImagesLabel.of(context),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: _pickImages,
            icon: const Icon(Icons.add_a_photo_rounded, size: 18),
            label: Text(S.insertNoAddImagesLabel.of(context)),
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

  // ── Submit ───────────────────────────────────────────────

  Widget _buildSubmitButton(BuildContext context) {
    return SizedBox(
      height: AppTheme.buttonHeight,
      child: ElevatedButton.icon(
        onPressed: _isSubmitting ? null : _insertData,
        icon: _isSubmitting
            ? const SizedBox.shrink()
            : const Icon(Icons.send_rounded, size: 18),
        label: _isSubmitting
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : Text(S.insertNoSubmit.of(context)),
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
