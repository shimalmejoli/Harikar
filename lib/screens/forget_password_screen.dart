// lib/screens/forget_password_screen.dart
// 3-step "Forgot password" flow with WhatsApp OTP.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_constants.dart';
import '../core/app_logger.dart';
import '../core/app_strings.dart';
import '../core/app_theme.dart';
import '../core/phone_utils.dart';
import '../services/api_service.dart';
import '../widgets/app_scaffold.dart';

enum _Step { phone, code, password }

class ForgetPasswordScreen extends StatefulWidget {
  const ForgetPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ForgetPasswordScreen> createState() => _ForgetPasswordScreenState();
}

class _ForgetPasswordScreenState extends State<ForgetPasswordScreen> {
  _Step _step = _Step.phone;

  final _phoneCtrl = TextEditingController();
  String _phoneNumber = '';
  String _verifyToken = '';

  bool _isSendingCode = false;

  final List<TextEditingController> _codeCtrls =
      List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _codeFocus = List.generate(4, (_) => FocusNode());
  bool _isVerifying = false;
  Timer? _resendTimer;
  int _resendSeconds = 0;
  static const int _resendCooldown = 60;

  final _newPwdCtrl = TextEditingController();
  final _confirmPwdCtrl = TextEditingController();
  bool _isResetting = false;
  bool _showNewPwd = false;
  bool _showConfirmPwd = false;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    for (final c in _codeCtrls) c.dispose();
    for (final f in _codeFocus) f.dispose();
    _newPwdCtrl.dispose();
    _confirmPwdCtrl.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  // ── Step 1: send code ───────────────────────────────────

  Future<void> _sendCode() async {
    final raw = _phoneCtrl.text.trim();
    final phone = IqPhone.normalize(raw); // canonical 10-digit form

    debugPrint('');
    debugPrint('======== FORGOT_PW : SEND CODE — REQUEST ========');
    debugPrint('  endpoint    : ${AppConstants.forgotPasswordSendEndpoint}');
    debugPrint('  raw input   : "$raw"');
    debugPrint('  normalized  : "$phone"  (length=${phone.length})');
    debugPrint('  isValid?    : ${IqPhone.isValid(raw)}');
    debugPrint('=================================================');

    if (!IqPhone.isValid(raw)) {
      debugPrint('FORGOT_PW : aborted — phone failed isValid()');
      _snack(S.forgotPasswordPhoneInvalid.of(context));
      return;
    }

    setState(() => _isSendingCode = true);
    AppLogger.info('Sending forgot-password code to: $phone', tag: 'FORGOT_PW');

    final body = {'phone_number': phone};
    debugPrint('FORGOT_PW : POST body = $body');

    final r = await ApiService.instance.post(
      AppConstants.forgotPasswordSendEndpoint,
      jsonBody: body,
    );

    if (!mounted) return;
    setState(() => _isSendingCode = false);

    debugPrint('');
    debugPrint('======== FORGOT_PW : SEND CODE — RESPONSE =======');
    debugPrint('  http status : ${r.statusCode}');
    debugPrint('  duration ms : ${r.durationMs}');
    debugPrint('  success     : ${r.success}');
    debugPrint('  error       : ${r.error}');
    debugPrint('  data        : ${r.data}');
    if (r.data != null) {
      r.data!.forEach((k, v) {
        debugPrint('    • $k = $v   (${v.runtimeType})');
      });
    }
    debugPrint('=================================================');
    debugPrint('');

    if (r.success) {
      AppLogger.info('Code sent, advancing to code step', tag: 'FORGOT_PW');
      setState(() {
        _phoneNumber = phone;
        _step = _Step.code;
      });
      _startResendCooldown();
      _snack(S.forgetPasswordSentSnack.of(context), success: true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _codeFocus.first.requestFocus();
      });
    } else {
      AppLogger.error('Send code failed: ${r.error}', tag: 'FORGOT_PW');
      _snack(r.error ?? S.forgotPasswordSendFailed.of(context));
    }
  }

  Future<void> _resendCode() async {
    if (_resendSeconds > 0) return;
    await _sendCode();
  }

  void _startResendCooldown() {
    _resendTimer?.cancel();
    setState(() => _resendSeconds = _resendCooldown);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _resendSeconds--);
      if (_resendSeconds <= 0) t.cancel();
    });
  }

  // ── Step 2: verify code ─────────────────────────────────

  String _collectedCode() => _codeCtrls.map((c) => c.text).join();

  Future<void> _verifyCode() async {
    final code = _collectedCode();
    if (code.length != 4) {
      _snack(S.forgotPasswordCodeRequired.of(context));
      return;
    }

    setState(() => _isVerifying = true);
    AppLogger.info('Verifying code for: $_phoneNumber', tag: 'FORGOT_PW');

    final r = await ApiService.instance.post(
      AppConstants.forgotPasswordVerifyEndpoint,
      jsonBody: {'phone_number': _phoneNumber, 'code': code},
    );

    if (!mounted) return;
    setState(() => _isVerifying = false);

    if (r.success && r.data != null && r.data!['token'] != null) {
      AppLogger.info('Code verified, token received', tag: 'FORGOT_PW');
      setState(() {
        _verifyToken = r.data!['token'].toString();
        _step = _Step.password;
      });
    } else {
      AppLogger.warning('Verify failed: ${r.error}', tag: 'FORGOT_PW');
      for (final c in _codeCtrls) c.clear();
      _codeFocus.first.requestFocus();
      _snack(r.error ?? S.forgotPasswordCodeWrong.of(context));
    }
  }

  void _backToPhoneStep() {
    setState(() {
      _step = _Step.phone;
      for (final c in _codeCtrls) c.clear();
      _resendTimer?.cancel();
      _resendSeconds = 0;
    });
  }

  // ── Step 3: reset password ──────────────────────────────

  Future<void> _resetPassword() async {
    final pwd = _newPwdCtrl.text;
    final confirm = _confirmPwdCtrl.text;

    if (pwd.length < 6) {
      _snack(S.forgotPasswordPasswordTooShort.of(context));
      return;
    }
    if (pwd != confirm) {
      _snack(S.forgotPasswordPasswordMismatch.of(context));
      return;
    }

    setState(() => _isResetting = true);
    AppLogger.info('Resetting password for: $_phoneNumber', tag: 'FORGOT_PW');

    final r = await ApiService.instance.post(
      AppConstants.forgotPasswordResetEndpoint,
      jsonBody: {
        'phone_number': _phoneNumber,
        'token': _verifyToken,
        'new_password': pwd,
      },
    );

    if (!mounted) return;
    setState(() => _isResetting = false);

    if (r.success) {
      AppLogger.info('Password reset successful', tag: 'FORGOT_PW');
      _snack(S.forgotPasswordResetSuccess.of(context), success: true);
      Navigator.pushReplacementNamed(context, '/login');
    } else {
      AppLogger.error('Reset failed: ${r.error}', tag: 'FORGOT_PW');
      final msg = r.error?.toLowerCase() ?? '';
      if (msg.contains('token') ||
          msg.contains('expired') ||
          msg.contains('invalid')) {
        _snack(S.forgotPasswordSessionExpired.of(context));
        setState(() => _step = _Step.phone);
      } else {
        _snack(r.error ?? S.forgotPasswordResetFailed.of(context));
      }
    }
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
      title: S.forgetPasswordTitle.of(context),
      showDrawer: false,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          switchInCurve: Curves.easeOut,
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.04),
                end: Offset.zero,
              ).animate(anim),
              child: child,
            ),
          ),
          child: KeyedSubtree(
            key: ValueKey(_step),
            child: switch (_step) {
              _Step.phone => _buildPhoneStep(context),
              _Step.code => _buildCodeStep(context),
              _Step.password => _buildPasswordStep(context),
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneStep(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHero(
          context,
          icon: Icons.lock_reset_rounded,
          step: 1,
          title: S.forgetPasswordTitle.of(context),
          subtitle: S.forgotPasswordHeroSubtitle.of(context),
        ),
        const SizedBox(height: 18),
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _fieldLabel(S.phoneNumberLabel.of(context)),
              const SizedBox(height: 6),
              TextField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(fontFamily: 'NotoKufi', fontSize: 14),
                decoration: const InputDecoration(
                  hintText: '0750 555 5555',
                  prefixIcon:
                      Icon(Icons.phone_rounded, color: AppTheme.primary),
                ),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _isSendingCode ? null : _sendCode(),
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: AppTheme.buttonHeight,
                child: ElevatedButton.icon(
                  onPressed: _isSendingCode ? null : _sendCode,
                  icon: _isSendingCode
                      ? const SizedBox.shrink()
                      : const Icon(Icons.send_rounded, size: 18),
                  label: _isSendingCode
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(S.forgetPasswordSendButton.of(context)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCodeStep(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHero(
          context,
          icon: Icons.message_rounded,
          step: 2,
          title: S.forgotPasswordCodeStepTitle.of(context),
          subtitle: S.forgotPasswordCodeStepSubtitle.of(context),
        ),
        const SizedBox(height: 18),
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  border: Border.all(color: AppTheme.primary.withOpacity(0.20)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.phone_rounded,
                        color: AppTheme.primary, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        IqPhone.pretty(_phoneNumber),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _backToPhoneStep,
                      icon: const Icon(Icons.edit_rounded, size: 14),
                      label: Text(
                        S.forgotPasswordChangePhone.of(context),
                        style: const TextStyle(fontSize: 12),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              _OtpInput(
                controllers: _codeCtrls,
                focusNodes: _codeFocus,
                onCompleted: _isVerifying ? null : (_) => _verifyCode(),
              ),
              const SizedBox(height: 22),
              SizedBox(
                height: AppTheme.buttonHeight,
                child: ElevatedButton.icon(
                  onPressed: _isVerifying ? null : _verifyCode,
                  icon: _isVerifying
                      ? const SizedBox.shrink()
                      : const Icon(Icons.check_circle_rounded, size: 18),
                  label: _isVerifying
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(S.forgotPasswordVerifyButton.of(context)),
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: _resendSeconds > 0
                    ? Text(
                        '${S.forgotPasswordResendInPrefix.of(context)} $_resendSeconds${S.forgotPasswordResendSecondsSuffix.of(context)}',
                        style: const TextStyle(
                          fontFamily: 'NotoKufi',
                          fontSize: 12,
                          color: AppTheme.textMuted,
                        ),
                      )
                    : TextButton.icon(
                        onPressed: _resendCode,
                        icon: const Icon(Icons.refresh_rounded, size: 16),
                        label: Text(S.forgotPasswordResendCode.of(context)),
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordStep(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHero(
          context,
          icon: Icons.lock_open_rounded,
          step: 3,
          title: S.forgotPasswordResetTitle.of(context),
          subtitle: S.forgotPasswordResetSubtitle.of(context),
        ),
        const SizedBox(height: 18),
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _fieldLabel(S.forgotPasswordNewPasswordLabel.of(context)),
              const SizedBox(height: 6),
              _passwordField(
                controller: _newPwdCtrl,
                visible: _showNewPwd,
                onToggle: () => setState(() => _showNewPwd = !_showNewPwd),
              ),
              const SizedBox(height: 16),
              _fieldLabel(S.forgotPasswordConfirmPasswordLabel.of(context)),
              const SizedBox(height: 6),
              _passwordField(
                controller: _confirmPwdCtrl,
                visible: _showConfirmPwd,
                onToggle: () =>
                    setState(() => _showConfirmPwd = !_showConfirmPwd),
                onSubmitted: _isResetting ? null : (_) => _resetPassword(),
              ),
              const SizedBox(height: 22),
              SizedBox(
                height: AppTheme.buttonHeight,
                child: ElevatedButton.icon(
                  onPressed: _isResetting ? null : _resetPassword,
                  icon: _isResetting
                      ? const SizedBox.shrink()
                      : const Icon(Icons.lock_reset_rounded, size: 18),
                  label: _isResetting
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(S.forgotPasswordResetButton.of(context)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Building blocks ─────────────────────────────────────

  Widget _buildHero(
    BuildContext context, {
    required IconData icon,
    required int step,
    required String title,
    required String subtitle,
  }) {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (i) {
              final n = i + 1;
              final done = n < step;
              final active = n == step;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Container(
                  width: active ? 26 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: done || active
                        ? Colors.white
                        : Colors.white.withOpacity(0.30),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.22),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white54, width: 1.5),
            ),
            child: Icon(icon, color: Colors.white, size: 30),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: AppTheme.headingLarge.copyWith(fontSize: 18),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: AppTheme.captionWhite.copyWith(fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: AppTheme.softShadow,
      ),
      child: child,
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

  Widget _passwordField({
    required TextEditingController controller,
    required bool visible,
    required VoidCallback onToggle,
    void Function(String)? onSubmitted,
  }) {
    return TextField(
      controller: controller,
      obscureText: !visible,
      style: const TextStyle(fontFamily: 'NotoKufi', fontSize: 14),
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        hintText: '••••••',
        prefixIcon: const Icon(Icons.lock_rounded, color: AppTheme.primary),
        suffixIcon: IconButton(
          icon: Icon(
            visible ? Icons.visibility_rounded : Icons.visibility_off_rounded,
            color: AppTheme.textMuted,
            size: 20,
          ),
          onPressed: onToggle,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// 4-digit OTP input — 4 boxes, auto-advance / auto-rewind.
// ─────────────────────────────────────────────────────────────

class _OtpInput extends StatelessWidget {
  final List<TextEditingController> controllers;
  final List<FocusNode> focusNodes;
  final ValueChanged<String>? onCompleted;

  const _OtpInput({
    required this.controllers,
    required this.focusNodes,
    this.onCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(4, (i) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: SizedBox(
              width: 56,
              child: TextField(
                controller: controllers[i],
                focusNode: focusNodes[i],
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                maxLength: 1,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(
                  fontFamily: 'NotoKufi',
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                ),
                decoration: InputDecoration(
                  counterText: '',
                  filled: true,
                  fillColor: AppTheme.background,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    borderSide:
                        const BorderSide(color: AppTheme.divider, width: 1),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    borderSide:
                        const BorderSide(color: AppTheme.divider, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    borderSide:
                        const BorderSide(color: AppTheme.primary, width: 1.6),
                  ),
                ),
                onChanged: (v) {
                  if (v.isNotEmpty && i < 3) {
                    focusNodes[i + 1].requestFocus();
                  } else if (v.isEmpty && i > 0) {
                    focusNodes[i - 1].requestFocus();
                  }
                  if (i == 3 &&
                      v.isNotEmpty &&
                      controllers.every((c) => c.text.isNotEmpty)) {
                    onCompleted?.call(controllers.map((c) => c.text).join());
                  }
                },
              ),
            ),
          );
        }),
      ),
    );
  }
}
