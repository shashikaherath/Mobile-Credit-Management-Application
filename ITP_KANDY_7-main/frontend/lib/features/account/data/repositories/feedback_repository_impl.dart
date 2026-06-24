// ------------------------------------------------------------------------------
// File: feedback_repository_impl.dart
// Purpose: Multi-Channel Communication Implementation.
// Rationale: Concrete adapter for the Feedback administrative pipeline. 
//   Distinguishes between secure internal feedback and high-priority 
//   public account recovery requests for optimized triage.
// ------------------------------------------------------------------------------
import 'package:frontend/core/network/api_client.dart'; // Infrastructure: Base HTTP engine
import 'package:frontend/features/account/domain/entities/feedback.dart'; // Domain: Entity
import 'package:frontend/features/account/domain/repositories/feedback_repository.dart'; // Domain: Contract

class FeedbackRepositoryImpl implements FeedbackRepository {
  /**
   * Logic: Internal Support Pipeline.
   * Rationale: Transmits feedback from an authenticated session, automatically inheriting owner identity headers.
   */
  @override
  Future<void> submitFeedback(UserFeedback feedback) async {
    await ApiClient.post('/feedback', feedback.toJson());
  }

  /**
   * Logic: Public Recovery Pipeline.
   * Rationale: Allows unauthenticated users to submit verified recovery requests (OTP-backed) to the help desk.
   */
  @override
  Future<void> submitPublicFeedback(UserFeedback feedback) async {
    await ApiClient.post('/public/feedback', feedback.toJson());
  }

  /**
   * Logic: Administrative Triage.
   * Rationale: Retrieves all outstanding tickets for system administrators to review and action.
   */
  @override
  Future<List<UserFeedback>> getAllFeedback() async {
    final response = await ApiClient.get('/admin/feedback');
    final List data = response['data'];
    // Parsing: Mapping raw JSON list into a collection of typed Domain Entities.
    return data.map((json) => UserFeedback.fromJson(json)).toList();
  }

  /**
   * Logic: Resolution Cleanup.
   * Rationale: Allows administrators to purge resolved or spam reports from the triage database.
   */
  @override
  Future<void> deleteFeedback(String id) async {
    await ApiClient.delete('/admin/feedback/$id');
  }
}

