// lib/screens/login_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/app_constants.dart';
import '../core/app_logger.dart';
import '../core/app_strings.dart';
import '../core/app_theme.dart';
import '../core/phone_utils.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../widgets/app_scaffold.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _inputController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _inputController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    String input = _inputController.text.trim();
    final String password = _passwordController.text.trim();

    if (input.isEmpty || password.isEmpty) {
      _showMessage(S.loginPromptInputs.of(context));
      return;
    }

    // If the user typed a phone number, normalize it (strip leading 0,
    // spaces, country code). If they typed a username, leave it alone.
    if (IqPhone.looksLikePhone(input)) {
      input = IqPhone.normalize(input);
    }

    setState(() => _isLoading = true);
    AppLogger.info('Login attempt: $input', tag: 'LOGIN');

    final response = await ApiService.instance.post(
      AppConstants.loginEndpoint,
      jsonBody: {'input': input, 'password': password},
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (response.success && response.data != null) {
      final data = response.data!;
      if (data['status'] == 'success') {
        AppLogger.info('Login success: ${data['name']}', tag: 'LOGIN');

        Provider.of<UserModel>(context, listen: false).setUser(
          data['name'],
          data['phone_number'],
          data['role'],
        );

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString(AppConstants.prefUserName, data['name']);
        await prefs.setString(
            AppConstants.prefPhoneNumber, data['phone_number']);
        await prefs.setString(AppConstants.prefRole, data['role']);
        if (data.containsKey('id')) {
          await prefs.setInt(
              'user_id', int.tryParse(data['id'].toString()) ?? 0);
        }

        _showMessage(data['message'] ?? '', success: true);
        Navigator.pushReplacementNamed(context, '/dashboard');
      } else {
        AppLogger.warning('Login failed: ${data['message']}', tag: 'LOGIN');
        _showMessage(data['message'] ?? S.loginFailed.of(context));
      }
    } else {
      AppLogger.error('Login error: ${response.error}', tag: 'LOGIN');
      _showMessage(S.loginNetworkError.of(context));
    }
  }

  void _showMessage(String message, {bool success = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: success ? AppTheme.success : AppTheme.error,
    ));
  }

  // ── BUILD ────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: S.loginAppBarTitle.of(context),
      showDrawer: false,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHero(context),
            const SizedBox(height: 18),
            _buildFormCard(context),
            const SizedBox(height: 14),
            _buildRegisterPrompt(context),
          ],
        ),
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
                      child: Icon(Icons.login_rounded,
                          size: 30, color: AppTheme.primary),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            S.loginAppBarTitle.of(context),
            style: AppTheme.headingLarge.copyWith(fontSize: 20),
          ),
          const SizedBox(height: 6),
          Text(
            S.loginInstruction.of(context),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _fieldLabel(S.loginInputLabel.of(context)),
          const SizedBox(height: 6),
          TextField(
            controller: _inputController,
            keyboardType: TextInputType.phone,
            style: const TextStyle(fontFamily: 'NotoKufi', fontSize: 14),
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              hintText: S.loginInputLabel.of(context),
              prefixIcon:
                  const Icon(Icons.person_rounded, color: AppTheme.primary),
            ),
          ),
          const SizedBox(height: 16),
          _fieldLabel(S.loginPasswordLabel.of(context)),
          const SizedBox(height: 6),
          TextField(
            controller: _passwordController,
            obscureText: !_isPasswordVisible,
            style: const TextStyle(fontFamily: 'NotoKufi', fontSize: 14),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _isLoading ? null : _login(),
            decoration: InputDecoration(
              hintText: S.loginPasswordLabel.of(context),
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
          ),
          const SizedBox(height: 4),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/forget_password'),
              icon: const Icon(Icons.help_outline_rounded, size: 16),
              label: Text(S.loginForgotPassword.of(context)),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                visualDensity: VisualDensity.compact,
              ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: AppTheme.buttonHeight,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _login,
              icon: _isLoading
                  ? const SizedBox.shrink()
                  : const Icon(Icons.login_rounded, size: 18),
              label: _isLoading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(S.loginButton.of(context)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterPrompt(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        onTap: () => Navigator.pushReplacementNamed(context, '/register'),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.primary.withOpacity(0.06),
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border:
                Border.all(color: AppTheme.primary.withOpacity(0.20), width: 1),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.14),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_add_rounded,
                    color: AppTheme.primary, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  S.loginRegisterPrompt.of(context),
                  style: const TextStyle(
                    fontFamily: 'NotoKufi',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primary,
                    height: 1.4,
                  ),
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded,
                  size: 14, color: AppTheme.primary),
            ],
          ),
        ),
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
