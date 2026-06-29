// lib/screens/FeedbackPage.dart

import 'package:flutter/material.dart';

import '../core/app_constants.dart';
import '../core/app_logger.dart';
import '../core/app_strings.dart';
import '../core/app_theme.dart';
import '../services/api_service.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/feedback_card.dart';

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({Key? key}) : super(key: key);

  @override
  _FeedbackPageState createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  List<Map<String, dynamic>> _feedbackEntries = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _didFetchFeedback = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didFetchFeedback) {
      _didFetchFeedback = true;
      _fetchFeedbackEntries();
    }
  }

  Future<void> _fetchFeedbackEntries() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    AppLogger.info('Fetching feedback entries', tag: 'FEEDBACK_PAGE');

    final response =
        await ApiService.instance.get(AppConstants.getFeedbackEndpoint);
    if (!mounted) return;

    if (response.success && response.data != null) {
      final data = response.data!;
      if (data['status'] == 'success') {
        final list = List<Map<String, dynamic>>.from(data['data'] as List);
        AppLogger.info('Feedback loaded: ${list.length} items',
            tag: 'FEEDBACK_PAGE');
        setState(() {
          _feedbackEntries = list;
          _isLoading = false;
        });
      } else {
        AppLogger.warning('Feedback API error: ${data['message']}',
            tag: 'FEEDBACK_PAGE');
        setState(() {
          _errorMessage =
              data['message'] ?? S.feedbackPageLoadError.of(context);
          _isLoading = false;
        });
      }
    } else {
      AppLogger.error('Feedback fetch failed: ${response.error}',
          tag: 'FEEDBACK_PAGE');
      setState(() {
        _errorMessage = S.feedbackPageFetchError.of(context);
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteFeedback(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
        title: Text(S.feedbackPageDeleteTitle.of(ctx),
            style: const TextStyle(fontFamily: 'NotoKufi')),
        content: Text(S.feedbackPageDeleteContent.of(ctx),
            style: const TextStyle(fontFamily: 'NotoKufi')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(S.no.of(ctx),
                style: const TextStyle(
                    fontFamily: 'NotoKufi', color: AppTheme.primary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(S.yes.of(ctx),
                style: const TextStyle(
                    fontFamily: 'NotoKufi', color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    AppLogger.info('Deleting feedback id: $id', tag: 'FEEDBACK_PAGE');

    final response = await ApiService.instance.post(
      AppConstants.deleteFeedbackEndpoint,
      jsonBody: {'id': id},
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (response.success) {
      AppLogger.info('Feedback deleted: $id', tag: 'FEEDBACK_PAGE');
      setState(
          () => _feedbackEntries.removeWhere((e) => e['id'].toString() == id));
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(S.feedbackPageDeletedSnack.of(context),
            style: const TextStyle(fontFamily: 'NotoKufi')),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ));
    } else {
      AppLogger.error('Delete feedback failed: ${response.error}',
          tag: 'FEEDBACK_PAGE');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(S.feedbackPageDeleteFailedSnack.of(context),
            style: const TextStyle(fontFamily: 'NotoKufi')),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  void _showDetails(Map<String, dynamic> feedback) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
        title: Text(
            feedback['name'] ?? S.feedbackPageUserName.of(ctx),
            style: const TextStyle(
                fontFamily: 'NotoKufi', fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow(
                Icons.phone_rounded,
                S.phoneNumberLabelColon.of(ctx),
                feedback['phone_number'] ?? '—'),
            const SizedBox(height: 12),
            Text(S.feedbackPageMessageLabel.of(ctx),
                style: const TextStyle(
                    fontFamily: 'NotoKufi',
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                    fontSize: 13)),
            const SizedBox(height: 6),
            Text(
                feedback['message'] ?? S.feedbackPageMessageNone.of(ctx),
                style: const TextStyle(
                    fontFamily: 'NotoKufi', fontSize: 14, height: 1.5)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(S.feedbackPageClose.of(ctx),
                style: const TextStyle(
                    fontFamily: 'NotoKufi', color: AppTheme.primary)),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(children: [
      Icon(icon, size: 16, color: AppTheme.primary),
      const SizedBox(width: 6),
      Text('$label ',
          style: const TextStyle(
              fontFamily: 'NotoKufi',
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.black54)),
      Text(value, style: const TextStyle(fontFamily: 'NotoKufi', fontSize: 13)),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: S.feedbackPageTitle.of(context),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.accent))
          : _errorMessage != null
              ? _buildError(context)
              : _feedbackEntries.isEmpty
                  ? Center(
                      child: Text(
                          S.feedbackPageEmpty.of(context),
                          style: const TextStyle(
                              fontFamily: 'NotoKufi',
                              fontSize: 16,
                              color: Colors.grey)))
                  : RefreshIndicator(
                      onRefresh: _fetchFeedbackEntries,
                      color: AppTheme.accent,
                      child: ListView.builder(
                        itemCount: _feedbackEntries.length,
                        itemBuilder: (_, i) => FeedbackCard(
                          feedback: _feedbackEntries[i],
                          onDelete: () => _deleteFeedback(
                              _feedbackEntries[i]['id'].toString()),
                          onTap: () => _showDetails(_feedbackEntries[i]),
                        ),
                      ),
                    ),
    );
  }

  Widget _buildError(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 64, color: AppTheme.error),
            const SizedBox(height: 12),
            Text(_errorMessage!,
                style: AppTheme.bodyMedium.copyWith(color: AppTheme.error),
                textAlign: TextAlign.center),
            const SizedBox(height: 20),
            SizedBox(
              width: 200,
              child: ElevatedButton.icon(
                onPressed: _fetchFeedbackEntries,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(S.retry.of(context)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
