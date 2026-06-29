// lib/screens/user_details_page.dart

import 'package:flutter/material.dart';

import '../core/app_constants.dart';
import '../core/app_logger.dart';
import '../core/app_strings.dart';
import '../core/app_theme.dart';
import '../main.dart' show LocaleContext;
import '../services/api_service.dart';
import '../widgets/app_scaffold.dart';
import 'view_users_screen.dart';

class UserDetailsPage extends StatefulWidget {
  final int userId;
  const UserDetailsPage({required this.userId, Key? key}) : super(key: key);

  @override
  _UserDetailsPageState createState() => _UserDetailsPageState();
}

class _UserDetailsPageState extends State<UserDetailsPage> {
  bool _isLoading = true;
  bool _isUpdating = false;

  final List<String> _cities = AppConstants.cities;
  List<Map<String, dynamic>> _workTypes = [];
  int? _isApproved;

  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _paymentController = TextEditingController();
  final _subscriptionController = TextEditingController();
  String? _selectedCity;
  String? _selectedWorkTypeId;

  @override
  void initState() {
    super.initState();
    AppLogger.info('UserDetailsPage — userId: ${widget.userId}',
        tag: 'USER_DETAIL');
    Future.wait([_fetchUserDetails(), _fetchWorkTypes()]);
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _paymentController.dispose();
    _subscriptionController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserDetails() async {
    AppLogger.info('Fetching user details: ${widget.userId}',
        tag: 'USER_DETAIL');
    // Cache-bust so a fresh edit dialog opens with current values,
    // not a stale 5-minute-old copy.
    final response = await ApiService.instance.get(
      AppConstants.getUserDetailsEndpoint,
      queryParams: {
        'id': widget.userId.toString(),
        '_t': DateTime.now().millisecondsSinceEpoch.toString(),
      },
    );
    if (!mounted) return;

    if (response.success && response.data != null) {
      final data = response.data!;
      if (data['status'] == 'success') {
        final user = data['data'] as Map<String, dynamic>;
        AppLogger.info('User details loaded: ${user['full_name']}',
            tag: 'USER_DETAIL');
        setState(() {
          _fullNameController.text = user['full_name'] ?? '';
          _phoneController.text = user['phone_number'] ?? '';
          _paymentController.text = user['payment_amount']?.toString() ?? '0';
          _subscriptionController.text = user['subscription_expiry'] ?? '';
          _selectedCity =
              _cities.contains(user['city']) ? user['city'] : null;
          _selectedWorkTypeId = user['type_of_work_id']?.toString();
          _isApproved = int.tryParse(user['is_approved'].toString()) ?? 0;
          _isLoading = false;
        });
      } else {
        _showSnack(data['message']?.toString() ?? 'Error');
        setState(() => _isLoading = false);
      }
    } else {
      AppLogger.error('User details failed: ${response.error}',
          tag: 'USER_DETAIL');
      _showSnack(response.error ?? 'Failed to load');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchWorkTypes() async {
    final response =
        await ApiService.instance.get(AppConstants.activeCategoriesEndpoint);
    if (!mounted) return;
    if (response.success && response.data != null) {
      final data = response.data!;
      if (data['success'] == true) {
        setState(() {
          _workTypes = List<Map<String, dynamic>>.from(data['data'] as List);
        });
      }
    }
  }

  Future<void> _updateUserDetails() async {
    setState(() => _isUpdating = true);
    AppLogger.info('Updating user: ${widget.userId}', tag: 'USER_DETAIL');

    final response = await ApiService.instance.post(
      AppConstants.updateUserEndpoint,
      jsonBody: {
        'id': widget.userId,
        'full_name': _fullNameController.text,
        'phone_number': _phoneController.text,
        'city': _selectedCity ?? '',
        'type_of_work_id': _selectedWorkTypeId ?? '0',
        'payment_amount': _paymentController.text,
        'subscription_expiry': _subscriptionController.text,
        'is_approved': _isApproved.toString(),
      },
    );

    if (!mounted) return;
    setState(() => _isUpdating = false);

    if (response.success) {
      AppLogger.info('User updated successfully', tag: 'USER_DETAIL');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(S.userDetailsUpdateSuccess.of(context)),
        backgroundColor: AppTheme.success,
      ));
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => ViewUsersScreen()));
    } else {
      AppLogger.error('Update failed: ${response.error}', tag: 'USER_DETAIL');
      final isArabic = context.isArabic;
      _showSnack(isArabic
          ? 'فشل التحديث: ${response.error}'
          : 'نوێکردنەوە سەرنەکەوت: ${response.error}');
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppTheme.error,
    ));
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _subscriptionController.text =
          picked.toLocal().toString().split(' ')[0]);
    }
  }

  // ── BUILD ────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: S.userDetailsTitle.of(context),
      showDrawer: false,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.accent))
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHero(context),
                  const SizedBox(height: 18),
                  _buildIdentitySection(context),
                  const SizedBox(height: 14),
                  _buildSubscriptionSection(context),
                  const SizedBox(height: 14),
                  _buildApprovalSection(context),
                  const SizedBox(height: 22),
                  _buildSubmitButton(context),
                ],
              ),
            ),
    );
  }

  // ── Hero ─────────────────────────────────────────────────

  Widget _buildHero(BuildContext context) {
    final name = _fullNameController.text.trim();
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
            child: const Icon(Icons.person_rounded,
                color: Colors.white, size: 30),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  S.userDetailsEditHeader.of(context),
                  style: AppTheme.captionWhite.copyWith(fontSize: 11),
                ),
                const SizedBox(height: 4),
                Text(
                  name.isEmpty ? '—' : name,
                  style: AppTheme.headingLarge.copyWith(fontSize: 17),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Identity ─────────────────────────────────────────────

  Widget _buildIdentitySection(BuildContext context) {
    return _card(
      icon: Icons.badge_rounded,
      title: S.fullNameLabel.of(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _fieldLabel(S.fullNameLabel.of(context)),
          const SizedBox(height: 6),
          TextFormField(
            controller: _fullNameController,
            decoration: const InputDecoration(
              prefixIcon:
                  Icon(Icons.person_rounded, color: AppTheme.primary),
            ),
            style: const TextStyle(fontFamily: 'NotoKufi', fontSize: 14),
          ),
          const SizedBox(height: 14),
          _fieldLabel(S.phoneNumberLabel.of(context)),
          const SizedBox(height: 6),
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.phone_rounded, color: AppTheme.primary),
            ),
            style: const TextStyle(fontFamily: 'NotoKufi', fontSize: 14),
          ),
          const SizedBox(height: 14),
          _fieldLabel(S.cityLabel.of(context)),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: _selectedCity,
            isExpanded: true,
            icon: const Icon(Icons.keyboard_arrow_down_rounded,
                color: AppTheme.textMuted),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.location_city_rounded,
                  color: AppTheme.primary),
            ),
            items: _cities
                .map((c) => DropdownMenuItem(
                      value: c,
                      child: Text(c,
                          style: const TextStyle(
                              fontFamily: 'NotoKufi', fontSize: 14)),
                    ))
                .toList(),
            onChanged: (v) => setState(() => _selectedCity = v),
          ),
          const SizedBox(height: 14),
          _fieldLabel(S.workTypeLabel.of(context)),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: _selectedWorkTypeId,
            isExpanded: true,
            icon: const Icon(Icons.keyboard_arrow_down_rounded,
                color: AppTheme.textMuted),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.work_rounded, color: AppTheme.primary),
            ),
            items: _workTypes
                .map((t) => DropdownMenuItem(
                      value: t['id'].toString(),
                      child: Text(t['name'].toString(),
                          style: const TextStyle(
                              fontFamily: 'NotoKufi', fontSize: 14),
                          overflow: TextOverflow.ellipsis),
                    ))
                .toList(),
            onChanged: (v) => setState(() => _selectedWorkTypeId = v),
          ),
        ],
      ),
    );
  }

  // ── Subscription ─────────────────────────────────────────

  Widget _buildSubscriptionSection(BuildContext context) {
    return _card(
      icon: Icons.subscriptions_rounded,
      title: S.userDetailsSubscriptionDate.of(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _fieldLabel(S.paymentAmountLabel.of(context)),
          const SizedBox(height: 6),
          TextFormField(
            controller: _paymentController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.monetization_on_rounded,
                  color: AppTheme.primary),
            ),
            style: const TextStyle(fontFamily: 'NotoKufi', fontSize: 14),
          ),
          const SizedBox(height: 14),
          _fieldLabel(S.userDetailsSubscriptionDate.of(context)),
          const SizedBox(height: 6),
          InkWell(
            onTap: _pickDate,
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            child: InputDecorator(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.calendar_today_rounded,
                    color: AppTheme.primary),
                suffixIcon: Icon(Icons.edit_calendar_rounded,
                    color: AppTheme.textMuted),
              ),
              child: Text(
                _subscriptionController.text.isEmpty
                    ? S.userDetailsPickDate.of(context)
                    : _subscriptionController.text,
                style: TextStyle(
                  fontFamily: 'NotoKufi',
                  fontSize: 14,
                  color: _subscriptionController.text.isEmpty
                      ? AppTheme.textMuted
                      : AppTheme.textPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Approval ────────────────────────────────────────────

  Widget _buildApprovalSection(BuildContext context) {
    return _card(
      icon: Icons.verified_user_rounded,
      title: S.userDetailsApprovalLabel.of(context),
      child: Row(
        children: [
          Expanded(
            child: _approvalChoice(
              value: 1,
              label: S.yes.of(context),
              icon: Icons.check_circle_rounded,
              color: AppTheme.success,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _approvalChoice(
              value: 0,
              label: S.no.of(context),
              icon: Icons.cancel_rounded,
              color: AppTheme.error,
            ),
          ),
        ],
      ),
    );
  }

  Widget _approvalChoice({
    required int value,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    final selected = _isApproved == value;
    return Material(
      color: selected ? color.withOpacity(0.12) : AppTheme.background,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        onTap: () => setState(() => _isApproved = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(
              color: selected ? color : AppTheme.divider,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  color: selected ? color : AppTheme.textMuted, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'NotoKufi',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: selected ? color : AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Submit ──────────────────────────────────────────────

  Widget _buildSubmitButton(BuildContext context) {
    return SizedBox(
      height: AppTheme.buttonHeight,
      child: ElevatedButton.icon(
        onPressed: _isUpdating ? null : _updateUserDetails,
        icon: _isUpdating
            ? const SizedBox.shrink()
            : const Icon(Icons.save_rounded, size: 18),
        label: _isUpdating
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : Text(S.updateButton.of(context)),
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────

  Widget _card({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
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
              Expanded(child: Text(title, style: AppTheme.headingSmall)),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _fieldLabel(String text) => Text(
        text,
        style: const TextStyle(
          fontFamily: 'NotoKufi',
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppTheme.textSecondary,
        ),
      );
}
