// lib/screens/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/app_constants.dart';
import '../core/app_logger.dart';
import '../core/app_strings.dart';
import '../core/app_theme.dart';
import '../services/api_service.dart';
import '../widgets/app_scaffold.dart';

class ProfileScreen extends StatefulWidget {
  final String userName;
  final String phoneNumber;

  const ProfileScreen({
    required this.userName,
    required this.phoneNumber,
    Key? key,
  }) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  bool _hasError = false;
  Map<String, dynamic> _userData = {};

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    AppLogger.info('Fetching profile: ${widget.phoneNumber}', tag: 'PROFILE');

    final response = await ApiService.instance.post(
      AppConstants.getUserDataEndpoint,
      jsonBody: {'phone_number': widget.phoneNumber},
    );

    if (!mounted) return;

    if (response.success && response.data != null) {
      final data = response.data!;
      if (data['status'] == 'success') {
        AppLogger.info('Profile loaded successfully', tag: 'PROFILE');
        setState(() {
          _userData = data['data'] as Map<String, dynamic>;
          _isLoading = false;
        });
      } else {
        AppLogger.warning('Profile not found: ${data['message']}',
            tag: 'PROFILE');
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    } else {
      AppLogger.error('Profile fetch failed: ${response.error}',
          tag: 'PROFILE');
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  String _formatDate(String? date) {
    if (date == null || date.isEmpty || date == '0000-00-00 00:00:00') {
      return 'نەمانە';
    }
    try {
      return DateFormat('yyyy-MM-dd').format(DateTime.parse(date));
    } catch (_) {
      return 'نەمانە';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: S.profileTitle.of(context),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.accent))
          : _hasError
              ? _buildErrorState(context)
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildProfileHeader(),
                      const SizedBox(height: 20),
                      _buildInfoCard(context),
                    ],
                  ),
                ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
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
              S.profileFetchError.of(context),
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
                  _fetchUserData();
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

  Widget _buildProfileHeader() {
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
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.22),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white54, width: 1.5),
            ),
            child: const Icon(Icons.person_rounded,
                size: 34, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.userName,
                    style: AppTheme.headingLarge.copyWith(fontSize: 17),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                Row(children: [
                  const Icon(Icons.phone_rounded,
                      size: 14, color: Colors.white70),
                  const SizedBox(width: 6),
                  Text(widget.phoneNumber,
                      style: AppTheme.captionWhite.copyWith(fontSize: 13)),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              S.profileInfoSection.of(context),
              style: AppTheme.headingMedium.copyWith(color: AppTheme.primary),
            ),
            const SizedBox(height: 14),
            _infoTile(
              icon: Icons.monetization_on_rounded,
              iconColor: AppTheme.success,
              title: S.profilePaymentLabel.of(context),
              value:
                  '${_userData['payment_amount'] ?? 0} ${S.profileDinar.of(context)}',
            ),
            const Divider(height: 18),
            _infoTile(
              icon: _userData['is_approved'] == 1
                  ? Icons.check_circle_rounded
                  : Icons.cancel_rounded,
              iconColor: _userData['is_approved'] == 1
                  ? AppTheme.success
                  : AppTheme.error,
              title: S.profileActiveStatus.of(context),
              value: _userData['is_approved'] == 1
                  ? S.profileActive.of(context)
                  : S.profileInactive.of(context),
            ),
            const Divider(height: 18),
            _infoTile(
              icon: Icons.date_range_rounded,
              iconColor: AppTheme.accent,
              title: S.expiryDateLabel.of(context),
              value: _formatDate(
                  _userData['subscription_expiry']?.toString()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
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
              Text(title,
                  style: const TextStyle(
                    fontFamily: 'NotoKufi',
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  )),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(
                    fontFamily: 'NotoKufi',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  )),
            ],
          ),
        ),
      ],
    );
  }
}
