// lib/screens/UserInfoPage.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_constants.dart';
import '../core/app_logger.dart';
import '../core/app_strings.dart';
import '../core/app_theme.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../widgets/app_scaffold.dart';
import 'InsertDetailsPageNo.dart';

class UserInfoPage extends StatefulWidget {
  const UserInfoPage({Key? key}) : super(key: key);

  @override
  _UserInfoPageState createState() => _UserInfoPageState();
}

class _UserInfoPageState extends State<UserInfoPage> {
  Map<String, dynamic>? _userInfo;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    AppLogger.info('UserInfoPage init', tag: 'USERINFO');
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchUserInfo());
  }

  Future<void> _fetchUserInfo() async {
    final userModel = Provider.of<UserModel>(context, listen: false);
    final phoneNumber = userModel.phoneNumber.trim();
    final currentRole = userModel.role;

    AppLogger.info('Fetching user info for: $phoneNumber', tag: 'USERINFO');

    if (phoneNumber.isEmpty) {
      AppLogger.warning('Phone number is empty — cannot fetch',
          tag: 'USERINFO');
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
      return;
    }

    final response = await ApiService.instance.get(
      AppConstants.getUserInfoEndpoint,
      queryParams: {'phone_number': phoneNumber},
    );

    if (!mounted) return;

    if (response.success && response.data != null) {
      final data = response.data!;
      if (data['success'] == true && data['data'] != null) {
        AppLogger.info('User info loaded successfully', tag: 'USERINFO');
        final info = Map<String, dynamic>.from(data['data'] as Map);
        setState(() {
          _userInfo = info;
          _isLoading = false;
          _hasError = false;
        });
        // Update UserModel while keeping role
        userModel.setUser(
          info['full_name'] ?? '',
          info['phone_number'] ?? '',
          currentRole,
          city: info['city'] ?? '',
        );
      } else {
        AppLogger.warning('User info API returned success=false',
            tag: 'USERINFO');
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    } else {
      AppLogger.error('User info fetch failed: ${response.error}',
          tag: 'USERINFO');
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: S.userInfoTitle.of(context),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.accent))
          : _hasError
              ? _buildError(context)
              : _buildContent(context),
    );
  }

  // ── Error state ───────────────────────────────────────────

  Widget _buildError(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 64, color: AppTheme.error),
            const SizedBox(height: 16),
            Text(
              S.userInfoErrorBody.of(context),
              style: AppTheme.bodyMedium.copyWith(color: AppTheme.error),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 200,
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _hasError = false;
                  });
                  _fetchUserInfo();
                },
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(S.retry.of(context)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Content ───────────────────────────────────────────────

  Widget _buildContent(BuildContext context) {
    final userModel = Provider.of<UserModel>(context, listen: false);

    return RefreshIndicator(
      onRefresh: _fetchUserInfo,
      color: AppTheme.accent,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeroCard(context),
            const SizedBox(height: 18),
            _buildInfoCard(context),
            const SizedBox(height: 14),
            _buildThanksNote(context),
            const SizedBox(height: 22),
            _buildAddMoreButton(context, userModel),
          ],
        ),
      ),
    );
  }

  // ── Hero card ─────────────────────────────────────────────

  Widget _buildHeroCard(BuildContext context) {
    final fullName = _userInfo?['full_name']?.toString() ?? '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: AppTheme.appBarGradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: AppTheme.appBarShadow,
      ),
      child: Column(
        children: [
          // Logo / avatar in a layered circle
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.16),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white38, width: 1.5),
            ),
            child: Center(
              child: Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/logo.png',
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Center(
                      child: Icon(Icons.person_rounded,
                          size: 30, color: AppTheme.primary),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            S.userInfoThanksTitle.of(context),
            style: AppTheme.headingLarge.copyWith(fontSize: 20),
            textAlign: TextAlign.center,
          ),
          if (fullName.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.20),
                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                border: Border.all(color: Colors.white38, width: 0.8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.verified_user_rounded,
                      size: 12, color: Colors.white),
                  const SizedBox(width: 6),
                  Text(
                    fullName,
                    style: const TextStyle(
                      fontFamily: 'NotoKufi',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Text(
            S.userInfoSubtitle.of(context),
            style: AppTheme.captionWhite.copyWith(fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ── Info card ─────────────────────────────────────────────

  Widget _buildInfoCard(BuildContext context) {
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
          _infoRow(
            icon: Icons.person_rounded,
            iconColor: AppTheme.primary,
            label: S.userInfoFullNameLabel.of(context),
            value: _userInfo?['full_name']?.toString() ?? '—',
          ),
          const Divider(height: 22),
          _infoRow(
            icon: Icons.phone_rounded,
            iconColor: AppTheme.accent,
            label: S.phoneNumberLabelColon.of(context),
            value: _userInfo?['phone_number']?.toString() ?? '—',
            monospace: true,
          ),
          const Divider(height: 22),
          _infoRow(
            icon: Icons.location_city_rounded,
            iconColor: AppTheme.success,
            label: S.cityLabelColon.of(context),
            value: _userInfo?['city']?.toString() ?? '—',
          ),
          const Divider(height: 22),
          _infoRow(
            icon: Icons.work_rounded,
            iconColor: AppTheme.primary,
            label: S.workTypeLabelColon.of(context),
            value: _userInfo?['type_of_work']?.toString() ?? '—',
          ),
        ],
      ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    bool monospace = false,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'NotoKufi',
                  fontSize: 12,
                  color: AppTheme.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: TextStyle(
                  fontFamily: monospace ? null : 'NotoKufi',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                  letterSpacing: monospace ? 0.5 : 0,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Thanks note ───────────────────────────────────────────

  Widget _buildThanksNote(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.accent.withOpacity(0.06),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.accent.withOpacity(0.20), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppTheme.accent.withOpacity(0.14),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.info_outline_rounded,
                color: AppTheme.accent, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              S.userInfoThankYouMessage.of(context),
              style: AppTheme.bodySmall.copyWith(
                fontSize: 12,
                color: AppTheme.textSecondary,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Add-more CTA ──────────────────────────────────────────

  Widget _buildAddMoreButton(BuildContext context, UserModel userModel) {
    return SizedBox(
      width: double.infinity,
      height: AppTheme.buttonHeight,
      child: ElevatedButton.icon(
        onPressed: () {
          AppLogger.info('Navigate to InsertDetailsPageNo', tag: 'USERINFO');
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => InsertDetailsPageNo(
                phoneNumber: userModel.phoneNumber,
                city: userModel.city,
              ),
            ),
          );
        },
        icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
        label: Text(S.userInfoAddMore.of(context)),
      ),
    );
  }
}
