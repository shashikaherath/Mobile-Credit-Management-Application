// ------------------------------------------------------------------------------
// File: admin_provider.dart
// Purpose: Centralized state management for global administrative operations.
// Rationale: Orchestrates high-level system control including store owner 
//   lifecycle (fetch, suspend, delete) and real-time MongoDB health monitoring.
//   Directly utilizes ApiClient to bypass feature-specific repositories for 
//   platform-wide administrative agility.
// ------------------------------------------------------------------------------
import 'package:flutter/material.dart'; // UI: Flutter Material & ChangeNotifier
import 'package:frontend/core/error/exceptions.dart'; // Core: Structured error handling
import 'package:frontend/core/network/api_client.dart'; // Network: Global API operations
import 'package:frontend/features/auth/domain/entities/owner.dart'; // Domain: Owner entity model

class AdminProvider extends ChangeNotifier {
  List<Owner> _owners = [];
  bool _isLoading = false;
  bool _isActionInProgress = false;
  String? _error;
  String? _technicalDetails;
  Map<String, dynamic>? _systemHealth;

  List<Owner> get owners => _owners;
  bool get isLoading => _isLoading;
  bool get isActionInProgress => _isActionInProgress;
  String? get error => _error;
  String? get technicalDetails => _technicalDetails;
  Map<String, dynamic>? get systemHealth => _systemHealth;

  // Fetch real-time system health and MongoDB metrics.
  Future<void> fetchSystemHealth() async {
    try {
      final response = await ApiClient.get('/admin/system-health');
      if (response['success'] == true) {
        _systemHealth = response['data']['mongodb'];
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching system health: $e');
    }
  }

  // Fetch all store owners for the Admin Dashboard
  Future<void> fetchOwners() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiClient.get('/admin/owners');
      if (response['success'] == true) {
        final List<dynamic> data = response['data'] ?? [];
        _owners = data.map((json) => Owner.fromJson(json)).toList();
      } else {
        _error = response['error'] ?? 'Failed to fetch owners';
      }
    } catch (e) {
      if (e is AppException) {
        _error = e.message;
        _technicalDetails = e.details;
      } else {
        _error = e.toString();
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Helper for dashboard stats
  int get totalOwners => _owners.length;
  int get activeOwners =>
      _owners
          .where(
            (owner) => owner.isSuspended == false && owner.status != 'suspended',
          )
          .length;
  int get suspendedOwners =>
      _owners
          .where(
            (owner) => owner.isSuspended || owner.status == 'suspended',
          )
          .length;

  Future<bool> _runOwnerAction(
    String ownerId,
    Future<Map<String, dynamic>> Function() request,
    String fallbackError,
  ) async {
    try {
      _isActionInProgress = true;
      _error = null;
      _technicalDetails = null;
      notifyListeners();

      final response = await request();
      if (response['success'] == true) {
        _applyOwnerActionResult(ownerId, response);
        _error = null;
        notifyListeners();
        return true;
      }
      _error = response['error'] ?? fallbackError;
      notifyListeners();
      return false;
    } catch (e) {
      if (e is AppException) {
        _error = e.message;
        _technicalDetails = e.details;
      } else {
        _error = e.toString();
      }
      notifyListeners();
      return false;
    } finally {
      _isActionInProgress = false;
      notifyListeners();
    }
  }

  void _applyOwnerActionResult(String ownerId, Map<String, dynamic> response) {
    if (response['message'] == 'Owner deleted successfully') {
       _owners.removeWhere((owner) => owner.id == ownerId);
       return;
    }

    final dynamic data = response['data'];
    if (data is Map<String, dynamic>) {
      final updatedOwner = Owner.fromJson(data);
      final index = _owners.indexWhere((owner) => owner.id == ownerId);
      if (index >= 0) {
        _owners[index] = updatedOwner;
      } else {
        _owners.add(updatedOwner);
      }
      return;
    }
  }

  // Update owner details
  Future<bool> updateOwner(String id, Map<String, dynamic> data) async {
    return _runOwnerAction(
      id,
      () => ApiClient.put('/admin/owners/$id', data),
      'Failed to update owner',
    );
  }

  // Suspend or Unsuspend an owner
  Future<bool> suspendOwner(String id) async {
    return _runOwnerAction(
      id,
      () => ApiClient.patch('/admin/owners/$id/suspend'),
      'Failed to update suspension status',
    );
  }

  // Delete an owner account
  Future<bool> deleteOwner(String id) async {
    return _runOwnerAction(
      id,
      () => ApiClient.delete('/admin/owners/$id'),
      'Failed to delete owner',
    );
  }

  // Clear any existing errors
  void clearError() {
    _error = null;
    notifyListeners();
  }
}

