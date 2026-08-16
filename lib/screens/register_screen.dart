// lib/screens/register_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/app_constants.dart';
import '../core/app_logger.dart';
import '../core/app_strings.dart';
import '../core/app_theme.dart';
import '../core/phone_utils.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../widgets/app_scaffold.dart';
import 'InsertDetailsPageNo.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();

  final List<String> _cities = AppConstants.cities;
  List<Map<String, dynamic>> _workTypes = [];
  String? _selectedCity;
  String? _selectedWorkTypeId;

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  static const int _selectedTabIndex = 1;

  @override
  void initState() {
    super.initState();
    _fetchWorkTypes();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneNumberController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ── Data loading ─────────────────────────────────────────

  Future<void> _fetchWorkTypes() async {
    AppLogger.info('Fetching work types...', tag: 'REGISTER');
    final response =
        await ApiService.instance.get(AppConstants.activeCategoriesEndpoint);
    if (!mounted) return;

    if (response.success && response.data != null) {
      final data = response.data!;
      if (data['success'] == true) {
        AppLogger.info('Work types loaded: ${(data['data'] as List).length}',
            tag: 'REGISTER');
        setState(() {
          _workTypes = List<Map<String, dynamic>>.from(data['data'] as List);
          _selectedWorkTypeId = null;
        });
      }
    } else {
      AppLogger.error('Work types fetch failed: ${response.error}',
          tag: 'REGISTER');
      _showMessage(
        S.registerLoadWorkTypesFailed.of(context),
        isSuccess: false,
      );
    }
  }

  // ── Submit ───────────────────────────────────────────────

  Future<void> _registerUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final normalizedPhone = IqPhone.normalize(_phoneNumberController.text);
    AppLogger.info('Registering user: $normalizedPhone', tag: 'REGISTER');

    final response = await ApiService.instance.post(
      AppConstants.registerEndpoint,
      jsonBody: {
        'full_name': _fullNameController.text.trim(),
        'phone_number': normalizedPhone, // 🔧 always 10-digit canonical form
        'password': _passwordController.text,
        'city': _selectedCity ?? '',
        'type_of_work_id': _selectedWorkTypeId ?? '0',
      },
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (response.success && response.data != null) {
      final data = response.data!;
      if (data['success'] == true) {
        AppLogger.info('Registration success', tag: 'REGISTER');
        Provider.of<UserModel>(context, listen: false).setUser(
          _fullNameController.text.trim(),
          normalizedPhone,
          'user',
          city: _selectedCity,
        );
        // Pull the new user's id out of whatever shape the backend
        // chose. Needed so we can roll back (delete the user) if they
        // abandon the work-details step.
        final newUserId = _extractNewUserId(data);
        AppLogger.info('Registered user id: $newUserId', tag: 'REGISTER');

        // Skip the intermediate "you are registered" page — push
        // straight to the work-details form. If the user abandons it
        // before submitting, that screen rolls the registration back.
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => InsertDetailsPageNo(
              phoneNumber: normalizedPhone,
              city: _selectedCity,
              pendingUserId: newUserId,
              requireDetailsOrRollback: true,
            ),
          ),
        );
      } else {
        AppLogger.warning('Registration failed: ${data['message']}',
            tag: 'REGISTER');
        _showMessage(
          data['message'] ?? S.registerOperationFailed.of(context),
          isSuccess: false,
        );
      }
    } else {
      AppLogger.error('Registration error: ${response.error}', tag: 'REGISTER');
      _showMessage(
        S.registerNetworkError.of(context),
        isSuccess: false,
      );
    }
  }

  /// Pulls the newly-inserted user's id out of the register response.
  /// Different versions of register_user.php have used 'id', 'user_id',
  /// or nested it under 'data'. Returns null if no id is present —
  /// the caller still proceeds (rollback will fall back to phone).
  int? _extractNewUserId(Map<String, dynamic> data) {
    int? tryParse(dynamic v) {
      if (v == null) return null;
      return int.tryParse(v.toString());
    }
    final direct = tryParse(data['id']) ?? tryParse(data['user_id']);
    if (direct != null) return direct;
    final inner = data['data'];
    if (inner is Map) {
      return tryParse(inner['id']) ?? tryParse(inner['user_id']);
    }
    return null;
  }

  void _showMessage(String message, {bool isSuccess = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: isSuccess ? AppTheme.success : AppTheme.error,
    ));
  }

  // ── BUILD ────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: S.registerTitle.of(context),
      footerIndex: _selectedTabIndex,
      body: Consumer<UserModel>(
        builder: (context, userModel, _) {
          if (userModel.name.isNotEmpty && userModel.phoneNumber.isNotEmpty) {
            return _buildAlreadyRegistered(context);
          }
          return _buildRegistrationForm(context);
        },
      ),
    );
  }

  // ── Already registered state ─────────────────────────────

  Widget _buildAlreadyRegistered(BuildContext context) {
    return _buildSuccessState(
      context: context,
      title: S.registerAlreadyDone.of(context),
      subtitle: S.registerAlreadyDoneSubtitle.of(context),
      buttonLabel: S.registerGoHome.of(context),
      buttonIcon: Icons.home_rounded,
      onPressed: () => Navigator.pushReplacementNamed(context, '/dashboard'),
    );
  }

  /// Shared success layout used by both the just-registered and
  /// already-registered states.
  Widget _buildSuccessState({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String buttonLabel,
    required IconData buttonIcon,
    required VoidCallback onPressed,
  }) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              color: AppTheme.success.withOpacity(0.10),
              shape: BoxShape.circle,
              border: Border.all(
                  color: AppTheme.success.withOpacity(0.30), width: 2),
            ),
            child: const Icon(Icons.check_circle_rounded,
                color: AppTheme.success, size: 64),
          ),
          const SizedBox(height: 22),
          Text(
            title,
            style: AppTheme.headingMedium.copyWith(
              fontSize: 20,
              color: AppTheme.success,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: AppTheme.bodySmall.copyWith(
              fontSize: 13,
              color: AppTheme.textSecondary,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: AppTheme.buttonHeight,
            child: ElevatedButton.icon(
              onPressed: onPressed,
              icon: Icon(buttonIcon, size: 18),
              label: Text(buttonLabel),
            ),
          ),
        ],
      ),
    );
  }

  // ── Registration form ────────────────────────────────────

  Widget _buildRegistrationForm(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHero(context),
          const SizedBox(height: 18),
          _buildFormCard(context),
          const SizedBox(height: 14),
          _buildInfoNote(context),
        ],
      ),
    );
  }

  Widget _buildHero(BuildContext context) {
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
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.22),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white54, width: 1.5),
            ),
            child: const Icon(Icons.app_registration_rounded,
                size: 32, color: Colors.white),
          ),
          const SizedBox(height: 14),
          Text(
            S.registerNow.of(context),
            style: AppTheme.headingLarge.copyWith(fontSize: 19),
          ),
          const SizedBox(height: 6),
          Text(
            S.registerHeroSubtitle.of(context),
            style: AppTheme.captionWhite.copyWith(fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: AppTheme.softShadow,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _fieldLabel(S.registerFullNameLabel.of(context)),
            const SizedBox(height: 6),
            TextFormField(
              controller: _fullNameController,
              decoration: InputDecoration(
                hintText: S.registerFullNameHint.of(context),
                prefixIcon:
                    const Icon(Icons.person_rounded, color: AppTheme.primary),
              ),
              style: const TextStyle(fontFamily: 'NotoKufi', fontSize: 14),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? S.fieldRequired.of(context)
                  : null,
            ),
            const SizedBox(height: 16),
            _fieldLabel(S.registerPhoneLabel.of(context)),
            const SizedBox(height: 6),
            TextFormField(
              controller: _phoneNumberController,
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                hintText: S.registerPhoneHint.of(context),
                prefixIcon:
                    const Icon(Icons.phone_rounded, color: AppTheme.primary),
              ),
              style: const TextStyle(fontFamily: 'NotoKufi', fontSize: 14),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return S.fieldRequired.of(context);
                }
                if (!IqPhone.isValid(v.trim())) {
                  return S.registerPhoneIraqiInvalid.of(context);
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _fieldLabel(S.registerCityLabel.of(context)),
            const SizedBox(height: 6),
            _buildDropdown<String>(
              hint: S.registerCityHint.of(context),
              icon: Icons.location_city_rounded,
              value: _selectedCity,
              items: _cities
                  .map((c) => DropdownMenuItem<String>(
                        value: c,
                        child: Text(c,
                            style: const TextStyle(
                                fontFamily: 'NotoKufi', fontSize: 14)),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _selectedCity = v),
            ),
            const SizedBox(height: 16),
            _fieldLabel(S.registerWorkTypeLabel.of(context)),
            const SizedBox(height: 6),
            _buildDropdown<String>(
              hint: S.registerWorkTypeHint.of(context),
              icon: Icons.work_rounded,
              value: _selectedWorkTypeId,
              items: _workTypes
                  .map((it) => DropdownMenuItem<String>(
                        value: it['id'].toString(),
                        child: Text(
                          it['name'].toString(),
                          style: const TextStyle(
                              fontFamily: 'NotoKufi', fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _selectedWorkTypeId = v),
            ),
            const SizedBox(height: 16),
            _fieldLabel(S.passwordLabel.of(context)),
            const SizedBox(height: 6),
            TextFormField(
              controller: _passwordController,
              obscureText: !_isPasswordVisible,
              decoration: InputDecoration(
                hintText: S.registerPasswordHint.of(context),
                prefixIcon:
                    const Icon(Icons.lock_rounded, color: AppTheme.primary),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility_rounded
                        : Icons.visibility_off_rounded,
                    color: AppTheme.textMuted,
                    size: 20,
                  ),
                  onPressed: () =>
                      setState(() => _isPasswordVisible = !_isPasswordVisible),
                ),
              ),
              style: const TextStyle(fontFamily: 'NotoKufi', fontSize: 14),
              validator: (v) =>
                  (v == null || v.isEmpty) ? S.fieldRequired.of(context) : null,
            ),
            const SizedBox(height: 22),
            SizedBox(
              height: AppTheme.buttonHeight,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _registerUser,
                icon: _isLoading
                    ? const SizedBox.shrink()
                    : const Icon(Icons.app_registration_rounded, size: 18),
                label: _isLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(S.registerSubmit.of(context)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoNote(BuildContext context) {
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
              S.registerInfoNote.of(context),
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

  // ── Helpers ──────────────────────────────────────────────

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

  Widget _buildDropdown<T>({
    required String hint,
    required IconData icon,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      isExpanded: true,
      icon: const Icon(Icons.keyboard_arrow_down_rounded,
          color: AppTheme.textMuted),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: AppTheme.primary),
      ),
      items: items,
      onChanged: onChanged,
      validator: (v) => v == null ? S.fieldRequired.of(context) : null,
    );
  }
}
