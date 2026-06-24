// ------------------------------------------------------------------------------
// File: feedback_provider.dart
// Purpose: Help Desk and User Feedback State Orchestrator.
// Rationale: Manages the lifecycle of support tickets, from UI capture 
//   to persistent administrative storage. Centralizes both authenticated 
//   internal reports and high-priority public recovery streams.
// ------------------------------------------------------------------------------
import 'package:flutter/material.dart'; // Core: Flutter reactive system.
import 'package:frontend/core/error/exceptions.dart'; // Error: Custom app exception hierarchy.
import 'package:frontend/features/account/domain/entities/feedback.dart'; // Domain: UserFeedback data structure.
import 'package:frontend/features/account/domain/repositories/feedback_repository.dart'; // Domain: Abstract data contract.
import 'package:frontend/features/account/data/repositories/feedback_repository_impl.dart'; // Data: Concrete implementation.
import 'package:frontend/core/network/api_client.dart'; // Infrastructure: Global networking instance.

class FeedbackProvider extends ChangeNotifier {
  final FeedbackRepository _repository;
  
  /**
   * Constructor with Dependency Injection support.
   * Defaults to FeedbackRepositoryImpl for production runtime.
   */
  FeedbackProvider({FeedbackRepository? repository}) 
      : _repository = repository ?? FeedbackRepositoryImpl();
  
  // --- Persistent State Variables ---
  List<UserFeedback> _feedbacks = []; // Cache: List of tickets (Admin view).
  bool _isLoading = false; // State: Global busy indicator.
  String? _error; // State: Human-readable error message.
  String? _technicalDetails; // State: Raw diagnostic data for troubleshooting.

  // --- Public Viewports ---
  List<UserFeedback> get feedbacks => _feedbacks;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get technicalDetails => _technicalDetails;

  /**
   * Logic: Authenticated Feedback Submission.
   * Rationale: Used by logged-in owners to send suggestions or report bugs.
   * Automatically attaches the Owner ID and Name from the active session.
   */
  Future<bool> submitFeedback(String category, String message, {String? ownerName}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Step: Materialize the domain entity with session-specific identity.
      final feedback = UserFeedback(
        id: '', // Server-generated.
        ownerId: '', // Resolved by backend via auth token.
        ownerName: ownerName ?? ApiClient.ownerName ?? '', // Fallback to cached identity.
        category: category,
        message: message,
        createdAt: DateTime.now(),
      );
      
      // Step: Persist via the repository layer.
      await _repository.submitFeedback(feedback);
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      // Strategy: Propagate technical details if available for UI diagnostics.
      if (e is AppException) {
        _error = e.message;
        _technicalDetails = e.details;
      } else {
        _error = e.toString();
      }
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /**
   * Logic: Unauthenticated (Public) Feedback Submission.
   * Rationale: Used by users locked out of their accounts.
   * Includes manual contact proof and identity verification flags.
   */
  Future<bool> submitPublicFeedback({
    required String category,
    required String message,
    required String contactInfo,
    required String claimedShopName,
    required bool isVerified,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Step: Materialize the domain entity with explicit recovery metadata.
      final feedback = UserFeedback(
        id: '',
        ownerId: '',
        ownerName: 'External User', // Distinguishes from internal owners.
        category: category,
        message: message,
        createdAt: DateTime.now(),
        contactInfo: contactInfo,
        claimedShopName: claimedShopName,
        isVerified: isVerified, // Strategy: Prioritize verified recovery requests.
      );
      
      // Step: Persist via specialized public endpoint.
      await _repository.submitPublicFeedback(feedback);
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      if (e is AppException) {
        _error = e.message;
        _technicalDetails = e.details;
      } else {
        _error = e.toString();
      }
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /**
   * Logic: Administrative Ticket Retrieval.
   * Rationale: Fetches all submitted issues for the Admin Panel view.
   */
  Future<void> fetchAllFeedback() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _feedbacks = await _repository.getAllFeedback();
    } catch (e) {
      _error = e.toString(); // Fallback for general errors.
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /**
   * Logic: Ticket Purge.
   * Rationale: Allows admins to clear resolved issues from the system.
   */
  Future<void> deleteFeedback(String id) async {
    try {
      await _repository.deleteFeedback(id);
      _feedbacks.removeWhere((f) => f.id == id); // Action: Sync local cache.
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /**
   * State Management: Diagnostic Reset.
   */
  void clearError() {
    _error = null;
    notifyListeners();
  }
}

