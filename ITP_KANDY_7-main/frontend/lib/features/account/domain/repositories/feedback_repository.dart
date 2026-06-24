// ------------------------------------------------------------------------------
// File: feedback_repository.dart
// Purpose: Dual-Pipeline Communication Contract.
// Rationale: Defines the blueprint for the administrative support system. 
//   Ensures that both authenticated internal reports and unauthenticated 
//   public recovery tickets flow through a standardized interface.
// ------------------------------------------------------------------------------
import 'package:frontend/features/account/domain/entities/feedback.dart'; // Domain: Entity

abstract class FeedbackRepository {
  /// Internal Pipeline: Submits feedback from an authenticated owner session.
  Future<void> submitFeedback(UserFeedback feedback);

  /// Public Pipeline: Submits recovery/support requests from unauthenticated users.
  Future<void> submitPublicFeedback(UserFeedback feedback);

  /// Administrative Triage: Retrieves all pending tickets for admin review.
  Future<List<UserFeedback>> getAllFeedback();

  /// Resolution Cleanup: Removes a resolved or spam ticket from the database.
  Future<void> deleteFeedback(String id);
}

