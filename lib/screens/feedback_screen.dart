// lib/screens/feedback_screen.dart

import 'package:flutter/material.dart';

import '../core/app_logger.dart';
import '../core/app_strings.dart';
import '../core/app_theme.dart';
import '../services/feedback_service.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/footer_menu.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({Key? key}) : super(key: key);

  @override
  _FeedbackScreenState createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _formKey = GlobalKey<FormState>();
  final _messageCtrl = TextEditingController();

  String _name = '';
  String _phoneNumber = '';
  String _message = '';

  bool _isSubmitting = false;
  bool _showSuccessMessage = false;

  static const int _maxMessageLength = 500;

  @override
  void initState() {
    super.initState();
    _messageCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() {
      _isSubmitting = true;
      _showSuccessMessage = false;
    });

    AppLogger.info('Submitting feedback from: $_name', tag: 'FEEDBACK');

    final response = await FeedbackService.instance
        .submitFeedback(_name, _phoneNumber, _message);

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (response['status'] == 'success') {
      AppLogger.info('Feedback submitted successfully', tag: 'FEEDBACK');
      setState(() => _showSuccessMessage = true);
      _formKey.currentState!.reset();
      _messageCtrl.clear();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(S.feedbackSubmitSnack.of(context)),
        backgroundColor: AppTheme.success,
      ));
    } else {
      final errMsg = response['message'] is List
          ? (response['message'] as List).join(' ')
          : response['message']?.toString() ?? 'Error';
      AppLogger.error('Feedback failed: $errMsg', tag: 'FEEDBACK');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(errMsg),
        backgroundColor: AppTheme.error,
      ));
    }
  }

  void _navigateToDashboard() {
    Navigator.pushReplacementNamed(context, '/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: S.feedbackTitle.of(context),
      bottomNavigationBar: const FooterMenu(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeroCard(context),
            const SizedBox(height: 22),
            if (_showSuccessMessage) ...[
              _buildSuccessCard(context),
              const SizedBox(height: 18),
            ],
            _buildForm(context),
          ],
        ),
      ),
    );
  }

  // ── Hero card ──────────────────────────────────────────────

  Widget _buildHeroCard(BuildContext context) {
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
            child: const Icon(Icons.forum_rounded,
                size: 32, color: Colors.white),
          ),
          const SizedBox(height: 14),
          Text(
            S.feedbackHeroTitle.of(context),
            style: AppTheme.headingLarge.copyWith(fontSize: 18),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            S.feedbackHeroSubtitle.of(context),
            style: AppTheme.captionWhite.copyWith(fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ── Success card ───────────────────────────────────────────

  Widget _buildSuccessCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.success.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.success.withOpacity(0.30), width: 1),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.success.withOpacity(0.18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded,
                    color: AppTheme.success, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      S.feedbackSuccessTitle.of(context),
                      style: AppTheme.headingSmall.copyWith(
                        color: AppTheme.success,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      S.feedbackSuccessBody.of(context),
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _navigateToDashboard,
              icon: const Icon(Icons.home_rounded, size: 18),
              label: Text(S.feedbackBackHome.of(context)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.success,
                side: const BorderSide(color: AppTheme.success, width: 1.4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Form ───────────────────────────────────────────────────

  Widget _buildForm(BuildContext context) {
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
            _fieldLabel(S.feedbackNameLabel.of(context)),
            const SizedBox(height: 6),
            TextFormField(
              decoration: InputDecoration(
                hintText: S.feedbackNameHint.of(context),
                prefixIcon:
                    const Icon(Icons.person_rounded, color: AppTheme.primary),
              ),
              style: const TextStyle(fontFamily: 'NotoKufi', fontSize: 14),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? S.feedbackNameRequired.of(context)
                  : null,
              onSaved: (v) => _name = v!.trim(),
            ),
            const SizedBox(height: 18),
            _fieldLabel(S.feedbackPhoneLabel.of(context)),
            const SizedBox(height: 6),
            TextFormField(
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                hintText: '07XX XXX XXXX',
                prefixIcon:
                    Icon(Icons.phone_rounded, color: AppTheme.primary),
              ),
              style: const TextStyle(fontFamily: 'NotoKufi', fontSize: 14),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return S.feedbackPhoneRequired.of(context);
                }
                if (!RegExp(r'^\+?[0-9]{7,15}$').hasMatch(v.trim())) {
                  return S.feedbackPhoneInvalid.of(context);
                }
                return null;
              },
              onSaved: (v) => _phoneNumber = v!.trim(),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _fieldLabel(S.feedbackMessageLabel.of(context)),
                Text(
                  '${_messageCtrl.text.length}/$_maxMessageLength',
                  style: AppTheme.bodySmall.copyWith(
                    fontSize: 11,
                    color: _messageCtrl.text.length > _maxMessageLength
                        ? AppTheme.error
                        : AppTheme.textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _messageCtrl,
              maxLines: 6,
              maxLength: _maxMessageLength,
              decoration: InputDecoration(
                hintText: S.feedbackMessageHint.of(context),
                alignLabelWithHint: true,
                counterText: '',
              ),
              style: const TextStyle(
                fontFamily: 'NotoKufi',
                fontSize: 14,
                height: 1.5,
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? S.feedbackMessageRequired.of(context)
                  : null,
              onSaved: (v) => _message = v!.trim(),
            ),
            const SizedBox(height: 22),
            SizedBox(
              height: AppTheme.buttonHeight,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submitFeedback,
                icon: _isSubmitting
                    ? const SizedBox.shrink()
                    : const Icon(Icons.send_rounded, size: 18),
                label: _isSubmitting
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(S.feedbackSubmit.of(context)),
              ),
            ),
          ],
        ),
      ),
    );
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
