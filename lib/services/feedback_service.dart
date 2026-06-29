// lib/services/feedback_service.dart
// ─────────────────────────────────────────────────────────────
// Now uses ApiService instead of raw http calls.
// ─────────────────────────────────────────────────────────────

import 'api_service.dart';

class FeedbackService {
  FeedbackService._();
  static final FeedbackService instance = FeedbackService._();

  Future<Map<String, dynamic>> submitFeedback(
    String name,
    String phoneNumber,
    String message,
  ) async {
    final response = await ApiService.instance.submitFeedback(
      name,
      phoneNumber,
      message,
    );

    if (response.success && response.data != null) {
      return response.data!;
    }
    return {
      'status': 'error',
      'message': response.error ?? 'Unknown error',
    };
  }
}
